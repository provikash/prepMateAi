import io
import re

from rest_framework.exceptions import ValidationError

from .ai_engine import AIImprovementEngine


class ResumeParser:
    SECTION_HEADERS = {
        "skills": ["skills", "technical skills"],
        "experience": ["experience", "work experience", "professional experience"],
        "projects": ["projects", "personal projects"],
        "education": ["education", "academic"],
        "summary": ["summary", "profile", "objective"],
    }

    @staticmethod
    def extract_pdf_text(uploaded_file) -> str:
        file_bytes = uploaded_file.read()
        uploaded_file.seek(0)

        if not file_bytes:
            raise ValidationError("Uploaded PDF is empty.")

        text_chunks = []

        try:
            import pdfplumber  # type: ignore

            with pdfplumber.open(io.BytesIO(file_bytes)) as pdf:
                for page in pdf.pages:
                    text_chunks.append(page.extract_text() or "")
        except Exception:
            try:
                import fitz  # type: ignore

                with fitz.open(stream=file_bytes, filetype="pdf") as doc:
                    for page in doc:
                        text_chunks.append(page.get_text("text") or "")
            except Exception as exc:
                raise ValidationError(
                    "Could not parse PDF. Install pdfplumber or PyMuPDF and retry."
                ) from exc

        full_text = "\n".join(text_chunks).strip()
        if not full_text:
            raise ValidationError("Unable to extract readable text from PDF.")

        return full_text

    @staticmethod
    def _extract_personal_info(raw_text: str) -> dict:
        email_match = re.search(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}", raw_text)
        phone_match = re.search(r"(\+?[0-9][0-9\-\s]{7,14}[0-9])", raw_text)
        linkedin_match = re.search(r"https?://(?:www\.)?linkedin\.com/[\w\-\./]+", raw_text, re.IGNORECASE)
        github_match = re.search(r"https?://(?:www\.)?github\.com/[\w\-\./]+", raw_text, re.IGNORECASE)

        lines = [line.strip() for line in raw_text.splitlines() if line.strip()]
        name = lines[0] if lines else ""

        summary = ""
        lower_text = raw_text.lower()
        for heading in ResumeParser.SECTION_HEADERS["summary"]:
            marker = f"\n{heading}\n"
            idx = lower_text.find(marker)
            if idx != -1:
                summary_block = raw_text[idx + len(marker) : idx + len(marker) + 1200]
                summary = " ".join(summary_block.splitlines()[:5]).strip()
                break

        return {
            "name": name,
            "email": email_match.group(0) if email_match else "",
            "phone": phone_match.group(0) if phone_match else "",
            "linkedin_url": linkedin_match.group(0) if linkedin_match else "",
            "github_url": github_match.group(0) if github_match else "",
            "summary": summary,
        }

    @staticmethod
    def _split_sections(raw_text: str) -> dict:
        lines = raw_text.splitlines()
        sections = {}
        current = "__header__"
        sections[current] = []

        header_map = {}
        for key, aliases in ResumeParser.SECTION_HEADERS.items():
            for alias in aliases:
                header_map[alias.lower()] = key

        for line in lines:
            cleaned = line.strip()
            if not cleaned:
                sections[current].append(line)
                continue

            normalized = cleaned.lower().rstrip(":")
            if normalized in header_map:
                current = header_map[normalized]
                sections.setdefault(current, [])
            else:
                sections.setdefault(current, []).append(line)

        return {k: "\n".join(v).strip() for k, v in sections.items()}

    @staticmethod
    def _extract_skills(section_text: str) -> list[str]:
        skills = []
        for raw_line in section_text.splitlines():
            line = raw_line.strip().lstrip("-*• ")
            if not line:
                continue
            for token in re.split(r"[,|/]", line):
                cleaned = token.strip()
                if cleaned and cleaned.lower() not in {s.lower() for s in skills}:
                    skills.append(cleaned)
        return skills

    @staticmethod
    def _extract_bulleted_entries(section_text: str, primary_key: str) -> list[dict]:
        entries = []
        blocks = [block.strip() for block in re.split(r"\n\s*\n", section_text) if block.strip()]

        for block in blocks:
            lines = [line.strip() for line in block.splitlines() if line.strip()]
            if not lines:
                continue

            title = lines[0]
            bullets = []
            for line in lines[1:]:
                cleaned = line.lstrip("-*• ").strip()
                if cleaned:
                    bullets.append(cleaned)

            if primary_key == "experience":
                entries.append(
                    {
                        "job_title": title,
                        "company": "",
                        "duration": "",
                        "responsibilities": bullets,
                        "technologies": [],
                    }
                )
            elif primary_key == "projects":
                entries.append(
                    {
                        "title": title,
                        "stack": "",
                        "date_range": "",
                        "bullets": bullets,
                        "source_code": "",
                        "description": "",
                    }
                )
            elif primary_key == "education":
                entries.append(
                    {
                        "degree": title,
                        "institution": "",
                        "year": "",
                        "location": "",
                    }
                )

        return entries

    @staticmethod
    def parse_text_to_structured(raw_text: str, job_role: str) -> dict:
        sections = ResumeParser._split_sections(raw_text)
        structured = {
            "personal_info": ResumeParser._extract_personal_info(raw_text),
            "skills": ResumeParser._extract_skills(sections.get("skills", "")),
            "experience": ResumeParser._extract_bulleted_entries(sections.get("experience", ""), "experience"),
            "projects": ResumeParser._extract_bulleted_entries(sections.get("projects", ""), "projects"),
            "education": ResumeParser._extract_bulleted_entries(sections.get("education", ""), "education"),
        }

        has_basic_signal = bool(structured["skills"] or structured["experience"] or structured["projects"])
        if has_basic_signal:
            return structured

        ai_structured = AIImprovementEngine.structure_resume_text(raw_text=raw_text, job_role=job_role)
        if ai_structured:
            return ai_structured

        return structured

    @staticmethod
    def parse_uploaded_pdf(uploaded_file, job_role: str) -> tuple[dict, str]:
        raw_text = ResumeParser.extract_pdf_text(uploaded_file)
        structured = ResumeParser.parse_text_to_structured(raw_text=raw_text, job_role=job_role)
        return structured, raw_text
