import re


EMAIL_PATTERN = re.compile(r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$")
PHONE_PATTERN = re.compile(r"^(\+?[0-9][0-9\-\s]{7,14}[0-9])$")
URL_PATTERN = re.compile(r"^https?://")


class ContactValidator:
    @staticmethod
    def validate(personal_info: dict) -> list[str]:
        issues = []

        email = str(personal_info.get("email", "")).strip()
        phone = str(personal_info.get("phone", "")).strip()
        linkedin = str(personal_info.get("linkedin_url") or personal_info.get("linkedin", "")).strip()
        github = str(personal_info.get("github_url") or personal_info.get("github", "")).strip()

        if not email:
            issues.append("Email is missing.")
        elif not EMAIL_PATTERN.match(email):
            issues.append("Email format appears invalid.")

        if not phone:
            issues.append("Phone number is missing.")
        elif not PHONE_PATTERN.match(phone):
            issues.append("Phone number format appears invalid.")

        if not linkedin:
            issues.append("LinkedIn profile is missing.")
        elif not URL_PATTERN.match(linkedin):
            issues.append("LinkedIn URL should start with http:// or https://.")

        if not github:
            issues.append("GitHub profile is missing.")
        elif not URL_PATTERN.match(github):
            issues.append("GitHub URL should start with http:// or https://.")

        return issues
