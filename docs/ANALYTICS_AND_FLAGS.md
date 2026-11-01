# H10 — Recovery Analytics & Clinical Flags

The analytics engine evaluates patient recovery trajectories, calculates individualized baselines, and raises deterministic rule-based flags for clinician review.

---

## 1. Individualized Patient Baseline
Recovery in neurological rehabilitation is highly heterogeneous. Rather than comparing against arbitrary population norms, H10 computes the patient's own baseline:
- **Calculation Rule:** Median of the first 3 valid (`data_quality == 'good'`) sessions for each exercise type.
- **Baseline Metrics:**
  - Established Fist ROM %
  - Established Pinch ROM %
  - Established Forearm Rotation Angle
  - Baseline Movement Consistency Score
- **Status:** Marked `in_progress` until 3 valid sessions are completed, then `established`.

---

## 2. Recovery Trend Classification (`TrendClassifier`)
Trends are evaluated over a rolling 14-day or 6-week window:
- **`improving`:** Metric increased by $\ge 10\%$ compared to baseline over the window with low variance.
- **`stable`:** Metric within $\pm 5\%$ of baseline across consecutive sessions.
- **`declining`:** Metric decreased by $\ge 10\%$ relative to baseline.
- **`plateau`:** Metric has not changed by $> 3\%$ over $\ge 6$ consecutive sessions.
- **`variable`:** Standard deviation of metrics exceeds $20\%$ of mean excursion.
- **`insufficientData`:** Fewer than 3 sessions in evaluation window.

---

## 3. Rule-Based Clinical Flags (`FlagGenerator`)

Clinical flags highlight potential safety risks, compensation strategies, or progression opportunities:

| Rule Name | Severity | Condition | Suggested Clinical Action |
|---|---|---|---|
| `fatigue_drop_high` | `review` | Fatigue drop $\ge 20\%$ in session | Evaluate repetition target; consider increasing rest interval to $3.0\text{ s}$. |
| `pain_increase` | `review` | Reported pain $\ge 5/10$ or increase of $\ge 2$ points | Follow up regarding soreness; reduce exercise intensity. |
| `rom_below_plan` | `info` | Achieved mean ROM $< 80\%$ of target plan band | Check for fatigue or spasticity; consider adjusting target ROM band. |
| `repetition_incomplete_repeated` | `review` | $> 50\%$ rejected/incomplete reps in 2 consecutive sessions | Reassess glove fit, sensor alignment, and patient exercise tolerance. |
| `consistency_decline` | `info` | Consistency score dropped $> 15$ points below patient baseline | Inspect for compensatory trunk or shoulder movements. |
| `calibration_drift_detected` | `info` | Baseline drift $> 15\%$ on flex channels across 3 sessions | Recalibrate glove; check sensor ribbon integrity. |

### Clinician Acknowledgment Workflow
- All raised flags remain open until a clinician reviews them on the Clinician Dashboard.
- Clinicians enter a clinical note (e.g., *"Reviewed in clinic; decreased prescribed reps from 12 to 10"*).
- The acknowledgment is timestamped, recorded with the clinician's ID, and saved to the audit log.
