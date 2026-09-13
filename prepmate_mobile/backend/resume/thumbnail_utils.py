import io
import logging
import os

from django.core.files.base import ContentFile

from PIL import Image, ImageDraw

logger = logging.getLogger(__name__)


THUMBNAIL_MAX_SIZE = (900, 1200)
RESUME_THUMBNAIL_QUALITY = 82
TEMPLATE_THUMBNAIL_QUALITY = 84


def _image_to_content_file(image: Image.Image, image_format: str = "JPEG", quality: int = 82) -> ContentFile:
    output = io.BytesIO()
    image = image.convert("RGB")
    image.thumbnail(THUMBNAIL_MAX_SIZE, Image.Resampling.LANCZOS)
    image.save(output, format=image_format, quality=quality, optimize=True)
    output.seek(0)
    return ContentFile(output.read())


def generate_thumbnail_from_pdf(pdf_path: str):
    """Convert the first page of a PDF to a JPEG thumbnail ContentFile."""
    if not pdf_path:
        logger.warning("Resume thumbnail skipped: empty PDF path.")
        return None, None

    if not os.path.exists(pdf_path):
        logger.warning("Resume thumbnail skipped: PDF does not exist at path=%s", pdf_path)
        return None, None

    logger.info("Resume thumbnail generation started for path=%s", pdf_path)

    try:
        from pdf2image import convert_from_path

        pages = convert_from_path(
            pdf_path,
            first_page=1,
            last_page=1,
            dpi=160,
            fmt="jpeg",
            thread_count=1,
        )
        if not pages:
            logger.error("Resume thumbnail failed: no pages rendered for path=%s", pdf_path)
            return None, None

        content_file = _image_to_content_file(
            pages[0],
            image_format="JPEG",
            quality=RESUME_THUMBNAIL_QUALITY,
        )
        logger.info("Resume thumbnail generated successfully for path=%s", pdf_path)
        return content_file, "thumbnail.jpg"
    except Exception as exc:
        logger.warning(
            "Resume thumbnail generation with pdf2image failed for path=%s: %s. Falling back to PyMuPDF.",
            pdf_path,
            exc,
        )

    try:
        import fitz

        with fitz.open(pdf_path) as document:
            if document.page_count == 0:
                logger.error("Resume thumbnail failed: PDF has zero pages for path=%s", pdf_path)
                return None, None

            page = document.load_page(0)
            pixmap = page.get_pixmap(matrix=fitz.Matrix(1.5, 1.5), alpha=False)
            image = Image.open(io.BytesIO(pixmap.tobytes("png")))

        content_file = _image_to_content_file(
            image,
            image_format="JPEG",
            quality=RESUME_THUMBNAIL_QUALITY,
        )
        logger.info("Resume thumbnail generated successfully via PyMuPDF for path=%s", pdf_path)
        return content_file, "thumbnail.jpg"
    except Exception as exc:
        logger.exception("Resume thumbnail generation failed for path=%s: %s", pdf_path, exc)
        return None, None


def generate_thumbnail_from_html(html_content: str, css: str = ""):
    """Render HTML to image via imgkit; returns a JPEG ContentFile or None."""
    if not html_content:
        logger.warning("Template thumbnail skipped: empty HTML content.")
        return None, None

    logger.info("Template thumbnail generation from HTML started.")

    try:
        import imgkit

        html_document = html_content
        if css:
            html_document = f"<style>{css}</style>{html_content}"

        rendered = imgkit.from_string(
            html_document,
            output_path=False,
            options={
                "format": "jpg",
                "quality": "84",
                "width": "900",
                "disable-smart-width": "",
                "encoding": "UTF-8",
                "enable-local-file-access": "",
            },
        )

        if not rendered:
            logger.error("Template thumbnail failed: imgkit returned empty content.")
            return None, None

        image = Image.open(io.BytesIO(rendered))
        content_file = _image_to_content_file(
            image,
            image_format="JPEG",
            quality=TEMPLATE_THUMBNAIL_QUALITY,
        )
        logger.info("Template thumbnail generated successfully from HTML.")
        return content_file, "template_thumbnail.jpg"
    except Exception as exc:
        logger.exception("Template thumbnail generation from HTML failed: %s", exc)
        return None, None


def generate_default_template_thumbnail(template_name: str = "Template"):
    """Generate an in-memory fallback thumbnail image for templates."""
    logger.info("Generating default template placeholder thumbnail.")

    image = Image.new("RGB", (900, 1200), (246, 246, 246))
    draw = ImageDraw.Draw(image)

    draw.rectangle((60, 60, 840, 1140), outline=(200, 200, 200), width=6)
    draw.rectangle((90, 120, 810, 220), fill=(225, 228, 235))
    draw.rectangle((90, 260, 810, 330), fill=(233, 236, 242))
    draw.rectangle((90, 360, 690, 420), fill=(233, 236, 242))
    draw.rectangle((90, 460, 810, 520), fill=(233, 236, 242))
    draw.rectangle((90, 560, 760, 620), fill=(233, 236, 242))

    label = (template_name or "Template")[:28]
    draw.text((95, 88), label, fill=(90, 90, 90))

    content_file = _image_to_content_file(
        image,
        image_format="JPEG",
        quality=TEMPLATE_THUMBNAIL_QUALITY,
    )
    return content_file, "template_placeholder.jpg"


def build_resume_thumbnail_name(resume_id) -> str:
    safe_id = str(resume_id).replace("-", "") if resume_id else "resume"
    return f"resume_{safe_id}.jpg"


def build_template_thumbnail_name(template_id) -> str:
    safe_id = str(template_id).replace("-", "") if template_id else "template"
    return f"template_{safe_id}.jpg"
