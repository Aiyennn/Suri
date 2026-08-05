"""
exceptions.py
=============
Domain-level exceptions for the Suri backend.

These are *not* HTTP exceptions — they carry domain semantics only.
FastAPI exception handlers in ``main.py`` translate each one into the
appropriate HTTP response so that neither the service layer nor the
repository layer needs to import FastAPI.
"""


class InternalServerError(Exception):
    """
    Raised when an unexpected error occurs that is not attributable to
    invalid client input.  Maps to HTTP 500.
    """

    def __init__(self, message: str = "An unexpected error occurred.") -> None:
        super().__init__(message)


class InvalidImageError(Exception):
    """
    Raised when an uploaded file cannot be decoded as a valid image, or
    when the decoded image fails content-level validation (e.g. wrong
    dimensions).  Maps to HTTP 422.

    Args:
        message: Human-readable description of the specific failure.
    """

    def __init__(self, message: str = "The uploaded file is not a valid image.") -> None:
        self.message = message
        super().__init__(message)


class ImageQualityError(Exception):
    """
    Raised when a decoded image passes format validation but fails one or
    more pixel-level quality thresholds (blur, brightness, contrast).
    Maps to HTTP 422.

    Args:
        reason: Plain-language description of the quality failure.
    """

    def __init__(self, reason: str) -> None:
        self.reason = reason
        super().__init__(reason)


class InvalidPatientDataError(Exception):
    """
    Raised when patient-supplied fields fail domain validation after the
    request schema has already been accepted by FastAPI.  Maps to HTTP 422.

    Args:
        detail: List of structured Pydantic error dicts, forwarded from a
                ``ValidationError.errors()`` call so the HTTP handler can
                surface them to the client.
    """

    def __init__(self, detail: list | None = None) -> None:
        self.detail = detail or []
        super().__init__(f"Invalid patient data: {self.detail}")