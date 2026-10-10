from django.test import TestCase

from job_optimizer.services.matcher import RequirementMatcher
from job_optimizer.services.resume_normalizer import ResumeNormalizer


class RequirementMatcherCriticalTest(TestCase):
    def setUp(self):
        self.matcher = RequirementMatcher()
        self.sample_resume = {
            "basics": {
                "name": "Alex Developer",
                "label": "Flutter Developer",
                "summary": "Experienced mobile engineer building cross-platform apps with Flutter and clean architecture. Familiar with cloud deployment and containerization.",
            },
            "skills": [
                {
                    "name": "Mobile Development",
                    "keywords": ["Flutter", "Dart", "Riverpod", "Clean Architecture"],
                },
                {
                    "name": "Backend",
                    "keywords": ["Python", "django rest framework", "PostgreSQL"],
                },
            ],
            "projects": [
                {
                    "name": "PrepMateAI",
                    "description": "AI-driven career platform.",
                    "technologies": ["Flutter", "Riverpod", "Django REST Framework", "PostgreSQL"],
                    "highlights": [
                        "Built mobile application using Flutter and Riverpod.",
                        "Implemented authenticated REST APIs using Django REST Framework.",
                    ],
                }
            ],
            "work": [],
            "education": [
                {
                    "institution": "State University",
                    "studyType": "Bachelor of Science",
                    "area": "Computer Science",
                }
            ],
        }

    def test_critical_case_1_exact_match(self):
        """Test 1 — Exact: JD: Flutter, Resume: Flutter -> Expected: MATCHED"""
        reqs = [{"id": "r1", "name": "Flutter", "importance": "REQUIRED", "category": "TECHNICAL_SKILL"}]
        match = self.matcher.match(reqs, self.sample_resume)
        res = match["results"][0]

        self.assertEqual(res["status"], "MATCHED")
        self.assertTrue(len(res["evidence"]) > 0)
        paths = [e["path"] for e in res["evidence"]]
        self.assertTrue(any("flutter" in p.lower() or "skills" in p or "projects" in p for p in paths))

    def test_critical_case_2_case_difference(self):
        """Test 2 — Case difference: JD: Django REST Framework, Resume: django rest framework -> Expected: MATCHED"""
        reqs = [{"id": "r2", "name": "Django REST Framework", "importance": "REQUIRED", "category": "TECHNICAL_SKILL"}]
        match = self.matcher.match(reqs, self.sample_resume)
        res = match["results"][0]

        self.assertEqual(res["status"], "MATCHED")
        self.assertTrue(len(res["evidence"]) > 0)

    def test_critical_case_3_non_equivalent_technology(self):
        """Test 3 — Non-equivalent: JD: Bloc, Resume: Riverpod -> Expected: NOT MATCHED (MISSING)"""
        reqs = [{"id": "r3", "name": "Bloc", "importance": "REQUIRED", "category": "TECHNICAL_SKILL"}]
        match = self.matcher.match(reqs, self.sample_resume)
        res = match["results"][0]

        self.assertNotEqual(res["status"], "MATCHED")
        self.assertEqual(res["status"], "MISSING")

    def test_critical_case_4_missing_requirement(self):
        """Test 4 — Missing: JD: Kubernetes, Resume: no Kubernetes -> Expected: MISSING"""
        reqs = [{"id": "r4", "name": "Kubernetes", "importance": "REQUIRED", "category": "TOOL"}]
        match = self.matcher.match(reqs, self.sample_resume)
        res = match["results"][0]

        self.assertEqual(res["status"], "MISSING")
        self.assertEqual(len(res["evidence"]), 0)

    def test_critical_case_5_ambiguous_evidence(self):
        """Test 5 — Ambiguous: JD: AWS, Resume: cloud deployment -> Expected: UNCLEAR"""
        reqs = [{"id": "r5", "name": "AWS", "importance": "PREFERRED", "category": "TECHNOLOGY"}]
        match = self.matcher.match(reqs, self.sample_resume)
        res = match["results"][0]

        self.assertEqual(res["status"], "UNCLEAR")
        self.assertTrue(len(res["evidence"]) > 0)
        self.assertIn("basics.summary", [e["path"] for e in res["evidence"]])

    def test_critical_case_6_partial_evidence(self):
        """Test 6 — Partial: JD: Mobile Architecture, Resume: Flutter + Clean Architecture + Riverpod -> Expected: PARTIAL"""
        reqs = [{"id": "r6", "name": "Mobile Architecture", "importance": "REQUIRED", "category": "TECHNICAL_SKILL"}]
        match = self.matcher.match(reqs, self.sample_resume)
        res = match["results"][0]

        self.assertEqual(res["status"], "PARTIAL")

    def test_aggregate_summary_and_alignment_score(self):
        reqs = [
            {"id": "r1", "name": "Flutter", "importance": "REQUIRED", "category": "TECHNICAL_SKILL"},
            {"id": "r2", "name": "REST APIs", "importance": "REQUIRED", "category": "TECHNICAL_SKILL"},
            {"id": "r3", "name": "Kubernetes", "importance": "REQUIRED", "category": "TOOL"},
            {"id": "r4", "name": "AWS", "importance": "PREFERRED", "category": "TECHNOLOGY"},
        ]
        match = self.matcher.match(reqs, self.sample_resume)
        summary = match["summary"]

        self.assertEqual(summary["total_requirements"], 4)
        self.assertTrue(summary["matched"] >= 1)
        self.assertTrue(summary["missing"] >= 1)
        self.assertTrue(0 <= summary["alignment_score"] <= 100)

    def test_evidence_paths_refer_to_real_resume_fields(self):
        resume = {
            "skills": [{"name": "Python", "keywords": ["Django"]}],
            "projects": [{"name": "Portfolio", "keywords": ["Flutter"]}],
            "work": [{"name": "Acme", "position": "Engineer", "keywords": ["Git"]}],
            "education": [{"studyType": "B.Tech", "area": "Computer Science", "institution": "State University"}],
        }
        paths = {item.path: item.text for item in ResumeNormalizer().normalize(resume)}
        self.assertEqual(paths["skills[0].name"], "Python")
        self.assertEqual(paths["projects[0].keywords[0]"], "Flutter")
        self.assertEqual(paths["work[0].position"], "Engineer")
        self.assertEqual(paths["education[0].area"], "Computer Science")

    def test_different_technologies_do_not_match(self):
        pairs = [("Bloc", "Riverpod"), ("AWS", "Azure"),
                 ("PostgreSQL", "MySQL"), ("Flutter", "React"),
                 ("Dart", "Kotlin")]
        for required, present in pairs:
            with self.subTest(required=required, present=present):
                result = self.matcher.match(
                    [{"id": "r1", "name": required, "importance": "REQUIRED", "category": "TECHNICAL_SKILL"}],
                    {"skills": [{"keywords": [present]}]},
                )
                self.assertNotEqual(result["results"][0]["status"], "MATCHED")
