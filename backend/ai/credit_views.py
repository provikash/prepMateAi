from django.conf import settings
from rest_framework import permissions
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import AICreditTransaction
from .services.credits import CreditService


class AICreditsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        account = CreditService.account(request.user)
        return Response({
            "balance": account.balance,
            "reserved_credits": account.reserved_credits,
            "available_credits": account.available,
            "lifetime_earned": account.lifetime_earned,
            "lifetime_used": account.lifetime_used,
            "operation_costs": settings.AI_OPERATION_COSTS,
        })


class AICreditTransactionsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        transactions = AICreditTransaction.objects.filter(user=request.user).order_by("-created_at")[:100]
        return Response([{
            "id": str(item.pk), "type": item.transaction_type,
            "amount": item.amount, "balance_before": item.balance_before,
            "balance_after": item.balance_after, "operation": item.operation,
            "created_at": item.created_at,
        } for item in transactions])


class AIOperationsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response([{"operation": operation, "credit_cost": cost,
                          "display_name": operation.replace("_", " ").title()}
                         for operation, cost in settings.AI_OPERATION_COSTS.items()])
