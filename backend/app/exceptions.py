class InternalServerError(Exception):
    """
    """

    def __init__(self, message: str = "An unexpected error occured."):
        super().__init__(message)

class InvalidImageError(Exception):
    """
    Raised when an uploaded file is not a valid image format
    """

class ImageQualityError(Exception):
    def __init__(self, reason: str):
        self.reason = reason
        super().__init__(reason)

class InvalidPatientDataError(Exception):
    """
    """