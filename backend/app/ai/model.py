import random

def analyze_wound(image):
    return {
        "risk": random.choice(["low", "medium", "high"]),
        "confidence": round(random.uniform(0.6, 0.95), 2)
    }