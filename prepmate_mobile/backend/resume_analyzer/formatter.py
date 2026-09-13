import re


class ResumeFormatAnalyzer:
    LONG_PARAGRAPH_WORD_LIMIT = 120

    @staticmethod
    def analyze(raw_text: str, structured_data: dict) -> list[str]:
        issues = []
        text = raw_text or ""

        bullet_prefixes = ("-", "*", "•")
        lines = [line.strip() for line in text.splitlines() if line.strip()]

        if lines and not any(line.startswith(bullet_prefixes) for line in lines):
            issues.append("No bullet points detected; use bullets for achievements and responsibilities.")

        paragraphs = [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]
        long_paragraphs = [p for p in paragraphs if len(p.split()) > ResumeFormatAnalyzer.LONG_PARAGRAPH_WORD_LIMIT]
        if long_paragraphs:
            issues.append("Long paragraphs detected; break them into concise bullets.")

        used_styles = set()
        for line in lines:
            if line.startswith("-"):
                used_styles.add("-")
            elif line.startswith("*"):
                used_styles.add("*")
            elif line.startswith("•"):
                used_styles.add("•")
        if len(used_styles) > 1:
            issues.append("Inconsistent bullet formatting detected; use a single bullet style.")

        experience = structured_data.get("experience") or []
        if isinstance(experience, list) and experience:
            weak_entries = 0
            for item in experience:
                responsibilities = item.get("responsibilities") if isinstance(item, dict) else []
                if not responsibilities:
                    weak_entries += 1
            if weak_entries:
                issues.append("Some experience entries do not include responsibilities or impact bullets.")

        return issues
