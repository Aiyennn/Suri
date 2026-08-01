"""
services/image_processing.py
============================
Low-level image decoding service for the wound-analysis pipeline.

Converts raw binary file content (as received from an HTTP multipart upload)
into an OpenCV-compatible NumPy array that downstream services and the AI
model can consume.
"""

import logging

import cv2
import numpy as np

from app.exceptions import InvalidImageError

logger = logging.getLogger(__name__)


def process_image(image_bytes: bytes):
    """
    Decode raw image bytes into a BGR NumPy array.

    Uses ``numpy.frombuffer`` to wrap the bytes without copying, then
    delegates decoding to ``cv2.imdecode`` with ``IMREAD_COLOR`` so the
    result is always a 3-channel BGR array regardless of the source format
    (e.g. grayscale JPEG, RGBA PNG).

    """
    logger.debug(
        "Starting image decoding (size=%d bytes)",
        len(image_bytes)
    )

    try:
        # Wrap bytes in a NumPy array without copying — imdecode reads from this buffer.
        np_arr = np.frombuffer(image_bytes, np.uint8)

        logger.debug(
            "Created NumPy buffer (shape=%s dtype=%s)",
            np_arr.shape,
            np_arr.dtype,
        )

        # Decode into a 3-channel BGR image (IMREAD_COLOR discards alpha channels).
        image = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

        if image is None:
            logger.warning(
                "OpenCV failed to decode image (size=%d bytes)",
                len(image_bytes),
            )
            raise InvalidImageError 
        
        logger.info(
            "Image decoded successfully (shape=%s dtype=%s)",
            image.shape,
            image.dtype
        )
        
        return image

    except Exception:
        raise
