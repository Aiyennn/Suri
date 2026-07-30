"""
services/auth_service.py
========================
Business logic for user registration, login, JWT creation, and the
``get_current_user`` FastAPI dependency.

Design decisions
----------------
* Passwords are hashed with **bcrypt** directly (not via passlib) because
  passlib 1.7.4 is incompatible with bcrypt >= 4.0 and is no longer
  maintained.  The ``bcrypt`` library is used directly — it is already a
  transitive dependency installed alongside passlib.
* JWTs are signed with **HS256** using the ``SECRET_KEY`` from settings.
  The subject claim (``sub``) stores the user's UUID as a string.
* ``get_current_user`` is a FastAPI dependency that validates the Bearer
  token on every protected route.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Optional
from uuid import UUID

import bcrypt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.core.config import settings
from app.dependencies import get_db
from app.models.user import User
from app.schemas.auth import UserRegisterRequest

# ---------------------------------------------------------------------------
# Password hashing — using bcrypt directly
# ---------------------------------------------------------------------------

def hash_password(plain: str) -> str:
    """Return the bcrypt hash of *plain* as a UTF-8 string."""
    hashed = bcrypt.hashpw(plain.encode("utf-8"), bcrypt.gensalt(rounds=12))
    return hashed.decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    """Return ``True`` if *plain* matches *hashed*."""
    try:
        return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))
    except Exception:
        return False


# Pre-computed hash used only for timing-safe dummy comparisons when the
# requested email does not exist in the database.
_DUMMY_HASH: bytes = bcrypt.hashpw(b"__timing_dummy__", bcrypt.gensalt(rounds=12))

# ---------------------------------------------------------------------------
# JWT helpers
# ---------------------------------------------------------------------------

def create_access_token(
    subject: str,
    expires_delta: Optional[timedelta] = None,
) -> str:
    """
    Create and sign a JWT access token.

    Args:
        subject: The value to store in the ``sub`` claim (usually a user UUID).
        expires_delta: Custom expiry window.  Defaults to
            ``settings.ACCESS_TOKEN_EXPIRE_MINUTES`` minutes.

    Returns:
        A signed JWT string.
    """
    expire = datetime.now(timezone.utc) + (
        expires_delta
        if expires_delta is not None
        else timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    payload = {"sub": subject, "exp": expire}
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


# ---------------------------------------------------------------------------
# Registration
# ---------------------------------------------------------------------------

def register_user(db: Session, req: UserRegisterRequest) -> User:
    """
    Create a new user account.

    Raises:
        HTTPException(400): If a user with the same email already exists.
    """
    existing = db.query(User).filter(User.email == req.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with this email address already exists.",
        )

    user = User(
        email=req.email,
        hashed_password=hash_password(req.password),
        full_name=req.full_name,
        date_of_birth=req.date_of_birth,
        sex=req.sex,
        medical_history=req.medical_history,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------

def authenticate_user(db: Session, email: str, password: str) -> User:
    """
    Verify credentials and return the matching ``User`` row.

    Raises:
        HTTPException(401): If the email is not found or the password is wrong.
    """
    user: Optional[User] = db.query(User).filter(User.email == email).first()

    # Constant-time dummy check — prevents email enumeration via response-time
    # differences. _DUMMY_HASH is a real bcrypt hash computed at startup.
    if user is None:
        bcrypt.checkpw(b"__timing_dummy__", _DUMMY_HASH)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not verify_password(password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account has been deactivated.",
        )

    return user


# ---------------------------------------------------------------------------
# get_current_user dependency
# ---------------------------------------------------------------------------

_bearer_scheme = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    """
    FastAPI dependency that validates the JWT Bearer token and returns the
    authenticated ``User`` ORM object.

    Inject this into any route that requires authentication::

        @router.get("/protected")
        def protected_route(current_user: User = Depends(get_current_user)):
            ...

    Raises:
        HTTPException(401): On missing, expired, or malformed tokens.
        HTTPException(403): If the token's subject resolves to an inactive user.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(
            credentials.credentials,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM],
        )
        user_id: Optional[str] = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user: Optional[User] = db.query(User).filter(
        User.id == UUID(user_id)
    ).first()

    if user is None:
        raise credentials_exception

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account has been deactivated.",
        )

    return user
