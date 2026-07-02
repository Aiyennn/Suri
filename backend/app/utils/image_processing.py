"""
utils/image_processing.py
=========================
Pure-function image metric utilities used by the image-quality service.

Each function accepts an OpenCV BGR NumPy array and returns a single float
metric.  These utilities have no side-effects and are designed to be easily
unit-tested in isolation (see ``tests/test_image_quality.py``).

Metric summary:
    blur_score       – Laplacian variance (higher = sharper).
    brightness_score – Mean pixel intensity (0–255).
    contrast_score   – Std-dev of pixel intensities (0–255).
"""

import cv2
import numpy as np


def blur_score(image) -> float:
    """
    Compute a sharpness score for the image using the Laplacian operator.

    The Laplacian highlights regions of rapid intensity change (edges).
    A high variance in the Laplacian response indicates a sharp, well-focused
    image; a low variance indicates blurriness.

    Algorithm:
        1. Convert BGR → grayscale.
        2. Apply the Laplacian second-derivative filter (cv2.CV_64F precision).
        3. Return the variance of the resulting map.

    Args:
        image (numpy.ndarray): BGR image array of shape (H, W, 3).

    Returns:
        float: Laplacian variance.  Values below 100 are considered too blurry.
    """
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    return float(cv2.Laplacian(gray, cv2.CV_64F).var())


def brightness_score(image) -> float:
    """
    Compute the mean pixel brightness of the image.

    Converts the image to grayscale and returns the arithmetic mean of all
    pixel values.  The result lies in the range [0, 255].

    Args:
        image (numpy.ndarray): BGR image array of shape (H, W, 3).

    Returns:
        float: Mean grayscale intensity.
                - < 40   → image is likely too dark (underexposed).
                - > 220  → image is likely overexposed.
                - 40–220 → acceptable brightness range.
    """
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    return float(np.mean(gray))


def contrast_score(image) -> float:
    """
    Compute the contrast of the image as the standard deviation of pixel values.

    A higher standard deviation means a wider spread of intensities, which
    corresponds to higher contrast — important for distinguishing wound tissue
    from surrounding healthy skin.

    Args:
        image (numpy.ndarray): BGR image array of shape (H, W, 3).

    Returns:
        float: Std-dev of grayscale intensities.
                Values below 15 are considered too low for reliable analysis.
    """
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    return float(np.std(gray))