"""
schemas/auth.py
===============
Pydantic data-transfer objects (DTOs) for the Suri authentication API.

These schemas define:
  - The shape of validated request bodies for /auth/register and /auth/login
  - The structure of every response body returned by the /auth/* endpoints
"""

from __future__ import annotations

from datetime import date
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


# ---------------------------------------------------------------------------
# Request schemas
# ---------------------------------------------------------------------------

class UserRegisterRequest(BaseModel):
    """Payload for POST /auth/register."""

    email: EmailStr = Field(
        ...,
        description="Unique email address used to log in.",
        examples=["jane@example.com"],
    )
    password: str = Field(
        ...,
        min_length=8,
        description="Password (min 8 characters). Will be bcrypt-hashed before storage.",
        examples=["s3cur3P@ss!"],
    )
    full_name: str = Field(
        ...,
        min_length=1,
        max_length=255,
        description="User's display name.",
        examples=["Jane Doe"],
    )
    date_of_birth: Optional[date] = Field(
        None,
        description="Optional date of birth (ISO 8601 date string).",
        examples=["1990-06-15"],
    )
    sex: Optional[str] = Field(
        None,
        description="Biological sex: 'male', 'female', or 'other'.",
        examples=["female"],
    )
    medical_history: Optional[str] = Field(
        None,
        description="Freeform medical background (conditions, allergies, medications).",
        examples=["Type 2 diabetes, penicillin allergy"],
    )


class UserLoginRequest(BaseModel):
    """Payload for POST /auth/login."""

    email: EmailStr = Field(
        ...,
        description="Registered email address.",
        examples=["jane@example.com"],
    )
    password: str = Field(
        ...,
        description="Account password.",
        examples=["s3cur3P@ss!"],
    )


# ---------------------------------------------------------------------------
# Response schemas
# ---------------------------------------------------------------------------

class TokenResponse(BaseModel):
    """JWT bearer token returned on successful login or register."""

    access_token: str = Field(
        ...,
        description="Signed JWT access token. Send as 'Authorization: Bearer <token>'.",
    )
    token_type: str = Field(
        default="bearer",
        description="Token type — always 'bearer'.",
    )


class UserResponse(BaseModel):
    """Public user profile. Never includes hashed_password."""

    id: UUID = Field(..., description="User UUID.")
    email: str = Field(..., description="User email address.")
    full_name: str = Field(..., description="User display name.")
    date_of_birth: Optional[date] = Field(None, description="Date of birth.")
    sex: Optional[str] = Field(None, description="Biological sex.")
    medical_history: Optional[str] = Field(None, description="Medical background.")
    is_active: bool = Field(..., description="Whether the account is active.")

    model_config = {"from_attributes": True}


class AuthResponse(BaseModel):
    """Combined response containing both the token and user profile."""

    token: TokenResponse
    user: UserResponse
