from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import IntegrityError
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import exception_handler


class AccountResponseMixin:
    def finalize_response(self, request, response, *args, **kwargs):
        if response.status_code >= 400 and hasattr(response, "data") and not (isinstance(response.data, dict) and response.data.get("success") is False):
            errors = response.data
            response.data = {"success": False, "message": "Request failed.", "errors": errors}
            if isinstance(errors, dict):
                response.data.update(errors)
        return super().finalize_response(request, response, *args, **kwargs)

    def handle_exception(self, exc):
        if isinstance(exc, DjangoValidationError):
            exc = ValidationError(getattr(exc, "message_dict", None) or exc.messages)
        if isinstance(exc, IntegrityError):
            exc = ValidationError("The request conflicts with existing account data.")
        response = exception_handler(exc, {"view": self, "request": self.request})
        if response is None:
            response = Response({"detail": "Unable to process the request."}, status=500)
        errors = response.data
        response.data = {"success": False, "message": "Request failed.", "errors": errors}
        if isinstance(errors, dict):
            response.data.update(errors)
        return response
