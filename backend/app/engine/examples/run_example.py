"""
engine/examples/run_example.py
==============================
Demonstrates the wound-assessment engine against four representative scenarios.

Run from the backend directory with:

    python -m engine.examples.run_example

or from the app/ directory:

    python engine/examples/run_example.py
"""

from __future__ import annotations

import json
import os
import sys

# Allow running from either backend/ or backend/app/
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

from engine import WoundAssessmentEngine

SCENARIOS: list[tuple[str, dict]] = [
    (
        "Scenario 1 — Moderate Abrasion (from spec)",
        {
            "classification": {
                "wound_type": "abrasion",
                "severity": "moderate",
                "healing_stage": "inflammatory",
            },
            "observations": {
                "redness": True,
                "bleeding": "minimal",
                "exudate": {"present": True, "type": "serous", "amount": "low"},
            },
            "confidence": 0.94,
        },
    ),
    (
        "Scenario 2 — Emergency (Heavy bleeding + Critical severity)",
        {
            "classification": {
                "wound_type": "laceration",
                "severity": "critical",
                "healing_stage": "hemostasis",
            },
            "observations": {
                "redness": True,
                "bleeding": "heavy",
                "exudate": {
                    "present": True,
                    "type": "sanguineous",
                    "amount": "high",
                },
            },
            "confidence": 0.91,
        },
    ),
    (
        "Scenario 3 — Low Risk (Mild abrasion, no complications)",
        {
            "classification": {
                "wound_type": "abrasion",
                "severity": "mild",
                "healing_stage": "proliferative",
            },
            "observations": {
                "redness": False,
                "bleeding": "none",
                "exudate": {"present": False, "type": "none", "amount": "none"},
            },
            "confidence": 0.92,
        },
    ),
    (
        "Scenario 4 — Diabetic Ulcer with Infection Signs",
        {
            "classification": {
                "wound_type": "diabetic_ulcer",
                "severity": "moderate",
                "healing_stage": "inflammatory",
            },
            "observations": {
                "redness": True,
                "bleeding": "none",
                "exudate": {
                    "present": True,
                    "type": "purulent",
                    "amount": "moderate",
                },
            },
            "confidence": 0.88,
        },
    ),
]


def main() -> None:
    engine = WoundAssessmentEngine()
    separator = "=" * 70

    for title, raw_input in SCENARIOS:
        print(f"\n{separator}")
        print(f"  {title}")
        print(separator)
        print("\nInput:")
        print(json.dumps(raw_input, indent=2))

        result = engine.assess(raw_input)
        output = result.model_dump()

        print("\nOutput:")
        print(json.dumps(output, indent=2))

    print(f"\n{separator}")
    print("  All scenarios completed successfully.")
    print(separator)


if __name__ == "__main__":
    main()
