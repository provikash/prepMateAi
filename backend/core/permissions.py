from rest_framework.permissions import BasePermission


class IsOwner(BasePermission):
    """Allow access only to authenticated owners of an object."""

    message = "You do not have permission to access this resource."

    def has_object_permission(self, request, view, obj):
        owner = getattr(obj, "user", None)
        return bool(request.user and request.user.is_authenticated and owner == request.user)
