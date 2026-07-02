import numpy as np
import cv2
import logging

logger = logging.getLogger(__name__)

def process_image(image_bytes: bytes):
    logger.info("Processing Image")
    np_arr = np.frombuffer(image_bytes, np.uint8)
    image = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    return image