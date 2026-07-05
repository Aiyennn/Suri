"""
engine/rules.py
===============
Rule definitions for the wound-assessment engine.

Each ``Rule`` is a pure, stateless dataclass that pairs a boolean condition
(a callable that inspects ``WoundAssessmentInput``) with metadata about the
risk contribution, recommendation text, and any forced flags.

Rules are registered into the global ``rule_registry`` at module import time.
To add new rules without touching this file, create a separate module that
imports ``rule_registry`` and calls ``rule_registry.register()``.

Design notes
------------
* Conditions are expressed as small lambdas or named functions — never
  branching ``if/else`` chains inside the evaluator.
* ``score`` is an *additive* integer contribution; the evaluator sums
  contributions from all triggered rules.
* ``forces_referral`` and ``forces_emergency`` are OR-reduced across all
  triggered rules.
* ``follow_up_hours`` is MIN-reduced; ``None`` means this rule does not
  constrain follow-up timing.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Callable, Optional

from .models import (
    BleedingLevel,
    ExudateAmount,
    ExudateType,
    HealingStage,
    Severity,
    WoundAssessmentInput,
    WoundType,
)


# ---------------------------------------------------------------------------
# Rule dataclass
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class Rule:
    """
    A single deterministic assessment rule.

    Attributes
    ----------
    id:
        Globally unique rule identifier (e.g. ``"BLEED_HEAVY"``).
    name:
        Short human-readable label.
    description:
        Longer explanation of clinical intent.
    condition:
        A callable that takes a ``WoundAssessmentInput`` and returns ``True``
        when the rule applies.  Must be pure and side-effect free.
    priority:
        Evaluation order (lower = earlier). Used only for recommendation
        ordering; all rules are always evaluated.
    score:
        Integer points added to the cumulative risk score when triggered.
    recommendation:
        Actionable guidance string surfaced in the output.
    explanation:
        Plain-language description of *why* the rule fired (included in
        ``triggered_rules``).
    forces_referral:
        When ``True`` and the rule fires, the output will set
        ``referral_required=True`` regardless of risk score.
    forces_emergency:
        When ``True`` and the rule fires, the output will set
        ``emergency=True``.
    follow_up_hours:
        If set, this rule constrains the follow-up window; the engine takes
        the minimum across all triggered rules.
    """

    id: str
    name: str
    description: str
    condition: Callable[[WoundAssessmentInput], bool]
    priority: int
    score: int
    recommendation: str
    explanation: str
    forces_referral: bool = False
    forces_emergency: bool = False
    follow_up_hours: Optional[int] = None


# ---------------------------------------------------------------------------
# Rule definitions
# ---------------------------------------------------------------------------
# Priority bands
#   1–9   : Emergency / critical safety
#   10–29 : Severity-based
#   30–49 : Wound-type–specific
#   50–69 : Observation-based (bleeding, exudate, redness)
#   70–89 : Healing-stage–based
#   90+   : Confidence / meta warnings
# ---------------------------------------------------------------------------

RULES: list[Rule] = [

    # -----------------------------------------------------------------------
    # Emergency / Critical safety  (priority 1–9)
    # -----------------------------------------------------------------------

    Rule(
        id="SEV_CRITICAL",
        name="Critical Severity",
        description="Wound classified as critical severity — immediate clinical attention required.",
        condition=lambda i: i.classification.severity == Severity.CRITICAL,
        priority=1,
        score=6,
        recommendation=(
            "Seek emergency medical attention immediately. "
            "Apply direct pressure if bleeding is present and do not remove dressings."
        ),
        explanation="Wound severity classified as critical.",
        forces_referral=True,
        forces_emergency=True,
        follow_up_hours=0,
    ),

    Rule(
        id="BLEED_HEAVY",
        name="Heavy Active Bleeding",
        description="Heavy bleeding represents a haemorrhagic emergency.",
        condition=lambda i: i.observations.bleeding == BleedingLevel.HEAVY,
        priority=2,
        score=5,
        recommendation=(
            "Apply firm, continuous direct pressure with a clean cloth or sterile dressing. "
            "Do not remove soaked dressings — add more on top. "
            "Seek emergency care immediately."
        ),
        explanation="Heavy active bleeding detected.",
        forces_referral=True,
        forces_emergency=True,
        follow_up_hours=0,
    ),

    Rule(
        id="STAGE_NECROTIC",
        name="Necrotic Healing Stage",
        description="Necrotic tissue indicates compromised perfusion and high infection risk.",
        condition=lambda i: i.classification.healing_stage == HealingStage.NECROTIC,
        priority=3,
        score=5,
        recommendation=(
            "Necrotic tissue requires professional wound debridement. "
            "Do not attempt debridement at home. Seek specialist wound care."
        ),
        explanation="Wound contains necrotic tissue.",
        forces_referral=True,
        forces_emergency=False,
        follow_up_hours=24,
    ),

    Rule(
        id="EXU_PURULENT",
        name="Purulent Exudate",
        description="Purulent (pus-like) exudate is a strong indicator of wound infection.",
        condition=lambda i: i.observations.exudate.type == ExudateType.PURULENT,
        priority=4,
        score=4,
        recommendation=(
            "Signs consistent with wound infection are present. "
            "Keep the wound clean and covered. "
            "Consult a healthcare provider promptly for assessment and treatment."
        ),
        explanation="Purulent exudate detected — possible infection.",
        forces_referral=True,
        forces_emergency=False,
        follow_up_hours=24,
    ),

    # -----------------------------------------------------------------------
    # Severity-based  (priority 10–29)
    # -----------------------------------------------------------------------

    Rule(
        id="SEV_SEVERE",
        name="Severe Severity",
        description="Severe wounds carry significant complication risk and require professional oversight.",
        condition=lambda i: i.classification.severity == Severity.SEVERE,
        priority=10,
        score=4,
        recommendation=(
            "This wound has been assessed as severe. "
            "Contact a healthcare provider within 24 hours for evaluation."
        ),
        explanation="Wound severity classified as severe.",
        forces_referral=True,
        forces_emergency=False,
        follow_up_hours=24,
    ),

    Rule(
        id="SEV_MODERATE",
        name="Moderate Severity",
        description="Moderate wounds may progress without appropriate care.",
        condition=lambda i: i.classification.severity == Severity.MODERATE,
        priority=11,
        score=2,
        recommendation=(
            "Monitor the wound closely for signs of worsening. "
            "Keep clean and covered with an appropriate dressing."
        ),
        explanation="Wound severity classified as moderate.",
        forces_referral=False,
        forces_emergency=False,
        follow_up_hours=48,
    ),

    Rule(
        id="SEV_MILD",
        name="Mild Severity",
        description="Mild wounds typically resolve with basic home care.",
        condition=lambda i: i.classification.severity == Severity.MILD,
        priority=12,
        score=1,
        recommendation=(
            "Clean the wound gently with mild soap and water. "
            "Apply a sterile adhesive dressing."
        ),
        explanation="Wound severity classified as mild.",
        forces_referral=False,
        forces_emergency=False,
        follow_up_hours=72,
    ),

    # -----------------------------------------------------------------------
    # Wound-type–specific  (priority 30–49)
    # -----------------------------------------------------------------------

    Rule(
        id="TYPE_BURN",
        name="Burn Wound",
        description="Burns require specialised care due to infection and fluid-loss risk.",
        condition=lambda i: i.classification.wound_type == WoundType.BURN,
        priority=30,
        score=3,
        recommendation=(
            "Cool the burn under cool (not cold) running water for at least 20 minutes. "
            "Do not apply ice, butter, or home remedies. "
            "Cover loosely with a clean, non-fluffy material. Seek medical assessment."
        ),
        explanation="Wound classified as a burn.",
        forces_referral=True,
        forces_emergency=False,
        follow_up_hours=24,
    ),

    Rule(
        id="TYPE_PRESSURE_ULCER",
        name="Pressure Ulcer",
        description="Pressure ulcers indicate sustained tissue ischaemia and require repositioning and specialist care.",
        condition=lambda i: i.classification.wound_type == WoundType.PRESSURE_ULCER,
        priority=31,
        score=3,
        recommendation=(
            "Relieve pressure on the affected area immediately. "
            "Use pressure-redistributing surfaces (specialist mattress/cushion). "
            "Refer to a wound-care specialist or tissue-viability nurse."
        ),
        explanation="Wound classified as a pressure ulcer.",
        forces_referral=True,
        forces_emergency=False,
        follow_up_hours=48,
    ),

    Rule(
        id="TYPE_DIABETIC_ULCER",
        name="Diabetic Ulcer",
        description="Diabetic ulcers carry high amputation risk without prompt specialist management.",
        condition=lambda i: i.classification.wound_type == WoundType.DIABETIC_ULCER,
        priority=32,
        score=4,
        recommendation=(
            "Diabetic foot or leg ulcers require urgent specialist review. "
            "Keep the wound clean and offloaded. "
            "Contact your diabetes care team or podiatrist promptly."
        ),
        explanation="Wound classified as a diabetic ulcer.",
        forces_referral=True,
        forces_emergency=False,
        follow_up_hours=24,
    ),

    Rule(
        id="TYPE_LACERATION",
        name="Laceration",
        description="Lacerations may require closure (sutures, staples, or adhesive strips).",
        condition=lambda i: i.classification.wound_type == WoundType.LACERATION,
        priority=33,
        score=2,
        recommendation=(
            "Apply gentle pressure to control bleeding. "
            "Seek medical evaluation to determine if wound closure is required."
        ),
        explanation="Wound classified as a laceration.",
        forces_referral=False,
        forces_emergency=False,
        follow_up_hours=None,
    ),

    Rule(
        id="TYPE_PUNCTURE",
        name="Puncture Wound",
        description="Puncture wounds carry deep infection and tetanus risk despite small surface area.",
        condition=lambda i: i.classification.wound_type == WoundType.PUNCTURE,
        priority=34,
        score=2,
        recommendation=(
            "Do not probe or compress a puncture wound. "
            "Ensure tetanus vaccination is current. "
            "Seek medical review — puncture wounds are prone to deep infection."
        ),
        explanation="Wound classified as a puncture wound.",
        forces_referral=True,
        forces_emergency=False,
        follow_up_hours=48,
    ),

    # -----------------------------------------------------------------------
    # Observation-based — bleeding  (priority 50–59)
    # -----------------------------------------------------------------------

    Rule(
        id="BLEED_MODERATE",
        name="Moderate Active Bleeding",
        description="Moderate bleeding that may require professional haemostasis.",
        condition=lambda i: i.observations.bleeding == BleedingLevel.MODERATE,
        priority=50,
        score=3,
        recommendation=(
            "Apply continuous direct pressure with a clean dressing for at least 10 minutes. "
            "If bleeding does not slow, seek medical attention."
        ),
        explanation="Moderate active bleeding detected.",
        forces_referral=True,
        forces_emergency=False,
        follow_up_hours=24,
    ),

    Rule(
        id="BLEED_MINIMAL",
        name="Minimal Active Bleeding",
        description="Minimal bleeding — typically manageable with basic first aid.",
        condition=lambda i: i.observations.bleeding == BleedingLevel.MINIMAL,
        priority=51,
        score=1,
        recommendation=(
            "Apply gentle pressure with a clean cloth until bleeding stops."
        ),
        explanation="Minimal active bleeding detected.",
        forces_referral=False,
        forces_emergency=False,
        follow_up_hours=None,
    ),

    # -----------------------------------------------------------------------
    # Observation-based — exudate  (priority 60–69)
    # -----------------------------------------------------------------------

    Rule(
        id="EXU_HIGH_AMOUNT",
        name="High Exudate Volume",
        description="High exudate volume indicates significant wound activity and increases maceration risk.",
        condition=lambda i: (
            i.observations.exudate.present
            and i.observations.exudate.amount == ExudateAmount.HIGH
        ),
        priority=60,
        score=3,
        recommendation=(
            "Change dressings frequently to manage high exudate. "
            "Use an absorbent dressing (e.g. foam or alginate). "
            "Seek wound-care advice if exudate volume is increasing."
        ),
        explanation="High exudate volume observed.",
        forces_referral=True,
        forces_emergency=False,
        follow_up_hours=24,
    ),

    Rule(
        id="EXU_MODERATE_AMOUNT",
        name="Moderate Exudate Volume",
        description="Moderate exudate volume — appropriate dressing selection is important.",
        condition=lambda i: (
            i.observations.exudate.present
            and i.observations.exudate.amount == ExudateAmount.MODERATE
        ),
        priority=61,
        score=2,
        recommendation=(
            "Select a moderately absorbent dressing. "
            "Check and change dressings as needed (typically every 1–2 days)."
        ),
        explanation="Moderate exudate volume observed.",
        forces_referral=False,
        forces_emergency=False,
        follow_up_hours=48,
    ),

    Rule(
        id="EXU_SANGUINEOUS",
        name="Sanguineous (Bloody) Exudate",
        description="Fresh bloody exudate may indicate new vessel involvement or trauma.",
        condition=lambda i: i.observations.exudate.type == ExudateType.SANGUINEOUS,
        priority=62,
        score=2,
        recommendation=(
            "Bloody exudate from a wound may indicate active bleeding within the wound bed. "
            "Monitor closely. If increasing, seek medical review."
        ),
        explanation="Sanguineous (bloody) exudate detected.",
        forces_referral=False,
        forces_emergency=False,
        follow_up_hours=48,
    ),

    Rule(
        id="EXU_PRESENT_LOW",
        name="Exudate Present (Low Volume)",
        description="Low-volume serous or serosanguineous exudate is normal in healing wounds.",
        condition=lambda i: (
            i.observations.exudate.present
            and i.observations.exudate.amount == ExudateAmount.LOW
            and i.observations.exudate.type not in (
                ExudateType.PURULENT, ExudateType.SANGUINEOUS
            )
        ),
        priority=63,
        score=0,
        recommendation=(
            "A small amount of clear or pale exudate is a normal part of wound healing. "
            "Keep the wound clean and covered."
        ),
        explanation="Low-volume non-concerning exudate present.",
        forces_referral=False,
        forces_emergency=False,
        follow_up_hours=None,
    ),

    # -----------------------------------------------------------------------
    # Observation-based — redness  (priority 70)
    # -----------------------------------------------------------------------

    Rule(
        id="REDNESS_PRESENT",
        name="Perilesional Redness",
        description="Perilesional erythema is expected post-injury but may indicate early inflammation or infection.",
        condition=lambda i: i.observations.redness,
        priority=70,
        score=1,
        recommendation=(
            "Mild redness immediately around a wound is normal during the inflammatory phase. "
            "Monitor for spreading redness, warmth, or streaking — these may indicate infection."
        ),
        explanation="Perilesional redness observed.",
        forces_referral=False,
        forces_emergency=False,
        follow_up_hours=None,
    ),

    # -----------------------------------------------------------------------
    # Healing-stage–based  (priority 75–85)
    # -----------------------------------------------------------------------

    Rule(
        id="STAGE_INFLAMMATORY",
        name="Inflammatory Healing Stage",
        description="The inflammatory phase is expected, but extended inflammation warrants monitoring.",
        condition=lambda i: i.classification.healing_stage == HealingStage.INFLAMMATORY,
        priority=75,
        score=1,
        recommendation=(
            "The wound is in the inflammatory phase. "
            "Redness, swelling, and mild exudate are expected. "
            "Monitor for signs of prolonged inflammation beyond 5–7 days."
        ),
        explanation="Wound is in the inflammatory healing stage.",
        forces_referral=False,
        forces_emergency=False,
        follow_up_hours=None,
    ),

    Rule(
        id="STAGE_HEMOSTASIS",
        name="Haemostasis Stage",
        description="The wound is in early haemostasis — clot formation is underway.",
        condition=lambda i: i.classification.healing_stage == HealingStage.HEMOSTASIS,
        priority=76,
        score=1,
        recommendation=(
            "The wound is in the haemostasis phase. "
            "Avoid disturbing clot formation. Keep the area clean and protected."
        ),
        explanation="Wound is in the haemostasis stage.",
        forces_referral=False,
        forces_emergency=False,
        follow_up_hours=None,
    ),

    # -----------------------------------------------------------------------
    # Confidence / meta  (priority 90+)
    # -----------------------------------------------------------------------

    Rule(
        id="LOW_CONFIDENCE",
        name="Low Model Confidence",
        description=(
            "The AI classification confidence is below the recommended threshold. "
            "Results should be interpreted with additional caution."
        ),
        condition=lambda i: i.confidence < 0.70,
        priority=90,
        score=0,
        recommendation=(
            "⚠ The AI model's confidence in this classification is below 70%. "
            "Results may be less reliable. Clinical examination is especially important."
        ),
        explanation=f"Model confidence is below the 70% reliability threshold.",
        forces_referral=False,
        forces_emergency=False,
        follow_up_hours=None,
    ),

    Rule(
        id="MARGINAL_CONFIDENCE",
        name="Marginal Model Confidence",
        description="Model confidence is between 70% and 85% — acceptable but worth noting.",
        condition=lambda i: 0.70 <= i.confidence < 0.85,
        priority=91,
        score=0,
        recommendation=(
            "ℹ Model confidence is in the marginal range (70–85%). "
            "Treat this assessment as an adjunct to, not a replacement for, clinical evaluation."
        ),
        explanation="Model confidence is in the marginal range.",
        forces_referral=False,
        forces_emergency=False,
        follow_up_hours=None,
    ),
]
