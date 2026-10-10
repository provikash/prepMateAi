from dataclasses import dataclass


class OTPProviderError(RuntimeError):
    pass


@dataclass(frozen=True)
class ProviderResult:
    message_id: str = ""
    status: str = "accepted"


class BaseOTPProvider:
    def send_otp(self, phone_number, otp, template_context=None):
        raise NotImplementedError
