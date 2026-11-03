"""
Evaluation and Confidence Intervals for RehabBridge NEXUS / H10.
Implements Build Specification v3 Section 15 and test API-10.
Calculates Wilson score 95% confidence intervals for Precision, Recall, and Uncertain Rate.
"""

import math
from typing import Dict, List, Optional, Tuple, Any


def wilson_score_interval(successes: int, total: int, z: float = 1.959964) -> Tuple[float, float]:
    """
    Computes the Wilson score interval for a binomial proportion at 95% confidence.
    Handles small sample sizes, edge proportions (0 and 1) gracefully without collapsing to zero.
    """
    if total <= 0:
        return 0.0, 0.0

    p = float(successes) / float(total)
    z2 = z * z
    denominator = 1.0 + z2 / float(total)
    center = (p + z2 / (2.0 * float(total))) / denominator
    margin = (z * math.sqrt((p * (1.0 - p) / float(total)) + (z2 / (4.0 * float(total) * float(total))))) / denominator

    lower = max(0.0, center - margin)
    upper = min(1.0, center + margin)
    return round(lower, 4), round(upper, 4)


def compute_evaluation_metrics(attempts: List[Dict[str, Any]], ground_truths: Dict[str, str]) -> Dict[str, Any]:
    """
    Computes precision, recall, uncertain rate, and Wilson intervals by matching
    system verdicts with operator ground truth labels.
    """
    total = len(attempts)
    counts = {
        "VERIFIED": 0,
        "FAILED": 0,
        "UNCERTAIN": 0,
        "ABORTED": 0,
    }
    for a in attempts:
        v = a.get("verdict", "UNCERTAIN")
        if v in counts:
            counts[v] += 1

    tp = 0  # system verified, ground truth success
    fp = 0  # system verified, ground truth failure
    fn = 0  # system failed, ground truth success
    tn = 0  # system failed, ground truth failure
    agreements = 0
    disagreements = 0
    gt_count = 0

    for a in attempts:
        att_id = a.get("id")
        verdict = a.get("verdict")
        gt_label = ground_truths.get(att_id)

        if not gt_label:
            continue
        gt_count += 1

        if verdict == "VERIFIED" and gt_label == "success":
            tp += 1
            agreements += 1
        elif verdict == "VERIFIED" and gt_label == "failure":
            fp += 1
            disagreements += 1
        elif verdict == "FAILED" and gt_label == "success":
            fn += 1
            disagreements += 1
        elif verdict == "FAILED" and gt_label == "failure":
            tn += 1
            agreements += 1
        elif verdict == "UNCERTAIN" and gt_label == "uncertain_expected":
            agreements += 1
        else:
            disagreements += 1

    # Precision = tp / (tp + fp)
    if (tp + fp) > 0:
        precision = float(tp) / float(tp + fp)
        precision_ci = list(wilson_score_interval(tp, tp + fp))
    else:
        precision = None
        precision_ci = None

    # Recall = tp / (tp + fn)
    if (tp + fn) > 0:
        recall = float(tp) / float(tp + fn)
        recall_ci = list(wilson_score_interval(tp, tp + fn))
    else:
        recall = None
        recall_ci = None

    uncertain_rate = float(counts["UNCERTAIN"]) / max(1, total)

    return {
        "total_attempts": total,
        "verified_count": counts["VERIFIED"],
        "failed_count": counts["FAILED"],
        "uncertain_count": counts["UNCERTAIN"],
        "aborted_count": counts["ABORTED"],
        "ground_truth_count": gt_count,
        "agreements": agreements,
        "disagreements": disagreements,
        "precision": round(precision, 4) if precision is not None else None,
        "recall": round(recall, 4) if recall is not None else None,
        "precision_wilson_ci": precision_ci,
        "recall_wilson_ci": recall_ci,
        "uncertain_rate": round(uncertain_rate, 4),
    }
