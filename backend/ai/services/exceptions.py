class AIServiceError(Exception):
    """Base exception for AI service failures."""


class AIServiceConfigurationError(AIServiceError):
    """Raised when required AI configuration is missing or invalid."""


class AIServiceTimeoutError(AIServiceError):
    """Raised when AI provider request times out."""


class AIServiceProviderError(AIServiceError):
    """Raised when AI provider returns an error response."""


class AIServiceResponseError(AIServiceError):
    """Raised when AI provider response cannot be parsed as expected."""
