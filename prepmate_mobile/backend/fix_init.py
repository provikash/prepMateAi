init_content = """from .auth import AuthService
from .google_oauth import GoogleTokenError, verify_google_id_token

__all__ = [
    "AuthService",
    "GoogleTokenError",
    "verify_google_id_token",
]
"""
with open('users/services/__init__.py', 'wb') as f:
    f.write(init_content.encode('utf-8'))
print("File written successfully")
