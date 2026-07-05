"""
engine/validation.py
====================
Input schema validation helpers.

Wraps Pydantic's validation with structured error reporting so callers
receive clear, actionable error messages rather than raw Pydantic exceptions.
"""

from __future__ import annotations

from pydantic import ValidationError

from .models import WoundAssessmentInput


class InputValidationError(ValueError):
    """
    Raised when the raw model output does not conform to the expected schema.

    Attributes
    ----------
    errors:
        List of human-readable field-level error descriptions.
    """

    def __init__(self, errors: list[str]) -> None:
        self.errors = errors
        formatted = "\n".join(f"  • {e}" for e in errors)
        super().__init__(f"Input validation failed:\n{formatted}")


def validate_input(raw: dict) -> WoundAssessmentInput:
    """
    Parse and validate a raw dictionary against ``WoundAssessmentInput``.

    Parameters
    ----------
    raw:
        Unvalidated dictionary (typically the direct output of the AI model).

    Returns
    -------
    WoundAssessmentInput
        A fully validated, type-safe model instance.

    Raises
    ------
    InputValidationError
        If any field is missing, has an invalid type, or fails an enum
        constraint.  The exception carries a ``errors`` list with one entry
        per validation failure.
    """
    try:
        return WoundAssessmentInput.model_validate(raw)
    except ValidationError as exc:
        errors = [
            f"{' → '.join(str(loc) for loc in err['loc'])}: {err['msg']}"
            for err in exc.errors()
        ]
        raise InputValidationError(errors) from exc
