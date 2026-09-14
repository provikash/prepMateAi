import copy
import re
from datetime import datetime
from urllib.parse import urlparse

from rest_framework import serializers


SECTIONS = (
    "basics", "work", "volunteer", "education", "awards", "certificates",
    "publications", "skills", "languages", "interests", "references", "projects",
)
ARRAY_SECTIONS = SECTIONS[1:]
SAFE_URL_SCHEMES = {"http", "https"}
DATE_PATTERN = re.compile(r"^\d{4}(?:-(?:0[1-9]|1[0-2])(?:-(?:0[1-9]|[12]\d|3[01]))?)?$")


def canonical_form_schema():
    """Return the one editable schema shared by API clients and the renderer."""
    def field(key, label, type="text", required=False, help=None, ai_actions=None):
        value = {"key": key, "label": label, "type": type, "required": required}
        if type == "list" and help is None:
            help = "Enter one item per line."
        if help:
            value["help"] = help
        if ai_actions:
            value["ai_actions"] = ai_actions
        return value

    def section(key, title, fields, *, single=False):
        if single:
            return {"key": key, "title": title, "type": "single", "fields": fields}
        return {
            "key": key,
            "title": title,
            "type": "repeatable",
            "fields": [{"key": key, "label": title, "type": "list_object", "item_fields": fields}],
        }

    return {
        "schema": "jsonresume",
        "version": 1,
        "sections": [
            section("basics", "Personal Information", [
                field("name", "Full Name", required=True), field("label", "Professional Title"),
                field("email", "Email", "email", True), field("phone", "Phone", "phone"),
                field("url", "Website", "url"), field("summary", "Professional Summary", "textarea", True, ai_actions=["improve_section"]),
                field("location", "Location", "location"), field("profiles", "Professional Links", "profiles"),
            ], single=True),
            section("work", "Work Experience", [
                field("name", "Company", required=True), field("position", "Position", required=True),
                field("url", "Company URL", "url"), field("location", "Location"),
                field("startDate", "Start Date", "date", True), field("endDate", "End Date", "date", help="Leave empty for a current position."),
                field("summary", "Summary", "textarea", ai_actions=["improve_section"]), field("highlights", "Achievements / Responsibilities", "list", ai_actions=["generate_bullets"]),
            ]),
            section("education", "Education", [
                field("institution", "Institution", required=True), field("url", "Institution URL", "url"),
                field("studyType", "Degree"), field("area", "Area of Study"), field("score", "Grade / Score"),
                field("startDate", "Start Date", "date"), field("endDate", "End Date", "date"),
                field("location", "Location"), field("courses", "Courses", "list"),
            ]),
            section("skills", "Skills", [field("name", "Category", required=True), field("level", "Level"), field("keywords", "Skills", "list", True)]),
            section("projects", "Projects", [
                field("name", "Project Name", required=True), field("description", "Description", "textarea", ai_actions=["improve_section"]),
                field("url", "Project URL", "url"), field("startDate", "Start Date", "date"), field("endDate", "End Date", "date"),
                field("roles", "Roles", "list"), field("highlights", "Highlights", "list", ai_actions=["generate_bullets"]),
            ]),
            section("certificates", "Certifications", [field("name", "Certification", required=True), field("issuer", "Issuer"), field("date", "Date", "date"), field("url", "Credential URL", "url"), field("summary", "Details", "textarea", ai_actions=["improve_section"])]),
            section("languages", "Languages", [field("language", "Language", required=True), field("fluency", "Fluency")]),
            section("awards", "Awards", [field("title", "Award", required=True), field("awarder", "Awarded By"), field("date", "Date", "date"), field("summary", "Details", "textarea", ai_actions=["improve_section"])]),
            section("volunteer", "Volunteer Experience", [field("organization", "Organization", required=True), field("position", "Position"), field("url", "Organization URL", "url"), field("startDate", "Start Date", "date"), field("endDate", "End Date", "date"), field("summary", "Summary", "textarea", ai_actions=["improve_section"]), field("highlights", "Highlights", "list", ai_actions=["generate_bullets"])]),
            section("publications", "Publications", [field("name", "Publication", required=True), field("publisher", "Publisher"), field("releaseDate", "Release Date", "date"), field("url", "URL", "url"), field("summary", "Summary", "textarea", ai_actions=["improve_section"])]),
            section("interests", "Interests", [field("name", "Interest", required=True), field("keywords", "Keywords", "list")]),
            section("references", "References", [field("name", "Name", required=True), field("reference", "Reference", "textarea")]),
        ],
    }


def empty_resume():
    return {"basics": {}, **{section: [] for section in ARRAY_SECTIONS}}


def deep_merge(original, changes):
    result = copy.deepcopy(original)
    for key, value in changes.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = copy.deepcopy(value)
    return result


def _text(value):
    return value.strip() if isinstance(value, str) else ""


def safe_url(value):
    value = _text(value)
    if not value:
        return ""
    if ":" not in value:
        value = "https://" + value
    parsed = urlparse(value)
    return value if parsed.scheme.lower() in SAFE_URL_SCHEMES and bool(parsed.netloc) else ""


def format_date(value, *, ongoing=False):
    value = _text(value)
    if not value:
        return "Present" if ongoing else ""
    if not DATE_PATTERN.fullmatch(value):
        return value
    if len(value) == 4:
        return value
    parsed = datetime.strptime(value[:7], "%Y-%m")
    return parsed.strftime("%B %Y")


def date_range(start, end):
    start_label = format_date(start)
    end_label = format_date(end, ongoing=bool(start_label))
    return " — ".join(part for part in (start_label, end_label) if part)


def _strings(value):
    if isinstance(value, str):
        value = [value]
    if not isinstance(value, list):
        return []
    return [_text(item) for item in value if _text(item)]


def _clean_mapping(item):
    return {key: value for key, value in item.items() if value not in (None, "", [], {})}


def _has_meaningful_value(value):
    if isinstance(value, dict):
        return any(_has_meaningful_value(part) for part in value.values())
    if isinstance(value, (list, tuple)):
        return any(_has_meaningful_value(part) for part in value)
    return value not in (None, "")


def legacy_to_json_resume(raw):
    data = copy.deepcopy(raw) if isinstance(raw, dict) else {}
    if "certifications" in data and "certificates" not in data:
        data["certificates"] = [
            {"name": item.get("title", ""), "summary": item.get("description", "")} if isinstance(item, dict) else {"name": item}
            for item in data.get("certifications", []) if isinstance(item, (dict, str))
        ]
    personal = data.get("personal_info") if isinstance(data.get("personal_info"), dict) else {}
    basics = copy.deepcopy(data.get("basics")) if isinstance(data.get("basics"), dict) else {}
    for target, sources in {
        "name": ("name", "full_name"), "label": ("label", "role"), "email": ("email",),
        "phone": ("phone",), "summary": ("summary",), "url": ("url", "website"),
    }.items():
        if not basics.get(target):
            basics[target] = next((personal.get(key) for key in sources if personal.get(key)), "")
    if personal.get("location") and not basics.get("location"):
        basics["location"] = {"city": personal["location"]}
    profiles = basics.get("profiles", [])
    for network, keys in (("LinkedIn", ("linkedin_url", "linkedin")), ("GitHub", ("github_url", "github"))):
        url = next((personal.get(key) for key in keys if personal.get(key)), "")
        if url and not any(isinstance(p, dict) and p.get("url") == url for p in profiles):
            profiles.append({"network": network, "url": url})
    basics["profiles"] = profiles
    data["basics"] = basics
    if "work" not in data and isinstance(data.get("experience"), list):
        data["work"] = [{
            "name": item.get("company", ""),
            "position": item.get("role") or item.get("job_title") or item.get("title", ""),
            "summary": item.get("summary", ""),
            "highlights": item.get("highlights") or item.get("details") or item.get("responsibilities") or item.get("bullets") or [],
            "dateLabel": item.get("duration", ""),
            "location": item.get("location", ""),
        } for item in data["experience"] if isinstance(item, dict)]
    if "skill_groups" in data and not data.get("skills") and isinstance(data["skill_groups"], dict):
        data["skills"] = [{"name": key.replace("_", " ").title(), "keywords": _strings(value.split(",") if isinstance(value, str) else value)} for key, value in data["skill_groups"].items()]
    if isinstance(data.get("projects"), list):
        data["projects"] = [{
            **item,
            "name": item.get("name") or item.get("title", ""),
            "url": item.get("url") or item.get("source_code", ""),
            "highlights": item.get("highlights") or item.get("bullets") or [],
        } for item in data["projects"] if isinstance(item, dict)]
    if isinstance(data.get("education"), list):
        data["education"] = [{
            **item,
            "studyType": item.get("studyType") or item.get("degree", ""),
            "dateLabel": item.get("dateLabel") or item.get("duration") or item.get("year", ""),
        } for item in data["education"] if isinstance(item, dict)]
    # Normalize common aliases even when callers already use canonical section names.
    if isinstance(data.get("work"), list):
        data["work"] = [{
            **item,
            "name": item.get("name") or item.get("company", ""),
            "position": item.get("position") or item.get("role") or item.get("job_title") or item.get("title", ""),
            "highlights": item.get("highlights") or item.get("achievements") or item.get("responsibilities") or item.get("bullets") or [],
            "startDate": item.get("startDate") or item.get("start_date", ""),
            "endDate": item.get("endDate") if "endDate" in item else item.get("end_date"),
        } for item in data["work"] if isinstance(item, dict)]
    if isinstance(data.get("certificates"), list):
        data["certificates"] = [{
            **item,
            "name": item.get("name") or item.get("title", ""),
            "issuer": item.get("issuer") or item.get("awarder", ""),
            "date": item.get("date") or item.get("issue_date", ""),
            "url": item.get("url") or item.get("credential_url", ""),
            "summary": item.get("summary") or item.get("description", ""),
        } for item in data["certificates"] if isinstance(item, dict)]
    return {key: value for key, value in data.items() if key in SECTIONS}


def validate_and_normalize(raw, *, strict=True):
    if not isinstance(raw, dict):
        raise serializers.ValidationError("Resume data must be a JSON object.")
    unknown = sorted(set(raw) - set(SECTIONS) - {"personal_info", "experience", "skill_groups", "certifications"})
    if unknown:
        raise serializers.ValidationError({key: "Unknown JSON Resume section." for key in unknown})
    data = empty_resume()
    converted = legacy_to_json_resume(raw)
    basics = converted.get("basics", {})
    if not isinstance(basics, dict):
        raise serializers.ValidationError({"basics": "Must be an object."})
    data["basics"] = copy.deepcopy(basics)
    has_content = any(bool(converted.get(section)) for section in SECTIONS)
    if strict and has_content and not _text(data["basics"].get("name") or data["basics"].get("full_name")):
        raise serializers.ValidationError({"basics": {"name": "Full name is required."}})
    schema_sections = {section["key"]: section for section in canonical_form_schema()["sections"]}

    def validate_known_fields(section, value, *, item_index=None):
        schema_fields = schema_sections[section]["fields"]
        if section != "basics":
            schema_fields = schema_fields[0]["item_fields"]
        errors = {}
        for definition in schema_fields:
            key = definition["key"]
            if key not in value:
                if strict and item_index is not None and definition.get("required"):
                    errors[key] = "This field is required."
                continue
            field_value = value[key]
            field_type = definition.get("type", "text")
            if field_value is None:
                if strict and definition.get("required") and (item_index is not None or key == "name"):
                    errors[key] = "This field is required."
                continue
            if field_type == "location":
                if not isinstance(field_value, dict):
                    errors[key] = "Must be an object containing address, city, region, postalCode, and countryCode."
                else:
                    invalid = [name for name, part in field_value.items() if part is not None and not isinstance(part, str)]
                    if invalid:
                        errors[key] = {name: "Must be a string or null." for name in invalid}
            elif field_type == "profiles":
                if not isinstance(field_value, list):
                    errors[key] = "Must be an array of profile objects."
                else:
                    profile_errors = []
                    for profile in field_value:
                        if not isinstance(profile, dict):
                            profile_errors.append("Must be an object.")
                            continue
                        invalid = [name for name, part in profile.items() if part is not None and not isinstance(part, str)]
                        profile_errors.append({name: "Must be a string or null." for name in invalid})
                    if any(profile_errors):
                        errors[key] = profile_errors
            elif field_type == "list":
                if not isinstance(field_value, list):
                    errors[key] = "Must be an array of strings."
                elif any(not isinstance(part, str) for part in field_value):
                    errors[key] = "Every item must be a string."
            elif not isinstance(field_value, str):
                errors[key] = "Must be a string or null."
            elif strict and definition.get("required") and not field_value.strip() and (item_index is not None or key == "name"):
                errors[key] = "This field is required."
            elif field_type == "date" and field_value.strip() and not DATE_PATTERN.fullmatch(field_value.strip()):
                errors[key] = "Use YYYY, YYYY-MM, or YYYY-MM-DD."
        return errors

    basics_errors = validate_known_fields("basics", data["basics"])
    if basics_errors:
        raise serializers.ValidationError({"basics": basics_errors})

    for section in ARRAY_SECTIONS:
        value = converted.get(section, [])
        if not isinstance(value, list):
            raise serializers.ValidationError({section: "Must be an array."})
        if any(not isinstance(item, dict) for item in value):
            raise serializers.ValidationError({section: "Every item must be an object."})
        value = [item for item in value if _has_meaningful_value(item)]
        item_errors = [validate_known_fields(section, item, item_index=index) for index, item in enumerate(value)]
        if any(item_errors):
            raise serializers.ValidationError({section: item_errors})
        data[section] = copy.deepcopy(value)
    return data


def prepare_context(raw):
    data = validate_and_normalize(raw)
    basics = data["basics"]
    basics["url"] = safe_url(basics.get("url") or basics.get("website"))
    location = basics.get("location") if isinstance(basics.get("location"), dict) else {}
    basics["location_label"] = ", ".join(filter(None, [_text(location.get("address")), _text(location.get("city")), _text(location.get("region")), _text(location.get("postalCode")), _text(location.get("countryCode"))]))
    basics["profiles"] = [
        _clean_mapping({**profile, "url": safe_url(profile.get("url"))})
        for profile in basics.get("profiles", []) if isinstance(profile, dict) and any(_text(profile.get(k)) for k in ("network", "username", "url"))
    ]
    url_fields = {"work": "url", "volunteer": "url", "education": "url", "certificates": "url", "publications": "url", "projects": "url"}
    list_fields = {"work": "highlights", "volunteer": "highlights", "education": "courses", "skills": "keywords", "interests": "keywords", "projects": "highlights", "projects_roles": "roles"}
    for section in ARRAY_SECTIONS:
        prepared = []
        for source in data[section]:
            item = copy.deepcopy(source)
            if section in url_fields:
                item[url_fields[section]] = safe_url(item.get(url_fields[section]))
            if section in list_fields:
                item[list_fields[section]] = _strings(item.get(list_fields[section]))
            if section == "projects":
                item["roles"] = _strings(item.get("roles"))
            if section in {"work", "volunteer", "education", "projects"}:
                item["date_range"] = _text(item.get("dateLabel")) or date_range(item.get("startDate"), item.get("endDate"))
            if section in {"awards", "certificates", "publications"}:
                item["date_label"] = format_date(item.get("date") or item.get("releaseDate"))
            cleaned = _clean_mapping(item)
            if cleaned:
                prepared.append(cleaned)
        data[section] = prepared
    # Read-only compatibility aliases for existing backend templates and clients.
    data["personal_info"] = {
        **basics,
        "linkedin_url": next((p.get("url", "") for p in basics["profiles"] if str(p.get("network", "")).lower() == "linkedin"), ""),
        "github_url": next((p.get("url", "") for p in basics["profiles"] if str(p.get("network", "")).lower() == "github"), ""),
    }
    data["experience"] = data["work"]
    data["certifications"] = data["certificates"]
    for section in ARRAY_SECTIONS:
        data[f"has_{section}"] = bool(data[section])
    data["has_experience"] = bool(data["work"])
    data["has_certifications"] = bool(data["certificates"])
    return data
