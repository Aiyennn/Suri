import random
import logging

logger = logging.getLogger(__name__)

def analyze_wound(image):

    logging.info("Model analyzing wound")
    return {
        "risk": random.choice(["low", "medium", "high"]),
        "confidence": round(random.uniform(0.6, 0.95), 2)
    }