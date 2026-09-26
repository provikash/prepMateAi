import logging
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone
from users.models import UserProfile
from users.services.phone_service import normalize_indian_phone
from resume.models import Resume, ResumeTemplate
from resume.json_resume import empty_resume
from job_optimizer.models import JobDescription, OptimizationSession, OptimizationSuggestion
from ai.models import AICreditAccount, AICreditTransaction

User = get_user_model()
logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "Creates or updates a fully seeded test user account for development and OTP bypass testing."

    def add_arguments(self, parser):
        parser.add_argument(
            "--phone",
            default="9999999999",
            help="Mobile phone number for the test user (default: 9999999999)",
        )
        parser.add_argument(
            "--email",
            default="testuser@prepmate.ai",
            help="Email address for the test user (default: testuser@prepmate.ai)",
        )
        parser.add_argument(
            "--name",
            default="Test Candidate",
            help="Display name for the test user (default: Test Candidate)",
        )
        parser.add_argument(
            "--credits",
            type=int,
            default=1000,
            help="Initial AI credits balance to grant (default: 1000)",
        )

    def handle(self, *args, **options):
        raw_phone = options["phone"]
        email = options["email"].strip().lower()
        name = options["name"].strip()

        phone_number = normalize_indian_phone(raw_phone)
        self.stdout.write(f"Preparing test account for phone: {phone_number} ({email})...")

        now = timezone.now()

        # 1. User
        user = User.objects.filter(phone_number=phone_number).first()
        if not user:
            user = User.objects.filter(email=email).first()

        if user:
            user.phone_number = phone_number
            user.email = email
            user.name = name
            user.first_name = name.split()[0] if name else ""
            user.last_name = " ".join(name.split()[1:]) if " " in name else ""
            user.is_phone_verified = True
            user.phone_verified_at = now
            user.profile_completed = True
            user.is_verified = True
            user.is_active = True
            user.save()
            self.stdout.write(self.style.SUCCESS(f"Updated existing user: ID={user.pk}, phone={user.phone_number}"))
        else:
            user = User.objects.create_mobile_user(
                phone_number=phone_number,
                email=email,
                name=name,
                first_name=name.split()[0] if name else "",
                last_name=" ".join(name.split()[1:]) if " " in name else "",
                is_phone_verified=True,
                phone_verified_at=now,
                profile_completed=True,
                is_verified=True,
                is_active=True,
            )
            self.stdout.write(self.style.SUCCESS(f"Created new user: ID={user.pk}, phone={user.phone_number}"))

        # 2. UserProfile
        profile, created = UserProfile.objects.get_or_create(user=user)
        profile.full_name = name
        profile.phone = phone_number
        profile.location = "Bengaluru, Karnataka, India"
        profile.job_title = "Senior Full Stack Engineer"
        profile.bio = (
            "Versatile Software Engineer with 5+ years of experience designing and deploying scalable web and "
            "mobile applications using Python, Django, Flutter, and generative AI services."
        )
        profile.linkedin = "https://linkedin.com/in/test-candidate"
        profile.github = "https://github.com/test-candidate"
        profile.portfolio_url = "https://prepmate.ai"
        profile.save()
        self.stdout.write(self.style.SUCCESS("Ensured UserProfile is populated with full details."))

        # 3. Sample Resume & Template
        template = ResumeTemplate.objects.filter(is_active=True).first()
        resume_data = empty_resume()
        resume_data["basics"] = {
            "name": name,
            "label": "Senior Full Stack Engineer",
            "email": email,
            "phone": phone_number,
            "url": "https://prepmate.ai",
            "summary": (
                "Passionate Full Stack Developer specializing in high-concurrency backend architectures, "
                "intuitive mobile UX with Flutter, and automated AI workflows."
            ),
            "location": {
                "address": "123 Tech Park",
                "postalCode": "560001",
                "city": "Bengaluru",
                "countryCode": "IN",
                "region": "Karnataka",
            },
            "profiles": [
                {
                    "network": "LinkedIn",
                    "username": "test-candidate",
                    "url": "https://linkedin.com/in/test-candidate",
                },
                {
                    "network": "GitHub",
                    "username": "test-candidate",
                    "url": "https://github.com/test-candidate",
                },
            ],
        }
        resume_data["work"] = [
            {
                "name": "CloudScale Innovations",
                "position": "Senior Software Engineer",
                "url": "https://example.com",
                "startDate": "2023-01",
                "endDate": "",
                "summary": "Led architecture and development of scalable microservices and cross-platform mobile apps.",
                "highlights": [
                    "Architected high-throughput REST APIs handling 5M+ daily requests with <80ms p99 latency.",
                    "Built Flutter mobile client supporting offline sync, biometrics, and reactive state management.",
                    "Integrated LLM evaluation pipelines reducing candidate matching latency by 45%.",
                ],
            },
            {
                "name": "Apex Digital Labs",
                "position": "Software Engineer",
                "url": "https://example.com",
                "startDate": "2021-06",
                "endDate": "2022-12",
                "summary": "Built backend services and developer tooling using Django, PostgreSQL, and Docker.",
                "highlights": [
                    "Engineered automated PDF generation and parsing pipelines for 200k+ documents.",
                    "Improved CI/CD test coverage from 60% to 92% across all microservices.",
                ],
            },
        ]
        resume_data["education"] = [
            {
                "institution": "National Institute of Technology",
                "url": "https://example.edu",
                "area": "Computer Science & Engineering",
                "studyType": "Bachelor of Technology",
                "startDate": "2017-08",
                "endDate": "2021-05",
                "score": "8.8 / 10.0",
                "courses": ["Data Structures", "Distributed Systems", "Cloud Computing", "Machine Learning"],
            }
        ]
        resume_data["skills"] = [
            {"name": "Python & Django", "level": "Expert", "keywords": ["Django REST Framework", "Celery", "FastAPI"]},
            {"name": "Mobile & Frontend", "level": "Advanced", "keywords": ["Flutter", "Dart", "Riverpod", "React"]},
            {"name": "Databases & Cloud", "level": "Advanced", "keywords": ["PostgreSQL", "Redis", "Docker", "AWS"]},
        ]
        resume_data["projects"] = [
            {
                "name": "PrepMate AI Job Optimizer",
                "description": "AI-powered resume optimization platform matching candidate experience to job descriptions.",
                "highlights": ["ATS keyword extraction", "Contextual bullet point rewriting", "Score forecasting"],
                "keywords": ["Python", "OpenAI", "Flutter", "Django"],
                "url": "https://prepmate.ai",
                "startDate": "2024-01",
                "endDate": "",
            }
        ]

        resume, _ = Resume.objects.update_or_create(
            user=user,
            title="Senior Full Stack Engineer Resume",
            defaults={
                "template": template,
                "template_version": template.version if template else 1,
                "data": resume_data,
                "metadata": {"source": "seed_test_account"},
            },
        )
        self.stdout.write(self.style.SUCCESS(f"Ensured sample Resume exists: ID={resume.pk}, title='{resume.title}'"))

        # 4. Sample Job Description & Optimization Session
        job_desc, _ = JobDescription.objects.update_or_create(
            user=user,
            title="Senior Backend & Mobile Engineer",
            company="Starlight Tech Systems",
            defaults={
                "description": (
                    "Starlight Tech Systems is looking for a Senior Backend & Mobile Engineer to lead "
                    "our core product engineering. Responsibilities include building robust APIs in Python/Django, "
                    "crafting clean Flutter UI, integrating generative AI, and optimizing cloud database performance."
                ),
                "source_url": "https://example.com/careers/senior-engineer",
            },
        )

        session, created = OptimizationSession.objects.get_or_create(
            user=user,
            source_resume=resume,
            job_description=job_desc,
            defaults={
                "source_resume_version": 1,
                "status": OptimizationSession.Status.READY_FOR_REVIEW,
                "source_data_snapshot": resume_data,
                "analysis_json": {
                    "match_score": 88,
                    "ats_score": 92,
                    "matched_skills": ["Python", "Django", "Flutter", "REST APIs", "PostgreSQL", "Docker"],
                    "missing_skills": ["Kubernetes", "GraphQL"],
                    "strengths": [
                        "Strong quantifiable impact in bullet points.",
                        "Excellent alignment with Python and Flutter requirements.",
                    ],
                    "recommendations": [
                        "Highlight distributed system scaling metrics.",
                        "Add mentions of cloud orchestration if applicable.",
                    ],
                },
                "match_results_json": {
                    "overall_score": 88,
                    "keyword_match_percentage": 90,
                },
            },
        )

        OptimizationSuggestion.objects.get_or_create(
            optimization_session=session,
            resume_path="work.0.highlights.0",
            defaults={
                "suggestion_type": OptimizationSuggestion.SuggestionType.EXPERIENCE_BULLET_IMPROVEMENT,
                "original_value": "Architected high-throughput REST APIs handling 5M+ daily requests with <80ms p99 latency.",
                "ai_suggestion": (
                    "Architected high-throughput REST APIs handling 5M+ daily requests with <80ms p99 latency, "
                    "improving backend efficiency by 35% through Redis caching."
                ),
                "status": OptimizationSuggestion.Status.PENDING,
            },
        )
        self.stdout.write(self.style.SUCCESS(f"Ensured sample Optimization Session exists: ID={session.pk}"))

        # 5. AI Credits Account
        desired_credits = options["credits"]
        credit_account, _ = AICreditAccount.objects.get_or_create(user=user)
        if credit_account.balance < desired_credits:
            diff = desired_credits - credit_account.balance
            before = credit_account.balance
            credit_account.balance = desired_credits
            credit_account.lifetime_earned += diff
            credit_account.save(update_fields=["balance", "lifetime_earned", "updated_at"])
            AICreditTransaction.objects.create(
                user=user,
                account=credit_account,
                transaction_type=AICreditTransaction.Type.GRANT,
                amount=diff,
                balance_before=before,
                balance_after=credit_account.balance,
                operation="test_account_seed",
                description="Test account initial credit grant",
            )
            self.stdout.write(self.style.SUCCESS(f"Granted {diff} AI credits. New balance: {credit_account.balance}"))
        else:
            self.stdout.write(self.style.SUCCESS(f"AI credit balance already sufficient: {credit_account.balance}"))

        self.stdout.write("\n" + "=" * 60)
        self.stdout.write(self.style.SUCCESS(" TEST ACCOUNT READY FOR BYPASS & TESTING!"))
        self.stdout.write("=" * 60)
        self.stdout.write(f" Mobile Number : {raw_phone} (or {phone_number})")
        self.stdout.write(" Test OTP Code : 123456")
        self.stdout.write(f" User ID       : {user.pk}")
        self.stdout.write(f" User Email    : {email}")
        self.stdout.write(f" AI Credits    : {credit_account.balance} credits available")
        self.stdout.write(f" Profile State : profile_completed = True (Direct Home Access)")
        self.stdout.write(f" Sample Resume : '{resume.title}' (ID: {resume.pk})")
        self.stdout.write("=" * 60 + "\n")
