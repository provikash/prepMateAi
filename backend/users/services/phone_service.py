import re


class InvalidPhoneNumber(ValueError):
    pass


def normalize_indian_phone(value):
    if not isinstance(value, str):
        raise InvalidPhoneNumber("Enter a valid Indian mobile number.")
    compact = re.sub(r"[\s-]", "", value.strip())
    if not compact or re.search(r"[^+\d]", compact) or compact.count("+") > 1 or ("+" in compact and not compact.startswith("+")):
        raise InvalidPhoneNumber("Enter a valid Indian mobile number.")
    digits = compact[1:] if compact.startswith("+") else compact
    if digits.startswith("91") and len(digits) == 12:
        digits = digits[2:]
    elif digits.startswith("0") and len(digits) == 11:
        digits = digits[1:]
    if len(digits) != 10 or not digits.isdigit() or digits[0] not in "6789":
        raise InvalidPhoneNumber("Enter a valid 10-digit Indian mobile number beginning with 6, 7, 8, or 9.")
    return "+91" + digits


def mask_phone(phone):
    return f"+91 ******{phone[-4:]}"
