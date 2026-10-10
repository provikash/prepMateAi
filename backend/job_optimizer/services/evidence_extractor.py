import re
from typing import Any, Dict, List, Optional, Set, Tuple

from .resume_normalizer import EvidenceItem


# Explicitly distinct/non-equivalent technologies that should NEVER match each other
NON_EQUIVALENT_PAIRS: Set[Tuple[str, str]] = {
    ("bloc", "riverpod"),
    ("bloc", "provider"),
    ("bloc", "getx"),
    ("riverpod", "provider"),
    ("riverpod", "getx"),
    ("aws", "azure"),
    ("aws", "gcp"),
    ("aws", "google cloud"),
    ("azure", "gcp"),
    ("postgresql", "mysql"),
    ("postgresql", "mongodb"),
    ("mysql", "mongodb"),
    ("react", "flutter"),
    ("react", "vue"),
    ("angular", "react"),
    ("angular", "vue"),
    ("kotlin", "dart"),
    ("kotlin", "swift"),
    ("swift", "dart"),
}

# Synonyms that ARE equivalent
SYNONYMS: Dict[str, Set[str]] = {
    "django rest framework": {"drf", "django rest", "django-rest-framework"},
    "rest apis": {"rest api", "restful api", "restful apis"},
    "postgresql": {"postgres"},
    "kubernetes": {"k8s"},
    "node.js": {"nodejs", "node"},
    "ci/cd": {"cicd", "continuous integration", "continuous delivery"},
}

# Generic terms that indicate ambiguous / unclear evidence for specific technologies
AMBIGUOUS_TERMS: Dict[str, List[str]] = {
    "aws": ["cloud", "cloud deployment", "cloud hosting", "serverless", "cloud infrastructure"],
    "azure": ["cloud", "cloud deployment", "cloud hosting", "cloud infrastructure"],
    "gcp": ["cloud", "cloud deployment", "cloud hosting", "cloud infrastructure"],
    "kubernetes": ["containers", "container orchestration"],
    "docker": ["containers", "containerization"],
    "ci/cd": ["automated deployment", "pipeline", "release pipeline"],
}

# Source type weights for ranking evidence strength
SOURCE_TYPE_WEIGHTS = {
    "PROJECT_TECH": 1.0,
    "SKILL_KEYWORD": 0.95,
    "PROJECT_HIGHLIGHT": 0.90,
    "WORK_HIGHLIGHT": 0.90,
    "PROJECT_DESCRIPTION": 0.80,
    "WORK_SUMMARY": 0.80,
    "SUMMARY": 0.75,
    "CERTIFICATE": 0.70,
    "TITLE": 0.65,
    "EDUCATION": 0.60,
    "COURSE": 0.55,
}


class ExtractedEvidenceResult:
    def __init__(
        self,
        match_status: str,  # MATCHED, PARTIAL, MISSING, UNCLEAR
        evidence_items: List[Dict[str, Any]],
        confidence: float,
        reason: str,
    ):
        self.match_status = match_status
        self.evidence_items = evidence_items
        self.confidence = confidence
        self.reason = reason

    def to_dict(self) -> Dict[str, Any]:
        return {
            "status": self.match_status,
            "evidence": self.evidence_items,
            "confidence": self.confidence,
            "reason": self.reason,
        }


class EvidenceExtractor:
    """
    Searches normalized resume evidence for a specific requirement.
    Enforces technology safety rules and categorizes evidence into MATCHED, PARTIAL, MISSING, or UNCLEAR.
    """

    def extract(self, requirement_name: str, evidence_list: List[EvidenceItem]) -> ExtractedEvidenceResult:
        req_norm = self._clean(requirement_name)
        if not req_norm:
            return ExtractedEvidenceResult("MISSING", [], 0.0, "Empty requirement.")

        # 1. Direct and Synonym Matches
        direct_matches: List[Tuple[EvidenceItem, float]] = []
        for item in evidence_list:
            score = self._score_direct_match(req_norm, item)
            if score > 0.0:
                direct_matches.append((item, score))

        if direct_matches:
            # Sort by score descending, then by source type weight
            direct_matches.sort(
                key=lambda pair: (pair[1], SOURCE_TYPE_WEIGHTS.get(pair[0].source_type, 0.5)),
                reverse=True
            )
            top_evidence = [item.to_dict() for item, _ in direct_matches[:4]]
            first_item = direct_matches[0][0]
            reason = f"Strong evidence found in {first_item.section.title()} ({first_item.context})."
            return ExtractedEvidenceResult("MATCHED", top_evidence, direct_matches[0][1], reason)

        # 2. Check for Ambiguous / Generic Terms (UNCLEAR)
        unclear_matches: List[EvidenceItem] = []
        if req_norm in AMBIGUOUS_TERMS:
            for generic_term in AMBIGUOUS_TERMS[req_norm]:
                for item in evidence_list:
                    if generic_term in item.normalized_text:
                        unclear_matches.append(item)
                        break

        if unclear_matches:
            top_evidence = [item.to_dict() for item in unclear_matches[:3]]
            first_item = unclear_matches[0]
            reason = (
                f"{first_item.context} mentions relevant concepts ({first_item.text[:50]}...), "
                f"but {requirement_name} is not explicitly documented."
            )
            return ExtractedEvidenceResult("UNCLEAR", top_evidence, 0.5, reason)

        # 3. Partial Token Overlap (PARTIAL)
        # e.g. "Mobile Architecture" when resume has "Clean Architecture" or "Flutter"
        partial_matches: List[Tuple[EvidenceItem, float]] = []
        req_tokens = set(re.findall(r"\b\w+\b", req_norm))
        # Filter common stopwords
        req_significant_tokens = {t for t in req_tokens if len(t) > 2 and t not in {"and", "with", "for", "the"}}

        if len(req_significant_tokens) >= 2:
            for item in evidence_list:
                overlap = req_significant_tokens.intersection(item.tokens)
                # Check for forbidden conflict
                if self._has_technology_conflict(req_norm, item.tokens):
                    continue
                if len(overlap) > 0 and len(overlap) < len(req_significant_tokens):
                    fraction = len(overlap) / len(req_significant_tokens)
                    if fraction >= 0.4:
                        partial_matches.append((item, fraction))

        if partial_matches:
            partial_matches.sort(key=lambda p: p[1], reverse=True)
            top_evidence = [item.to_dict() for item, _ in partial_matches[:3]]
            first_item = partial_matches[0][0]
            reason = (
                f"Related experience documented in {first_item.section.title()}, "
                f"but does not fully cover {requirement_name}."
            )
            return ExtractedEvidenceResult("PARTIAL", top_evidence, partial_matches[0][1], reason)

        # 4. Nothing Found -> MISSING
        return ExtractedEvidenceResult(
            "MISSING",
            [],
            0.0,
            f"No supporting evidence for {requirement_name} was found in the supplied resume."
        )

    def _clean(self, text: str) -> str:
        text = text.lower().strip()
        text = re.sub(r"[\s\-_]+", " ", text)
        return text

    def _score_direct_match(self, req_norm: str, item: EvidenceItem) -> float:
        item_norm = item.normalized_text

        # Exact match
        if req_norm == item_norm:
            return 1.0

        # Exact boundary match within item
        if re.search(rf"\b{re.escape(req_norm)}\b", item_norm):
            # Check technology conflict (e.g. if searching for bloc, ensure it's not riverpod)
            if not self._has_technology_conflict(req_norm, item.tokens):
                return 0.95

        # Check synonyms
        synonyms = SYNONYMS.get(req_norm, set())
        for syn in synonyms:
            if syn == item_norm or re.search(rf"\b{re.escape(syn)}\b", item_norm):
                return 0.90

        # Also check reverse synonyms
        for canonical, syn_set in SYNONYMS.items():
            if req_norm in syn_set:
                if canonical == item_norm or re.search(rf"\b{re.escape(canonical)}\b", item_norm):
                    return 0.90

        return 0.0

    def _has_technology_conflict(self, req_norm: str, item_tokens: Set[str]) -> bool:
        """
        Ensures related but distinct technologies are not conflated (e.g. bloc vs riverpod).
        """
        for t1, t2 in NON_EQUIVALENT_PAIRS:
            if req_norm == t1 and t2 in item_tokens and t1 not in item_tokens:
                return True
            if req_norm == t2 and t1 in item_tokens and t2 not in item_tokens:
                return True
        return False
