from typing import Any, Dict, List, Optional

from .evidence_extractor import EvidenceExtractor
from .resume_normalizer import ResumeNormalizer


class RequirementMatcher:
    """
    Coordinates matching structured Job Description requirements against a JSON Resume.
    Categorizes evidence into MATCHED, PARTIAL, MISSING, and UNCLEAR with full evidence paths.
    """

    def __init__(self):
        self.normalizer = ResumeNormalizer()
        self.extractor = EvidenceExtractor()

    def match(
        self,
        requirements: List[Dict[str, Any]],
        resume_data: Dict[str, Any],
    ) -> Dict[str, Any]:
        evidence_list = self.normalizer.normalize(resume_data)

        matched_items: List[Dict[str, Any]] = []
        partial_items: List[Dict[str, Any]] = []
        missing_items: List[Dict[str, Any]] = []
        unclear_items: List[Dict[str, Any]] = []
        all_results: List[Dict[str, Any]] = []

        for req in requirements:
            req_name = req.get("name") or req.get("normalized_name") or ""
            res = self.extractor.extract(req_name, evidence_list)

            match_entry = {
                "id": req.get("id"),
                "name": req_name,
                "category": req.get("category", "OTHER"),
                "importance": req.get("importance", "REQUIRED"),
                "source_text": req.get("source_text", req_name),
                "status": res.match_status,
                "match_strength": round(res.confidence, 2),
                "evidence": res.evidence_items,
                "explanation": res.reason,
            }

            all_results.append(match_entry)

            if res.match_status == "MATCHED":
                matched_items.append(match_entry)
            elif res.match_status == "PARTIAL":
                partial_items.append(match_entry)
            elif res.match_status == "UNCLEAR":
                unclear_items.append(match_entry)
            else:
                missing_items.append(match_entry)

        total = len(all_results)
        matched_count = len(matched_items)
        partial_count = len(partial_items)
        missing_count = len(missing_items)
        unclear_count = len(unclear_items)

        # Deterministic Alignment Score calculation:
        # Required requirements carry 1.0 weight, Preferred carry 0.5 weight
        # Matched awards 100%, Partial awards 50%, Unclear awards 25%, Missing awards 0%
        total_weight = 0.0
        earned_weight = 0.0

        for item in all_results:
            w = 1.0 if item["importance"] == "REQUIRED" else 0.5
            total_weight += w
            if item["status"] == "MATCHED":
                earned_weight += w * 1.0
            elif item["status"] == "PARTIAL":
                earned_weight += w * 0.5
            elif item["status"] == "UNCLEAR":
                earned_weight += w * 0.25

        alignment_score = int(round((earned_weight / total_weight) * 100)) if total_weight > 0 else 0
        alignment_score = max(0, min(100, alignment_score))

        return {
            "summary": {
                "total_requirements": total,
                "matched": matched_count,
                "partial": partial_count,
                "missing": missing_count,
                "unclear": unclear_count,
                "alignment_score": alignment_score,
            },
            "results": all_results,
            "matched_requirements": matched_items,
            "partial_requirements": partial_items,
            "missing_requirements": missing_items,
            "unclear_requirements": unclear_items,
        }
