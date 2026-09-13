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


def legacy_to_json_resume(raw):
    data = copy.deepcopy(raw) if isinstance(raw, dict) else {}
    if "certifications" in data and "certificates" not in data:
        data["certificates"] = [
            {"name": item.get("title", ""), "summary": item.get("description", "")} if isinstance(item, dict) else {"name": item}
            for item in data.get("certifications", []) if isinstance(item, (dict, str))
        ]
    if "personal_info" not in data and "experience" not in data and "skill_groups" not in data:
        return data
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
    return {key: value for key, value in data.items() if key in SECTIONS}


def validate_and_normalize(raw):
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
    for section in ARRAY_SECTIONS:
        value = converted.get(section, [])
        if not isinstance(value, list):
            raise serializers.ValidationError({section: "Must be an array."})
        if any(not isinstance(item, dict) for item in value):
            raise serializers.ValidationError({section: "Every item must be an object."})
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
