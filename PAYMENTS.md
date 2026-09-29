# Razorpay payments

PrepMate uses Razorpay Standard Checkout for prepaid Premium access and one-time
AI credit packs. Prices and benefits are selected by the Django backend; the
mobile application never supplies a trusted amount or credit quantity.

## Products

Default test catalog:

- Premium Monthly: INR 99, 30 days, 500 AI credits.
- Premium Annual: INR 950, 365 days, 6,000 AI credits granted upfront.
- Credit packs: 100 for INR 49, 500 for INR 199, or 1,500 for INR 499.

All amounts and included credits can be changed using the variables in
`backend/.env.example`. Premium is prepaid and does not auto-renew.

## Razorpay dashboard setup

1. Start in Razorpay Test Mode and generate an API key pair.
2. Set `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` on the backend service.
   Never put the key secret in Flutter or source control.
3. Create a webhook pointing to:
   `https://YOUR_API_HOST/api/v1/billing/webhooks/razorpay/`
4. Generate a separate webhook secret and set it as
   `RAZORPAY_WEBHOOK_SECRET` on the backend.
5. Subscribe the webhook to `payment.captured` and `order.paid`.
6. Enable automatic capture in Razorpay. Benefits are granted only after the
   backend confirms that the payment status is `captured`.
7. Make successful, failed, retried, and duplicate Test Mode payments before
   replacing the API keys with Live Mode keys.

## Payment flow

1. Flutter requests an order using a product code.
2. Django chooses the price and creates the Razorpay order.
3. Flutter opens Razorpay Checkout using the public key and order ID.
4. Flutter sends the returned payment ID, order ID, and signature to Django.
5. Django verifies the HMAC signature, fetches the payment from Razorpay, and
   checks the captured status, amount, currency, and order ID.
6. Django grants credits and/or extends Premium access in one database
   transaction. Repeated callbacks and webhook deliveries do not grant twice.

The webhook is the recovery path if the app closes after payment but before its
verification request reaches Django.

## Store-distribution requirement

Premium access and AI credits are digital goods. A Google Play build can use an
alternative billing system for eligible Indian users only after enrolling in
Google's applicable alternative-billing program and implementing its required
choice screen, APIs, and transaction reporting. Apple generally requires
StoreKit In-App Purchase for digital features unless the app and storefront
qualify for a specific external-purchase entitlement. Do not submit the current
Razorpay checkout unchanged to an app store without completing those program
requirements. It is suitable for direct Android distribution and controlled
Test Mode testing.

- [Google Play Payments policy](https://support.google.com/googleplay/android-developer/answer/9858738)
- [Google Play alternative billing in India](https://support.google.com/googleplay/android-developer/answer/13306652)
- [Apple App Review Guidelines, section 3.1](https://developer.apple.com/app-store/review/guidelines/)
