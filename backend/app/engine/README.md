# Wound Assessment Rule Engine

The wound assessment engine converts structured wound observations into a deterministic clinical risk assessment. It does not make a diagnosis, and does not replace a licensed healthcare professional's clinical judgement.

---

## Purpose & Separation of Concerns

The wound analysis pipeline separates two clear responsibilities:

1. **AI Vision Model (`app/ai/`)**: Identifies wound characteristics from images (wound type, severity, healing stage, redness, bleeding, exudate).
2. **Deterministic Rule Engine (`app/engine/`)**: Evaluates those validated characteristics against registered clinical rules to compute:
   - **Risk score & risk level** (Low, Moderate, High, Critical)
   - **Actionable care recommendations** (prioritized self-care guidance)
   - **"What to Monitor" warning signs** (`monitoring_signs` watch-list)
   - **Clinical referral requirement** (`referral_required`)
   - **Emergency flag** (`emergency`)
   - **Follow-up timeframe** (`follow_up`)
   - **Transparent clinical findings** (`triggered_rules`)

For any identical input, the engine is 100% deterministic and produces the exact same output.

---

## Assessment Pipeline Flow

```text
Image
  ↓
Image Quality Checks (blur, brightness, contrast)
  ↓
Vision Model Output (type, severity, stage, redness, bleeding, exudate, confidence)
  ↓
1. Validation (validation.py / schemas.py)
  ↓
2. Rule Evaluation (evaluator.py + registry.py)
  ↓
3. Risk Scoring (scoring.py)
  ↓
4. Recommendations (recommendations.py)
  ↓
5. Monitoring Signs (monitoring.py)
  ↓
6. Referral Check (referrals.py)
  ↓
7. Emergency & Follow-up Scheduling (followup.py)
  ↓
8. AssessmentResult Construction (schemas.py)
```

`WoundAssessmentEngine.assess()` is the main entry point. The API service passes the vision model result plus patient-reported context (e.g., wound duration) to it.

---

## Module Overview

| Module | Class / Function | Responsibility |
|---|---|---|
| [`engine.py`](./engine.py) | `WoundAssessmentEngine` | Public orchestrator coordinating the end-to-end evaluation pipeline. |
| [`rules.py`](./rules.py) | `Rule`, `RULES` | Dataclass definitions and the built-in clinical rule catalog. |
| [`registry.py`](./registry.py) | `RuleRegistry`, `rule_registry` | Open/closed registry indexing rules and sorting by priority. |
| [`evaluator.py`](./evaluator.py) | `RuleEvaluator`, `EvaluationResult` | Evaluates registered rules against validated input. |
| [`scoring.py`](./scoring.py) | `RiskScorer` | Sums rule score contributions and maps total score to risk levels. |
| [`recommendations.py`](./recommendations.py) | `RecommendationBuilder` | Compiles prioritized, deduplicated self-care steps and disclaimer. |
| [`monitoring.py`](./monitoring.py) | `MonitoringBuilder` | Compiles deduplicated "What to Monitor" warning signs from triggered rules. |
| [`referrals.py`](./referrals.py) | `ReferralChecker` | Determines if healthcare-provider referral is mandatory. |
| [`followup.py`](./followup.py) | `FollowUpScheduler` | Resolves follow-up timeframe constraints across rules and risk levels. |
| [`schemas.py`](./schemas.py) | `WoundAssessmentInput`, `AssessmentResult`, `TriggeredRule` | Pydantic data contracts for input and output. |
| [`validation.py`](./validation.py) | `validate_input` | Validates raw dictionary input against schema rules and cross-field constraints. |

---

## Inputs

The engine accepts a raw dictionary validated into `WoundAssessmentInput`:

* **`classification.wound_type`**: `abrasion`, `laceration`, `burn`, `pressure_ulcer`, `diabetic_ulcer`, `surgical_wound`, `contusion`, or `puncture`.
* **`classification.severity`**: `mild`, `moderate`, `severe`, or `critical`.
* **`classification.healing_stage`**: `haemostasis`, `inflammatory`, `proliferative`, `maturation`, or `necrotic`.
* **`observations.redness`**: Boolean indicating perilesional erythema.
* **`observations.bleeding`**: `none`, `minimal`, `moderate`, or `heavy`.
* **`observations.exudate`**: Object containing `present` (bool), `type` (`serous`, `serosanguinous`, `sanguineous`, `purulent`), and `amount` (`none`, `light`, `moderate`, `heavy`).
* **`confidence`**: Vision model confidence score from `0.0` to `1.0`.
* **`duration`** *(optional)*: `less_than_24h`, `1_to_3_days`, `1_week`, or `more_than_1_week`.

---

## Rules & Calculation Logic

### 1. Risk Score & Risk Level

Every triggered rule contributes its `score` to the total risk score:

| Total Score | Risk Level |
|---|---|
| 0–3 | **Low** |
| 4–7 | **Moderate** |
| 8–12 | **High** |
| 13+ | **Critical** |

### 2. Referral & Emergency

- **`emergency`**: Set to `true` if any triggered rule has `forces_emergency=True` (e.g., critical severity, heavy active bleeding).
- **`referral_required`**: Set to `true` if any triggered rule has `forces_referral=True` OR if the final risk level is `Moderate`, `High`, or `Critical`.

### 3. Follow-Up Scheduling

The engine selects the most urgent `follow_up_hours` among triggered rules. If no rule specifies a constraint, the default timeframe for the risk level is assigned:

| Risk Level | Default Follow-up |
|---|---|
| Low | 72 hours (3 days) |
| Moderate | 48 hours |
| High | 24 hours |
| Critical | Immediate |

### 4. Recommendations

Recommendations from triggered rules are sorted by rule priority, deduplicated (first occurrence wins), and appended with a standard safety disclaimer.

### 5. "What to Monitor" Guidance (`monitoring_signs`)

Each `Rule` may define an optional `monitoring` string describing specific red flags or warning signs to watch for. The `MonitoringBuilder` collects and deduplicates these in priority order:

| Triggered Rule | Example Monitoring Sign |
|---|---|
| `SEV_CRITICAL` | Uncontrolled bleeding, loss of consciousness, or signs of shock (pale skin, rapid weak pulse, confusion). |
| `BLEED_HEAVY` | Bleeding that does not stop after 10 minutes of firm, continuous pressure; blood soaking through multiple dressings. |
| `EXU_PURULENT` | Increasing or thickening pus; spreading redness, warmth, or swelling; fever above 38 °C (100.4 °F); worsening pain around the wound. |
| `STAGE_NECROTIC` | Expanding dark, black, or foul-smelling tissue; worsening wound size; fever or chills. |
| `REDNESS_PRESENT` | Redness spreading beyond the wound margin; red streaking lines extending from the wound; increasing warmth or tenderness. |
| `TYPE_BURN` | New or enlarging blisters; skin turning white, brown, or charred; loss of sensation; fever. |
| `TYPE_DIABETIC_ULCER` | Wound enlarging or deepening; change in skin colour; increased numbness or tingling; foul odour; fever or high blood sugar. |

---

## Python Usage Example

```python
from app.engine import WoundAssessmentEngine

engine = WoundAssessmentEngine()

raw_model_output = {
    "classification": {
        "wound_type": "laceration",
        "severity": "moderate",
        "healing_stage": "inflammatory",
    },
    "observations": {
        "redness": True,
        "bleeding": "minimal",
        "exudate": {
            "present": True,
            "type": "serosanguinous",
            "amount": "light",
        },
    },
    "confidence": 0.92,
}

patient_context = {"duration": "1_to_3_days"}

result = engine.assess(raw_model_output, patient_context=patient_context)

print(result.model_dump_json(indent=2))
```

### Example Output

```json
{
  "risk_score": 4,
  "risk_level": "Moderate",
  "recommendations": [
    "Clean the wound gently with sterile saline or potable water and apply a clean non-stick dressing.",
    "Monitor wound edges for spreading erythema or signs of local infection."
  ],
  "monitoring_signs": [
    "Redness spreading beyond the wound margin; red streaking lines extending from the wound; increasing warmth or tenderness in the surrounding skin.",
    "Worsening pain or swelling not improving within 48 hours; new discharge or change in discharge colour."
  ],
  "referral_required": true,
  "emergency": false,
  "follow_up": "Review in 48 hours",
  "triggered_rules": [
    {
      "id": "SEV_MODERATE",
      "name": "Moderate Severity",
      "reason": "Wound severity classified as moderate.",
      "score_contribution": 2
    },
    {
      "id": "REDNESS_PRESENT",
      "name": "Perilesional Redness",
      "reason": "Perilesional erythema detected.",
      "score_contribution": 1
    }
  ],
  "disclaimer": "This assessment is generated automatically for guidance only and does not replace clinical evaluation by a medical professional."
}
```

---

## Adding or Modifying Rules

1. Define a new `Rule` in [`rules.py`](./rules.py) or register dynamically via `rule_registry.register(rule)`:
   ```python
   Rule(
       id="MY_RULE_ID",
       name="My Rule Name",
       condition=lambda inp: inp.classification.severity == Severity.SEVERE,
       priority=50,
       score=3,
       recommendation="Apply clean dry sterile dressing.",
       explanation="Severe tissue involvement requires clinical assessment.",
       monitoring="Watch for spreading warmth or red streaks.",
       forces_referral=True,
       forces_emergency=False,
       follow_up_hours=24,
   )
   ```
2. Write unit tests in [`backend/tests/test_engine_pkg/`](../../tests/test_engine_pkg/).
3. Ensure all tests pass:
   ```bash
   pytest tests/test_engine_pkg
   ```
