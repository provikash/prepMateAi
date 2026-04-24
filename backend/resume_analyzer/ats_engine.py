class ATSScoringEngine:
    WEIGHTS = {
        "keyword_match": 40,
        "section_completeness": 20,
        "formatting": 15,
        "content_quality": 15,
        "contact_info": 10,
    }

    @staticmethod
    def _score_sections(missing_sections: list[str]) -> int:
        total = 4
        missing = len(missing_sections)
        return int(((total - min(total, missing)) / total) * 100)

    @staticmethod
    def _score_format(format_issues: list[str]) -> int:
        if not format_issues:
            return 100
        deduction = min(60, len(format_issues) * 20)
        return max(0, 100 - deduction)

    @staticmethod
    def _score_contact(contact_issues: list[str]) -> int:
        if not contact_issues:
            return 100
        deduction = min(80, len(contact_issues) * 20)
        return max(0, 100 - deduction)

    @staticmethod
    def _score_content_quality(structured_data: dict) -> int:
        score = 0

        summary = str((structured_data.get("personal_info") or {}).get("summary", "")).strip()
        if len(summary.split()) >= 30:
            score += 30
        elif summary:
            score += 15

        experience = structured_data.get("experience") or []
        with_bullets = 0
        for entry in experience:
            if isinstance(entry, dict) and entry.get("responsibilities"):
                with_bullets += 1
        if experience:
            ratio = with_bullets / len(experience)
            score += int(ratio * 40)

        projects = structured_data.get("projects") or []
        if projects:
            score += 15

        education = structured_data.get("education") or []
        if education:
            score += 15

        return max(0, min(100, score))

    @staticmethod
    def calculate(
        keyword_match_percentage: int,
        missing_sections: list[str],
        format_issues: list[str],
        contact_issues: list[str],
        structured_data: dict,
    ) -> dict:
        section_score = ATSScoringEngine._score_sections(missing_sections)
        format_score = ATSScoringEngine._score_format(format_issues)
        contact_score = ATSScoringEngine._score_contact(contact_issues)
        content_quality_score = ATSScoringEngine._score_content_quality(structured_data)

        weighted = (
            keyword_match_percentage * ATSScoringEngine.WEIGHTS["keyword_match"]
            + section_score * ATSScoringEngine.WEIGHTS["section_completeness"]
            + format_score * ATSScoringEngine.WEIGHTS["formatting"]
            + content_quality_score * ATSScoringEngine.WEIGHTS["content_quality"]
            + contact_score * ATSScoringEngine.WEIGHTS["contact_info"]
        ) / 100

        final_score = int(round(weighted))

        return {
            "ats_score": max(0, min(100, final_score)),
            "breakdown": {
                "keyword_match": keyword_match_percentage,
                "section_completeness": section_score,
                "formatting": format_score,
                "content_quality": content_quality_score,
                "contact_info": contact_score,
            },
        }
