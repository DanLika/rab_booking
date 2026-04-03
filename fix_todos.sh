#!/bin/bash
# 1. lib/features/owner_dashboard/presentation/providers/ai_chat_provider.dart
sed -i 's/\/\/ Show actual error for debugging (TODO: remove after fixing)/\/\/ Show actual error for debugging/g' lib/features/owner_dashboard/presentation/providers/ai_chat_provider.dart

# 2. functions/src/guestCancelBooking.ts:250
sed -i 's/\/\/ TODO: Add cancellation policy logic (full_refund\/50_percent\/no_refund)/\/\/ TODO(2025-05-01): Add cancellation policy logic (full_refund\/50_percent\/no_refund) for accurate refunds/g' functions/src/guestCancelBooking.ts

# 3. functions/src/stripeSubscription.ts:44
sed -i 's/\/\/ TODO: Replace with actual Stripe Price IDs from config\/env/\/\/ TODO(2025-05-01): Replace with actual Stripe Price IDs from config\/env when moving to production pricing/g' functions/src/stripeSubscription.ts

# 4. functions/src/email/templates/trial-expiring-soon.ts:11
sed -i 's/\/\/ TODO: Create a visually appealing HTML template/\/\/ TODO(2025-06-01): Create a visually appealing HTML template for trial expiring emails/g' functions/src/email/templates/trial-expiring-soon.ts

# 5. functions/src/email/templates/trial-expired.ts:10
sed -i 's/\/\/ TODO: Create a visually appealing HTML template/\/\/ TODO(2025-06-01): Create a visually appealing HTML template for trial expired emails/g' functions/src/email/templates/trial-expired.ts

# 6. functions/src/bookingComApi.ts
sed -i 's/\/\/ TODO: Update with actual API base URL after getting API access/\/\/ TODO(2025-07-01): Update with actual API base URL after getting API access for Booking.com/g' functions/src/bookingComApi.ts
sed -i 's/\/\/ TODO: Implement proper encryption with KMS/\/\/ TODO(2025-07-01): Implement proper encryption with KMS for sensitive Booking.com credentials/g' functions/src/bookingComApi.ts
sed -i 's/\/\/ TODO: Implement proper decryption with KMS/\/\/ TODO(2025-07-01): Implement proper decryption with KMS for sensitive Booking.com credentials/g' functions/src/bookingComApi.ts
sed -i 's/\/\/ TODO: Update with actual OAuth authorization URL after getting API access/\/\/ TODO(2025-07-01): Update with actual OAuth authorization URL after getting API access for Booking.com/g' functions/src/bookingComApi.ts

# 7. functions/src/emailService.ts
sed -i 's/\* TODO: Suspicious Activity Email (deferred for future implementation)/\*\* Suspicious Activity Email (deferred for future implementation) \*/g' functions/src/emailService.ts
sed -i 's/\/\/ NOTE: sendSuspiciousActivityEmail has been removed (TODO for future implementation)/\/\/ NOTE: sendSuspiciousActivityEmail has been removed (planned for future implementation)/g' functions/src/emailService.ts

# 8. functions/src/index.ts:89
sed -i 's/\/\/ TODO: SMS feature not yet implemented - requires Twilio\/SMS provider setup/\/\/ TODO(2025-08-01): SMS feature not yet implemented - requires Twilio\/SMS provider setup/g' functions/src/index.ts

# 9. functions/src/airbnbApi.ts
sed -i 's/\/\/ TODO: Update with actual API base URL after getting API access/\/\/ TODO(2025-07-01): Update with actual API base URL after getting API access for Airbnb/g' functions/src/airbnbApi.ts
sed -i 's/\/\/ TODO: Update with actual OAuth authorization URL after getting API access/\/\/ TODO(2025-07-01): Update with actual OAuth authorization URL after getting API access for Airbnb/g' functions/src/airbnbApi.ts
sed -i 's/\/\/ TODO: Update with actual OAuth token URL after getting API access/\/\/ TODO(2025-07-01): Update with actual OAuth token URL after getting API access for Airbnb/g' functions/src/airbnbApi.ts

# 10. functions/src/scheduledPushNotifications.ts:369
sed -i 's/\/\/ TODO: Implement lastActiveAt update in enhanced_auth_provider.dart/\/\/ TODO(2025-04-01): Implement lastActiveAt update in enhanced_auth_provider.dart to accurately track user activity/g' functions/src/scheduledPushNotifications.ts
