# replit.md

## Overview

PrepMateAI is a backend API service built with Django and Django REST Framework. It provides user authentication features including registration, login, OTP-based email verification, password reset, and JWT token-based authentication. The project appears to be in early development with several bugs and incomplete implementations that need to be fixed before it will run properly.

The backend is designed to serve a Flutter mobile frontend (indicated by CORS headers dependency), though no frontend code exists in this repository yet.

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Backend Framework
- **Framework**: Django 5.2 with Django REST Framework
- **Project structure**: Django project named `core` with a `users` app for authentication
- **Working directory**: All Django code lives under the `backend/` directory. The `manage.py` file is at `backend/manage.py`, so Django commands should be run from the `backend/` directory.

### Authentication System
- **Custom User Model**: Extends `AbstractUser` with email as the primary login field (`USERNAME_FIELD = 'email'`), while keeping username as a required field
- **JWT Tokens**: Uses `djangorestframework-simplejwt` for token-based authentication (token refresh endpoint configured, but access token generation not yet wired up in login view)
- **OTP Verification**: Email-based OTP system for registration verification and password reset. OTP model stores codes with purpose (register/reset) and creation timestamp
- **Email**: Uses Django's `send_mail` for OTP delivery (requires `EMAIL_HOST_USER` and related email settings to be configured)

### API Endpoints
All under `/api/auth/`:
- `POST /api/auth/register/` — User registration
- `POST /api/auth/verify-otp/` — OTP verification
- `POST /api/auth/login/` — User login
- `POST /api/auth/forget-password/` — Request password reset OTP
- `POST /api/auth/reset-password/` — Reset password with OTP
- `POST /api/auth/token/refresh/` — JWT token refresh

### Database
- **Default**: SQLite (Django default, used for development)
- **Production-ready**: `psycopg2-binary` is listed as a dependency for future PostgreSQL support
- **Custom User Manager**: `CustomUserManager` handles user creation with email normalization
- **Models**: `User` (custom auth user) and `OTP` (verification codes)

### Known Issues That Need Fixing
The codebase has several bugs that must be addressed:
1. **`settings.py` is truncated** — Missing the rest of MIDDLEWARE, AUTH_USER_MODEL setting, REST_FRAMEWORK config, CORS config, and database settings
2. **`serializers.py` has syntax errors** — `mini_length` should be `min_length`, `Meta` class is not indented inside `RegisterSerializer`, `User.object` should be `User.objects`, `serializers.charField` should be `serializers.CharField`, `validate_new_password` and `ResetPasswordSerializer` have indentation issues
3. **`views.py` is incomplete** — Missing `VerifyOTPView`, `ForgetPasswordView`, and `ResetPasswordView` classes (imported in urls.py but not defined)
4. **`utils.py` has indentation error** — `resend_otp` function body is not properly indented
5. **`apps.py` and `admin.py` are empty** — Need `UsersConfig` in apps.py and model registration in admin.py
6. **`AUTH_USER_MODEL`** must be set to `'users.User'` in settings.py
7. **Login view** authenticates by username instead of email, inconsistent with the custom user model's `USERNAME_FIELD = 'email'`
8. **Missing OTP migration** — The OTP model doesn't appear in the initial migration

### Running the Server
```bash
cd backend
pip install -r requirement.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:5000
```

## External Dependencies

### Python Packages (backend/requirement.txt)
- **Django** — Web framework
- **djangorestframework** — REST API toolkit
- **djangorestframework-simplejwt** — JWT authentication
- **django-cors-headers** — CORS support for cross-origin requests (listed in requirements but not yet configured in settings)
- **python-dotenv** — Environment variable management (listed but not yet used in settings)
- **psycopg2-binary** — PostgreSQL adapter (listed for future production use)

### External Services
- **Email Service** — Required for OTP delivery. Needs SMTP configuration (`EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD`) in settings.py
- **Database** — SQLite by default, PostgreSQL for production