# Complete Booking Flow Documentation

This document describes the end-to-end booking flow in the PoaFix Flutter app, highlighting the exact frontend files involved and their roles.

---

## 1. Home Screen
- **File:** `lib/screens/home/home_screen.dart`
- **Role:** Main dashboard for the client. User starts here. The bottom navigation bar allows navigation to service selection (search icon).

## 2. Service Selection
- **File:** `lib/screens/services/service_selection_screen.dart`
- **Role:** Displays service categories. User selects a category and clicks “Book Now” to proceed to booking details.

## 3. Booking Details & Creation
- **File:** `lib/screens/booking/booking_details_screen.dart`
- **Role:** Multi-step booking form (provider, date/time, location, confirmation). Handles user input and booking data. Calls booking creation logic.

## 4. Booking API & State
- **File:** `lib/services/booking_service.dart`
- **Role:** Handles API requests for booking creation and status updates.
- **File:** `lib/providers/booking_provider.dart`
- **Role:** Manages booking state and updates.

## 5. Booking Confirmation
- **File:** `lib/screens/booking/booking_confirmation_screen.dart`
- **Role:** Shows confirmation after successful booking.

## 6. Bookings List
- **File:** `lib/screens/bookings/bookings_screen.dart`
- **Role:** Displays all bookings for the user.

## 7. Navigation & Routing
- **File:** `lib/main.dart`
- **Role:** Sets up navigation and routes between all screens above.

---

### Notes
- Files moved to `.deprecated` (not used in the main flow):
  - `lib/screens/enhanced_booking_screen.dart`
  - `lib/screens/services/enhanced_service_selection_screen.dart`
- Only the files listed above are required for the booking flow. Unused or legacy files can be safely archived for future reference.

---

This documentation ensures clarity for future development and codebase maintenance.
