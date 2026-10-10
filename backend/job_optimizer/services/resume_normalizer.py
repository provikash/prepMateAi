import re
from typing import Any, Dict, List


class EvidenceItem:
    def __init__(
        self,
        path: str,
        section: str,
        context: str,
        source_type: str,
        text: str,
    ):
        self.path = path
        self.section = section
        self.context = context
        self.source_type = source_type
        self.text = text
        self.normalized_text = self._normalize(text)
        self.tokens = set(re.findall(r"\b\w+\b", self.normalized_text))

    def _normalize(self, val: str) -> str:
        val = val.lower().strip()
        val = re.sub(r"[\s\-_]+", " ", val)
        return val

    def to_dict(self) -> Dict[str, Any]:
        return {
            "path": self.path,
            "section": self.section,
            "context": self.context,
            "source_type": self.source_type,
            "text": self.text,
        }

    def __repr__(self) -> str:
        return f"<EvidenceItem path={self.path} text={self.text[:30]!r}>"


class ResumeNormalizer:
    """
    Normalizes a canonical JSON Resume data structure into a searchable list of EvidenceItem objects.
    Preserves exact JSON paths (e.g. projects[0].technologies[1]).
    """

    def normalize(self, resume_data: Dict[str, Any]) -> List[EvidenceItem]:
        evidence: List[EvidenceItem] = []
        if not isinstance(resume_data, dict):
            return evidence

        # 1. Basics
        basics = resume_data.get("basics") or {}
        if isinstance(basics, dict):
            label = basics.get("label")
            if label:
                evidence.append(EvidenceItem(
                    path="basics.label",
                    section="basics",
                    context="Professional Title",
                    source_type="TITLE",
                    text=str(label),
                ))
            summary = basics.get("summary")
            if summary:
                evidence.append(EvidenceItem(
                    path="basics.summary",
                    section="basics",
                    context="Professional Summary",
                    source_type="SUMMARY",
                    text=str(summary),
                ))

        # 2. Skills
        skills = resume_data.get("skills") or []
        if isinstance(skills, list):
            for s_idx, skill_group in enumerate(skills):
                if not isinstance(skill_group, dict):
                    continue
                group_name = skill_group.get("name") or f"Skill Group {s_idx}"
                if isinstance(skill_group.get("name"), str) and skill_group["name"].strip():
                    evidence.append(EvidenceItem(
                        path=f"skills[{s_idx}].name", section="skills",
                        context="Skill Category", source_type="SKILL_KEYWORD",
                        text=skill_group["name"].strip(),
                    ))
                keywords = skill_group.get("keywords") or []
                if isinstance(keywords, list):
                    for k_idx, kw in enumerate(keywords):
                        if kw and isinstance(kw, str):
                            evidence.append(EvidenceItem(
                                path=f"skills[{s_idx}].keywords[{k_idx}]",
                                section="skills",
                                context=str(group_name),
                                source_type="SKILL_KEYWORD",
                                text=kw.strip(),
                            ))

        # 3. Projects
        projects = resume_data.get("projects") or []
        if isinstance(projects, list):
            for p_idx, project in enumerate(projects):
                if not isinstance(project, dict):
                    continue
                proj_name = project.get("name") or f"Project {p_idx}"
                if isinstance(project.get("name"), str) and project["name"].strip():
                    evidence.append(EvidenceItem(
                        path=f"projects[{p_idx}].name", section="projects",
                        context="Project Name", source_type="TITLE",
                        text=project["name"].strip(),
                    ))

                # Technologies
                for field_name in ("technologies", "keywords"):
                    technologies = project.get(field_name) or []
                    if isinstance(technologies, list):
                        for t_idx, tech in enumerate(technologies):
                            if isinstance(tech, str) and tech.strip():
                                evidence.append(EvidenceItem(
                                    path=f"projects[{p_idx}].{field_name}[{t_idx}]",
                                    section="projects", context=str(proj_name),
                                    source_type="PROJECT_TECH", text=tech.strip(),
                                ))

                # Description
                description = project.get("description")
                if description and isinstance(description, str):
                    evidence.append(EvidenceItem(
                        path=f"projects[{p_idx}].description",
                        section="projects",
                        context=str(proj_name),
                        source_type="PROJECT_DESCRIPTION",
                        text=description.strip(),
                    ))

                # Highlights
                highlights = project.get("highlights") or []
                if isinstance(highlights, list):
                    for h_idx, hl in enumerate(highlights):
                        if hl and isinstance(hl, str):
                            evidence.append(EvidenceItem(
                                path=f"projects[{p_idx}].highlights[{h_idx}]",
                                section="projects",
                                context=str(proj_name),
                                source_type="PROJECT_HIGHLIGHT",
                                text=hl.strip(),
                            ))

        # 4. Work Experience
        work = resume_data.get("work") or []
        if isinstance(work, list):
            for w_idx, job in enumerate(work):
                if not isinstance(job, dict):
                    continue
                company = job.get("name") or "Company"
                position = job.get("position") or "Role"
                context = f"{company} — {position}"

                for field_name in ("name", "position"):
                    value = job.get(field_name)
                    if isinstance(value, str) and value.strip():
                        evidence.append(EvidenceItem(
                            path=f"work[{w_idx}].{field_name}", section="work",
                            context=context, source_type="TITLE", text=value.strip(),
                        ))
                keywords = job.get("keywords") or []
                if isinstance(keywords, list):
                    for k_idx, keyword in enumerate(keywords):
                        if isinstance(keyword, str) and keyword.strip():
                            evidence.append(EvidenceItem(
                                path=f"work[{w_idx}].keywords[{k_idx}]", section="work",
                                context=context, source_type="SKILL_KEYWORD", text=keyword.strip(),
                            ))

                # Work Summary
                summary = job.get("summary")
                if summary and isinstance(summary, str):
                    evidence.append(EvidenceItem(
                        path=f"work[{w_idx}].summary",
                        section="work",
                        context=context,
                        source_type="WORK_SUMMARY",
                        text=summary.strip(),
                    ))

                # Work Highlights
                highlights = job.get("highlights") or []
                if isinstance(highlights, list):
                    for h_idx, hl in enumerate(highlights):
                        if hl and isinstance(hl, str):
                            evidence.append(EvidenceItem(
                                path=f"work[{w_idx}].highlights[{h_idx}]",
                                section="work",
                                context=context,
                                source_type="WORK_HIGHLIGHT",
                                text=hl.strip(),
                            ))

        # 5. Education
        education = resume_data.get("education") or []
        if isinstance(education, list):
            for e_idx, edu in enumerate(education):
                if not isinstance(edu, dict):
                    continue
                institution = edu.get("institution") or "Institution"
                for field_name in ("studyType", "area", "institution"):
                    value = edu.get(field_name)
                    if isinstance(value, str) and value.strip():
                        evidence.append(EvidenceItem(
                            path=f"education[{e_idx}].{field_name}", section="education",
                            context=str(institution), source_type="EDUCATION", text=value.strip(),
                        ))

                courses = edu.get("courses") or []
                if isinstance(courses, list):
                    for c_idx, course in enumerate(courses):
                        if course and isinstance(course, str):
                            evidence.append(EvidenceItem(
                                path=f"education[{e_idx}].courses[{c_idx}]",
                                section="education",
                                context=str(institution),
                                source_type="COURSE",
                                text=course.strip(),
                            ))

        # 6. Certificates
        certificates = resume_data.get("certificates") or []
        if isinstance(certificates, list):
            for c_idx, cert in enumerate(certificates):
                if not isinstance(cert, dict):
                    continue
                name = cert.get("name")
                issuer = cert.get("issuer") or ""
                if name:
                    evidence.append(EvidenceItem(
                        path=f"certificates[{c_idx}].name",
                        section="certificates",
                        context=str(issuer) or "Certification",
                        source_type="CERTIFICATE",
                        text=f"{name} ({issuer})" if issuer else str(name),
                    ))

        return evidence
