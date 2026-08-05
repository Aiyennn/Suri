
class InternalServerError(Exception):

    def __init__(self, message: str = "An unexpected error occurred.") -> None:
        super().__init__(message)


class InvalidImageError(Exception):

    def __init__(self, message: str = "The uploaded file is not a valid image.") -> None:
        self.message = message
        super().__init__(message)


class ImageQualityError(Exception):

    def __init__(self, reason: str) -> None:
        self.reason = reason
        super().__init__(reason)


class InvalidPatientDataError(Exception):

    def __init__(self, detail: list | None = None) -> None:
        self.detail = detail or []
        super().__init__(f"Invalid patient data: {self.detail}")