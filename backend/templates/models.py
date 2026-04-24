from resume.models import ResumeTemplate as ResumeTemplateBase


class ResumeTemplate(ResumeTemplateBase):
    """
    Proxy model used to expose template APIs from the templates module.
    """

    class Meta:
        proxy = True
        ordering = ["name"]