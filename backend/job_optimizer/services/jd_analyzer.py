import re
from typing import Any, Dict, List, Optional, Set, Tuple


# Known technologies and skills taxonomy
COMMON_TECH_TAXONOMY = {
    # Mobile
    "flutter": ("Flutter", "TECHNICAL_SKILL"),
    "dart": ("Dart", "TECHNICAL_SKILL"),
    "bloc": ("Bloc", "TECHNICAL_SKILL"),
    "riverpod": ("Riverpod", "TECHNICAL_SKILL"),
    "provider": ("Provider", "TECHNICAL_SKILL"),
    "getx": ("GetX", "TECHNICAL_SKILL"),
    "android": ("Android", "TECHNICAL_SKILL"),
    "ios": ("iOS", "TECHNICAL_SKILL"),
    "react native": ("React Native", "TECHNICAL_SKILL"),
    "swift": ("Swift", "TECHNICAL_SKILL"),
    "kotlin": ("Kotlin", "TECHNICAL_SKILL"),

    # Backend / Web
    "python": ("Python", "TECHNICAL_SKILL"),
    "django": ("Django", "TECHNICAL_SKILL"),
    "django rest framework": ("Django REST Framework", "TECHNICAL_SKILL"),
    "drf": ("Django REST Framework", "TECHNICAL_SKILL"),
    "fastapi": ("FastAPI", "TECHNICAL_SKILL"),
    "flask": ("Flask", "TECHNICAL_SKILL"),
    "nodejs": ("Node.js", "TECHNICAL_SKILL"),
    "node.js": ("Node.js", "TECHNICAL_SKILL"),
    "node": ("Node.js", "TECHNICAL_SKILL"),
    "express": ("Express.js", "TECHNICAL_SKILL"),
    "typescript": ("TypeScript", "TECHNICAL_SKILL"),
    "javascript": ("JavaScript", "TECHNICAL_SKILL"),
    "react": ("React", "TECHNICAL_SKILL"),
    "next.js": ("Next.js", "TECHNICAL_SKILL"),
    "vue": ("Vue.js", "TECHNICAL_SKILL"),
    "rest api": ("REST APIs", "TECHNICAL_SKILL"),
    "rest apis": ("REST APIs", "TECHNICAL_SKILL"),
    "restful api": ("REST APIs", "TECHNICAL_SKILL"),
    "restful apis": ("REST APIs", "TECHNICAL_SKILL"),
    "graphql": ("GraphQL", "TECHNICAL_SKILL"),
    "grpc": ("gRPC", "TECHNICAL_SKILL"),
    "jwt": ("JWT", "TECHNICAL_SKILL"),
    "oauth": ("OAuth", "TECHNICAL_SKILL"),

    # Databases
    "postgresql": ("PostgreSQL", "TECHNOLOGY"),
    "postgres": ("PostgreSQL", "TECHNOLOGY"),
    "mysql": ("MySQL", "TECHNOLOGY"),
    "mongodb": ("MongoDB", "TECHNOLOGY"),
    "sqlite": ("SQLite", "TECHNOLOGY"),
    "redis": ("Redis", "TECHNOLOGY"),
    "firebase": ("Firebase", "TECHNOLOGY"),
    "supabase": ("Supabase", "TECHNOLOGY"),

    # DevOps / Cloud / Tools
    "git": ("Git", "TOOL"),
    "github": ("GitHub", "TOOL"),
    "gitlab": ("GitLab", "TOOL"),
    "docker": ("Docker", "TOOL"),
    "kubernetes": ("Kubernetes", "TOOL"),
    "k8s": ("Kubernetes", "TOOL"),
    "ci/cd": ("CI/CD", "TOOL"),
    "cicd": ("CI/CD", "TOOL"),
    "aws": ("AWS", "TECHNOLOGY"),
    "amazon web services": ("AWS", "TECHNOLOGY"),
    "azure": ("Azure", "TECHNOLOGY"),
    "gcp": ("Google Cloud Platform", "TECHNOLOGY"),
    "google cloud": ("Google Cloud Platform", "TECHNOLOGY"),
    "postman": ("Postman", "TOOL"),
    "linux": ("Linux", "TECHNOLOGY"),

    # Architecture / Methodologies
    "clean architecture": ("Clean Architecture", "TECHNICAL_SKILL"),
    "mvvm": ("MVVM", "TECHNICAL_SKILL"),
    "mvc": ("MVC", "TECHNICAL_SKILL"),
    "microservices": ("Microservices", "TECHNICAL_SKILL"),
    "agile": ("Agile", "SOFT_SKILL"),
    "scrum": ("Scrum", "SOFT_SKILL"),
    "tdd": ("Test-Driven Development (TDD)", "TECHNICAL_SKILL"),
    "unit testing": ("Unit Testing", "TECHNICAL_SKILL"),
}

SENIORITY_PATTERNS = [
    (re.compile(r"\b(lead|principal|staff|architect)\b", re.I), "Senior / Lead"),
    (re.compile(r"\b(senior|sr\.?)\b", re.I), "Senior"),
    (re.compile(r"\b(junior|jr\.?|associate|entry[\s-]level|intern)\b", re.I), "Junior"),
    (re.compile(r"\b(mid[\s-]level|intermediate)\b", re.I), "Mid-Level"),
]

DEGREE_PATTERNS = [
    (re.compile(r"\b(?:bachelor'?s|b\.?s\.?|b\.?tech|b\.?e\.?|undergraduate)\b[^\.\n]*", re.I), "Bachelor's Degree"),
    (re.compile(r"\b(?:master'?s|m\.?s\.?|m\.?tech|graduate)\b[^\.\n]*", re.I), "Master's Degree"),
    (re.compile(r"\b(?:ph\.?d\.?|doctorate)\b[^\.\n]*", re.I), "PhD / Doctorate"),
    (re.compile(r"\bcomputer science\b", re.I), "Computer Science"),
]

EXPERIENCE_YEARS_PATTERN = re.compile(
    r"\b(\d+\+?\s*(?:to\s*\d+\+?)?\s*(?:years?|yrs?))\s*(?:of)?\s*([^\.\n,;]*)",
    re.I
)

DOMAIN_TERMS = [
    "fintech", "healthcare", "healthtech", "e-commerce", "ecommerce",
    "edtech", "saas", "b2b", "b2c", "ai/ml", "artificial intelligence",
    "iot", "crypto", "blockchain", "cybersecurity"
]

SOFT_SKILLS = [
    "communication", "teamwork", "collaboration", "problem solving",
    "critical thinking", "leadership", "mentorship", "adaptability",
    "attention to detail", "time management"
]


class JDAnalyzer:
    """
    Transforms raw Job Description text into structured, categorized, and prioritized requirements.
    Does NOT modify resume data.
    """

    def analyze(
        self,
        job_description: str,
        job_title: Optional[str] = None,
        company: Optional[str] = None,
    ) -> Dict[str, Any]:
        text = job_description or ""
        lines = [ln.strip() for ln in text.splitlines() if ln.strip()]

        detected_title = job_title or self._detect_title(lines)
        detected_seniority = self._detect_seniority(detected_title or text)

        sections = self._segment_sections(lines)

        req_skills, pref_skills, all_tech = self._extract_skills_and_technologies(sections)
        responsibilities = self._extract_responsibilities(sections)
        qualifications = self._extract_qualifications(sections)
        experience_requirements = self._extract_experience(sections, text)
        soft_skills_found = self._extract_terms(text, SOFT_SKILLS, "SOFT_SKILL")
        domain_terms_found = self._extract_terms(text, DOMAIN_TERMS, "DOMAIN")

        # Build master requirement objects
        requirements_list: List[Dict[str, Any]] = []
        req_counter = 1

        # Required skills
        for skill in req_skills:
            norm_name, category = self._normalize_tech(skill)
            requirements_list.append({
                "id": f"req_{req_counter:03d}",
                "name": norm_name,
                "text": f"Knowledge or experience in {norm_name}",
                "normalized_name": norm_name,
                "category": category,
                "importance": "REQUIRED",
                "source_text": skill,
            })
            req_counter += 1

        # Preferred skills
        for skill in pref_skills:
            norm_name, category = self._normalize_tech(skill)
            requirements_list.append({
                "id": f"req_{req_counter:03d}",
                "name": norm_name,
                "text": f"Preferred experience with {norm_name}",
                "normalized_name": norm_name,
                "category": category,
                "importance": "PREFERRED",
                "source_text": skill,
            })
            req_counter += 1

        # Responsibilities
        for resp in responsibilities[:8]:
            requirements_list.append({
                "id": f"req_{req_counter:03d}",
                "name": resp[:60] + ("..." if len(resp) > 60 else ""),
                "text": resp,
                "normalized_name": resp[:60],
                "category": "RESPONSIBILITY",
                "importance": "REQUIRED",
                "source_text": resp,
            })
            req_counter += 1

        # Qualifications
        for qual in qualifications[:5]:
            requirements_list.append({
                "id": f"req_{req_counter:03d}",
                "name": qual,
                "text": qual,
                "normalized_name": qual,
                "category": "QUALIFICATION",
                "importance": "REQUIRED",
                "source_text": qual,
            })
            req_counter += 1

        # Experience
        for exp in experience_requirements[:4]:
            requirements_list.append({
                "id": f"req_{req_counter:03d}",
                "name": exp,
                "text": exp,
                "normalized_name": exp,
                "category": "EXPERIENCE",
                "importance": "REQUIRED",
                "source_text": exp,
            })
            req_counter += 1

        # Keywords list with structured metadata
        keywords_metadata: List[Dict[str, Any]] = []
        for item in requirements_list:
            keywords_metadata.append({
                "keyword": item["name"],
                "category": item["category"],
                "importance": item["importance"],
                "source": "job_description",
                "evidence_status": None,
            })

        analysis_result = {
            "job_title": detected_title,
            "company": company or "",
            "seniority": detected_seniority,
            "required_skills": sorted(list(set(req_skills))),
            "preferred_skills": sorted(list(set(pref_skills))),
            "technologies": sorted(list(set(all_tech))),
            "responsibilities": responsibilities,
            "qualifications": qualifications,
            "experience_requirements": experience_requirements,
            "keywords": keywords_metadata,
            "soft_skills": sorted(list(set(soft_skills_found))),
            "domain_terms": sorted(list(set(domain_terms_found))),
            "requirements": requirements_list,
        }

        return self._validate_analysis(analysis_result)

    def _detect_title(self, lines: List[str]) -> Optional[str]:
        for line in lines[:5]:
            labelled = re.match(r"^(?:job\s*title|position|role)\s*:\s*(.+)$", line, flags=re.I)
            cleaned = labelled.group(1).strip() if labelled else line.strip()
            if not 3 < len(cleaned) < 80:
                continue
            if not any(re.search(rf"\b{word}\b", cleaned, re.I) for word in ("engineer", "developer", "architect", "lead", "designer", "manager", "specialist")):
                continue
            if labelled or (len(cleaned.split()) <= 6 and not re.search(r"[.!?]$", cleaned)):
                return cleaned
        return None

    def _detect_seniority(self, text: str) -> Optional[str]:
        for pattern, label in SENIORITY_PATTERNS:
            if pattern.search(text):
                return label
        return None

    def _segment_sections(self, lines: List[str]) -> Dict[str, List[str]]:
        sections: Dict[str, List[str]] = {
            "general": [],
            "required": [],
            "preferred": [],
            "responsibilities": [],
            "qualifications": [],
        }

        current = "general"
        for line in lines:
            lower = line.lower()
            if re.search(r"\b(preferred|nice to have|plus|bonus|optional)\b", lower):
                current = "preferred"
                continue
            elif re.search(r"\b(requirements?|must have|what you need|qualifications?|skills)\b", lower):
                current = "required"
                continue
            elif re.search(r"\b(responsibilities|what you'?ll do|duties|role overview)\b", lower):
                current = "responsibilities"
                continue
            elif re.search(r"\b(education|degree|background)\b", lower):
                current = "qualifications"
                continue

            sections[current].append(line)

        return sections

    def _extract_skills_and_technologies(
        self,
        sections: Dict[str, List[str]]
    ) -> Tuple[List[str], List[str], List[str]]:
        req_skills: Set[str] = set()
        pref_skills: Set[str] = set()
        all_tech: Set[str] = set()

        for term, (canonical, _) in COMMON_TECH_TAXONOMY.items():
            pattern = rf"\b{re.escape(term)}\b"

            # Check preferred section first
            preferred_matched = any(re.search(pattern, line, re.I) for line in sections["preferred"])
            required_matched = any(re.search(pattern, line, re.I) for line in sections["required"])
            general_matched = any(
                re.search(pattern, line, re.I)
                for line in sections["general"] + sections["responsibilities"]
            )

            if preferred_matched and not required_matched:
                pref_skills.add(canonical)
                all_tech.add(canonical)
            elif required_matched or general_matched:
                req_skills.add(canonical)
                all_tech.add(canonical)

        return list(req_skills), list(pref_skills), list(all_tech)

    def _extract_responsibilities(self, sections: Dict[str, List[str]]) -> List[str]:
        resps = []
        for line in sections["responsibilities"]:
            cleaned = re.sub(r"^[-*•\d\.\s]+", "", line).strip()
            if len(cleaned) > 15:
                resps.append(cleaned)
        return resps

    def _extract_qualifications(self, sections: Dict[str, List[str]]) -> List[str]:
        quals = []
        all_lines = sections["qualifications"] + sections["required"] + sections["general"]
        for line in all_lines:
            for pattern, label in DEGREE_PATTERNS:
                if pattern.search(line):
                    cleaned = re.sub(r"^[-*•\d\.\s]+", "", line).strip()
                    if cleaned and cleaned not in quals:
                        quals.append(cleaned)
        return quals

    def _extract_experience(self, sections: Dict[str, List[str]], full_text: str) -> List[str]:
        exp_list = []
        for match in EXPERIENCE_YEARS_PATTERN.finditer(full_text):
            duration = match.group(1).strip()
            context = match.group(2).strip()
            item = f"{duration} of experience"
            if context and len(context) < 60:
                item = f"{item} in {context}"
            if item not in exp_list:
                exp_list.append(item)
        return exp_list

    def _extract_terms(self, text: str, term_list: List[str], category: str) -> List[str]:
        found = []
        for term in term_list:
            if re.search(rf"\b{re.escape(term)}\b", text, re.I):
                found.append(term.title())
        return found

    def _normalize_tech(self, tech_name: str) -> Tuple[str, str]:
        key = tech_name.lower().strip()
        if key in COMMON_TECH_TAXONOMY:
            return COMMON_TECH_TAXONOMY[key]
        return tech_name, "TECHNICAL_SKILL"

    def _validate_analysis(self, result: Dict[str, Any]) -> Dict[str, Any]:
        """Ensures all required fields exist and types conform to schema."""
        required_fields = [
            "job_title", "seniority", "required_skills", "preferred_skills",
            "technologies", "responsibilities", "qualifications",
            "experience_requirements", "keywords", "soft_skills",
            "domain_terms", "requirements"
        ]
        for f in required_fields:
            if f not in result:
                result[f] = None if f in {"job_title", "seniority"} else []

        return result
