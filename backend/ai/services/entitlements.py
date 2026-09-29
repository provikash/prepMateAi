"""Single backend source of truth for AI feature access and balances."""

from ai.services.credits import CreditService
from billing.models import PremiumSubscription


class EntitlementService:
    FEATURE_COSTS = {"resume_optimizer": "resume_optimization"}

    @classmethod
    def get_user_entitlements(cls, user):
        account = CreditService.account(user)
        available = max(0, account.available)
        subscription = PremiumSubscription.objects.filter(user=user).first()
        premium = bool(subscription and subscription.is_active)
        return {
            "plan": {
                "code": "premium" if premium else "free",
                "name": "Premium" if premium else "Free",
                "is_active": True,
                "expires_at": subscription.expires_at if premium else None,
            },
            "ai_credits": {
                "limit": max(account.lifetime_earned, account.balance + account.lifetime_used),
                "used": account.lifetime_used,
                "reserved": account.reserved_credits,
                "available": available,
                "resets_at": None,
            },
            "features": {
                "resume_optimizer": available >= CreditService.cost("resume_optimization"),
                "premium_templates": premium,
                "pdf_export": True,
            },
        }

    @classmethod
    def can_use_feature(cls, user, feature_code):
        return bool(cls.get_user_entitlements(user)["features"].get(feature_code, False))

    @classmethod
    def get_available_ai_credits(cls, user):
        return cls.get_user_entitlements(user)["ai_credits"]["available"]

    reserve_ai_credit = staticmethod(CreditService.reserve)
    commit_credit = staticmethod(CreditService.commit)
    release_credit = staticmethod(CreditService.release)
