"""
api/auth.py
===========
FastAPI router for authentication endpoints.

All routes in this module are mounted under the ``/auth`` prefix by
``main.py``, so the full paths are:

    POST /auth/register  – Create a new account.
    POST /auth/login     – Verify credentials and receive a JWT.
    GET  /auth/me        – Return the authenticated user's profile (protected).
"""

import logging

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.dependencies import get_db
from app.models.user import User
from app.schemas.auth import (
    AuthResponse,
    TokenResponse,
    UserLoginRequest,
    UserRegisterRequest,
    UserResponse,
)
from app.services.auth_service import (
    authenticate_user,
    create_access_token,
    get_current_user,
    register_user,
)

logger = logging.getLogger(__name__)

router = APIRouter()


# ---------------------------------------------------------------------------
# POST /auth/register
# ---------------------------------------------------------------------------

@router.post(
    "/register",
    response_model=AuthResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user",
    description=(
        "Create a new Suri account. "
        "Returns the user profile and a JWT access token so the client "
        "can immediately authenticate without a separate login call."
    ),
)
def register(
    req: UserRegisterRequest,
    db: Session = Depends(get_db),
) -> AuthResponse:
    """
    Register a new user account.

    Processing:
        1. Validate the request body.
        2. Check that the email is not already taken.
        3. Hash the password with bcrypt.
        4. Persist the new ``User`` row.
        5. Issue a JWT and return both the token and the public user profile.

    Raises:
        HTTPException(400): Email already registered.
    """
    logger.info("Register attempt for email=%r", req.email)
    user = register_user(db, req)
    token = create_access_token(subject=str(user.id))
    logger.info("User registered successfully id=%s", user.id)

    return AuthResponse(
        token=TokenResponse(access_token=token),
        user=UserResponse.model_validate(user),
    )


# ---------------------------------------------------------------------------
# POST /auth/login
# ---------------------------------------------------------------------------

@router.post(
    "/login",
    response_model=AuthResponse,
    summary="Login with email and password",
    description=(
        "Authenticate with a registered email and password. "
        "Returns a JWT access token valid for "
        "``ACCESS_TOKEN_EXPIRE_MINUTES`` minutes."
    ),
)
def login(
    req: UserLoginRequest,
    db: Session = Depends(get_db),
) -> AuthResponse:
    """
    Authenticate a user and issue a JWT.

    Processing:
        1. Look up the user by email.
        2. Verify the submitted password against the stored bcrypt hash.
        3. Reject inactive accounts.
        4. Issue a JWT and return both the token and the public user profile.

    Raises:
        HTTPException(401): Invalid email or password.
        HTTPException(403): Account is deactivated.
    """
    logger.info("Login attempt for email=%r", req.email)
    user = authenticate_user(db, req.email, req.password)
    token = create_access_token(subject=str(user.id))
    logger.info("User logged in successfully id=%s", user.id)

    return AuthResponse(
        token=TokenResponse(access_token=token),
        user=UserResponse.model_validate(user),
    )


# ---------------------------------------------------------------------------
# GET /auth/me
# ---------------------------------------------------------------------------

@router.get(
    "/me",
    response_model=UserResponse,
    summary="Get the current authenticated user",
    description=(
        "Returns the profile of the currently authenticated user. "
        "Requires a valid JWT Bearer token in the Authorization header."
    ),
)
def me(current_user: User = Depends(get_current_user)) -> UserResponse:
    """
    Return the authenticated user's public profile.

    This is a lightweight endpoint that can be used by the mobile client
    to verify token validity and refresh the local user cache.

    Raises:
        HTTPException(401): Missing or invalid token.
    """
    return UserResponse.model_validate(current_user)
