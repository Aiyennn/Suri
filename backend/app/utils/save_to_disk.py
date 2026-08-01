import logging
import uuid
from pathlib import Path

from app.core.config import settings

logger = logging.getLogger(__name__)


def _save_image_to_disk(image_bytes: bytes, assessment_id: uuid.UUID, filename: str) -> str:
    """
    Persist raw image bytes to the uploads directory.

    Directory structure: ``<UPLOAD_DIR>/<assessment_id>/<filename>``

    Returns the relative path string stored in the database.
    """
    assessment_dir = Path(settings.UPLOAD_DIR) / str(assessment_id)
    assessment_dir.mkdir(parents=True, exist_ok=True)

    # Ensure unique filenames by prepending a short UUID
    unique_filename = f"{uuid.uuid4().hex[:8]}_{filename}"
    file_path = assessment_dir / unique_filename

    file_path.write_bytes(image_bytes)
    logger.debug("Saved image to %s (%d bytes)", file_path, len(image_bytes))

    # Store as a relative path from UPLOAD_DIR for portability
    return str(Path(str(assessment_id)) / unique_filename)