"""Validation for PDFs rendered from immutable resume-version snapshots."""

from dataclasses import dataclass


class PDFValidationError(ValueError):
    pass


@dataclass(frozen=True)
class PDFValidationResult:
    page_count: int
    extracted_text: str


def validate_optimized_pdf(pdf_bytes, *, version, applied_values=()):
    if not isinstance(pdf_bytes, (bytes, bytearray)) or not pdf_bytes:
        raise PDFValidationError("empty_pdf")
    try:
        import fitz

        document = fitz.open(stream=bytes(pdf_bytes), filetype="pdf")
        try:
            page_count = document.page_count
            if page_count < 1:
                raise PDFValidationError("pdf_has_no_pages")
            text = "\n".join(page.get_text() for page in document)
        finally:
            document.close()
    except PDFValidationError:
        raise
    except Exception as exc:
        raise PDFValidationError("invalid_pdf") from exc

    lowered = text.lower()
    if any(token in lowered for token in ("undefined", "{{", "}}", ">null<")):
        raise PDFValidationError("unresolved_template_output")
    expected_name = str((version.data.get("basics") or {}).get("name", "")).strip()
    if expected_name and expected_name.casefold() not in text.casefold():
        raise PDFValidationError("expected_name_missing")
    for value in applied_values:
        value = str(value).strip()
        if value and value.casefold() not in text.casefold():
            raise PDFValidationError("applied_content_missing")
    return PDFValidationResult(page_count=page_count, extracted_text=text)
