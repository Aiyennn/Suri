"""
services/image_processing.py
============================
Low-level image decoding service for the wound-analysis pipeline.

Converts raw binary file content (as received from an HTTP multipart upload)
into an OpenCV-compatible NumPy array that downstream services and the AI
model can consume.

Supported input formats: any format supported by OpenCV imdecode (JPEG, PNG,
BMP, TIFF, WebP, …).  The output is always a BGR uint8 NumPy array.
"""

import numpy as np
import cv2
import logging

logger = logging.getLogger(__name__)


def process_image(image_bytes: bytes):
    """
    Decode raw image bytes into a BGR NumPy array.

    Uses ``numpy.frombuffer`` to wrap the bytes without copying, then
    delegates decoding to ``cv2.imdecode`` with ``IMREAD_COLOR`` so the
    result is always a 3-channel BGR array regardless of the source format
    (e.g. grayscale JPEG, RGBA PNG).

    Args:
        image_bytes (bytes): Raw binary content of an uploaded image file.

    Returns:
        numpy.ndarray: Decoded BGR image of shape (H, W, 3) and dtype uint8.

    Raises:
        cv2.error: If ``image_bytes`` cannot be decoded as a valid image.
        ValueError: If ``image_bytes`` is empty or all-zero (imdecode returns None).
    """
    logger.info("Processing Image")
    # Wrap bytes in a NumPy array without copying — imdecode reads from this buffer.
    np_arr = np.frombuffer(image_bytes, np.uint8)
    # Decode into a 3-channel BGR image (IMREAD_COLOR discards alpha channels).
    image = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    return image