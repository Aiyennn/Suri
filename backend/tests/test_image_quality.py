import sys

import cv2
import numpy as np

for p in sys.path:
    print(p)

from app.utils.image_metrics import (
    blur_score,
    brightness_score,
    contrast_score,
)


def test_blur_score():
    img = np.zeros((500, 500, 3), dtype=np.uint8)

    cv2.putText(
        img,
        "TEST",
        (50, 250),
        cv2.FONT_HERSHEY_SIMPLEX,
        4,
        (255, 255, 255),
        10,
    )

    blurred = cv2.GaussianBlur(img, (31, 31), 0)

    assert blur_score(img) > blur_score(blurred)

def test_brightness_score():
    dark = np.full((100, 100, 3), 50, dtype=np.uint8)
    bright = np.full((100, 100, 3), 200, dtype=np.uint8)

    assert brightness_score(bright) > brightness_score(dark)

def test_contrast_score():
    low = np.full((100, 100, 3), 128, dtype=np.uint8)

    high = np.zeros((100, 100, 3), dtype=np.uint8)
    high[:, :50] = 0
    high[:, 50:] = 255

    assert contrast_score(high) > contrast_score(low)