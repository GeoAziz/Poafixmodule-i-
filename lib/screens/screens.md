# PoaFix Screens Directory Structure

This document describes the structure and purpose of each screen and subfolder in `lib/screens/`.

---

## Root-Level Screens

| File                          | Purpose/Entry Point                                      |
|-------------------------------|---------------------------------------------------------|
| home_screen.dart              | Main client home screen                                 |
| login_screen.dart             | App login screen                                        |
| bookings_screen.dart          | Client bookings overview                                |
| service_provider_screen.dart  | Main provider dashboard                                 |
| settings_screen.dart          | App and user settings                                   |
| profile_screen.dart           | User profile (client/provider)                          |
| notification_screen.dart      | Single notification view                                |
| notifications_screen.dart     | Notifications list                                      |
| payment_methods_screen.dart   | Manage payment methods                                  |
| billing_history_screen.dart   | View billing/payment history                            |
| refer_a_friend_screen.dart    | Referral feature                                        |
| follow_us_screen.dart         | Social media links                                      |
| calendar_screen.dart          | Calendar for jobs/bookings                              |
| clients_screen.dart           | Client management (admin/client flows)                  |
| contact_support_screen.dart   | Support/help contact                                    |
| my_service_screen.dart        | Provider's services management                          |
| provider_profile_screen.dart  | Provider profile                                        |
| service_provider_list_screen.dart | List of service providers                         |
| terms_and_conditions_screen.dart | Legal/terms screen                                 |
| document_upload_screen.dart   | Document upload for providers                           |

---

## Subfolders

### auth/
- **auth_service.dart**: Authentication logic and helpers.
- **login_screen.dart**: Login UI.
- **sign_in_screen.dart**: Sign-in flow.
- **sign_up_screen.dart**: Sign-up/registration flow.

### booking/
- **booking_confirmation_screen.dart**: Booking confirmation UI.
- **booking_screen.dart**: Booking creation and management.

### bookings/
- **bookings_screen.dart**: Bookings list and management.

### client/
- **booking_screen.dart**: Client-specific booking UI.
- **edit_profile_screen.dart**: Edit client profile.
- **profile_screen.dart**: Client profile.
- **review_service_screen.dart**: Review a service.
- **service_history_screen.dart**: Client's service history.
- **service_provider_list_screen.dart**: List of providers for clients.

### finance/
- **financial_management_screen.dart**: Financial management for providers.

### home/
- **home_screen.dart**: Main home/dashboard for clients.

### location/
- **location_picker_screen.dart**: Location selection utility.

### notifications/
- **notification_screen.dart**: Single notification view.
- **notifications_screen.dart**: Notifications list.

### payment/
- **mpesa_payment_screen.dart**: M-Pesa payment integration.
- **service_payment_screen.dart**: Service payment UI.

### profile/
- **activity_history_screen.dart**: User activity history.
- **payment_billing_screen.dart**: Payment and billing info.
- **profile_screen.dart**: User profile.
- **ratings_reviews_screen.dart**: Ratings and reviews.
- **service_preferences_screen.dart**: Service preferences.
- **settings_screen.dart**: Profile/settings.

### provider/
- **availability_screen.dart**: Provider availability management.
- **certifications_screen.dart**: Provider certifications.

### quick_actions/
- **history_screen.dart**: Quick access to history.
- **saved_screen.dart**: Quick access to saved items.
- **schedule_screen.dart**: Quick access to schedule.

### rating/
- **rating_screen.dart**: Rate a provider/service.

### service/
- **service_tracking_screen.dart**: Track service progress.

### service_provider/
- **booking_screen.dart**: Provider booking management.
- **dashboard_screen.dart**: Provider dashboard.
- **earnings_screen.dart**: Provider earnings.
- **financial_management_screen.dart**: Provider financials.
- **job_details_screen.dart**: Details for a provider's job.
- **jobs_screen.dart**: Provider jobs list.
- **notifications_screen.dart**: Provider notifications.
- **service_areas_screen.dart**: Manage provider service areas.
- **service_provider_screen.dart**: Main provider dashboard.

### services/
- **client_service.dart**: Client service logic.
- **payment_service.dart**: Payment logic.
- **service_detail_screen.dart**: Service details.
- **service_list_screen.dart**: List of services.

---

## Deprecated Screens

All unused, legacy, duplicate, and empty screens have been moved to `.deprecated/screens/` and its subfolders for safe keeping and future reference.

---

## How to Add a New Screen

1. Place your new screen in the appropriate subfolder.
2. Update navigation/routes in `main.dart` or the relevant parent screen.
3. Document the new screen here for future developers.

---

## Notes

- Keep this documentation updated as you add, remove, or refactor screens.
- For any questions, refer to the code comments or contact the lead developer.
