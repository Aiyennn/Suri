import cv2
import numpy as np

def blur_score(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    return float(cv2.Laplacian(gray, cv2.CV_64F).var())

def brightness_score(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    return float(np.mean(gray))

def contrast_score(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    return float(np.std(gray))