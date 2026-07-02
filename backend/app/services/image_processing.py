"""
services/image_processing.py
============================
Low-level image decoding service for the wound-analysis pipeline.

Converts raw binary file content (as received from an HTTP multipart upload)
into an OpenCV-compatible NumPy array that downstream services and the AI
model can consume.
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

    """
    logger.info("Processing Image")
    # Wrap bytes in a NumPy array without copying — imdecode reads from this buffer.
    np_arr = np.frombuffer(image_bytes, np.uint8)
    # Decode into a 3-channel BGR image (IMREAD_COLOR discards alpha channels).
    image = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    return image
