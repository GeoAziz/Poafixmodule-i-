# PoaFix Authentication Documentation

This guide covers the authentication flow, configuration, and all related files in the PoaFix Flutter frontend.

---

## 1. Login Screen
- **File:** `lib/screens/auth/login_screen.dart`
- Presents login UI for clients, providers, and admins.
- Collects credentials and calls authentication logic.

## 2. Authentication Service
- **File:** `lib/services/auth_service.dart`
- Handles login, signup, logout, and API calls.
- Parses responses and manages errors.

## 3. Auth Storage
- **File:** `lib/services/auth_storage.dart`
- Securely stores JWT tokens and user info.
- Ensures tokens are available for authenticated requests.

## 4. API Configuration
- **File:** `lib/services/api_config.dart`
- Manages backend base URL and endpoint construction.
- Uses network discovery to select the correct backend IP.

## 5. Network Service
- **File:** `lib/services/network_service.dart`
- Discovers which backend URL is reachable from your device.
- Contains a list of potential backend IPs (`_potentialUrls`).
- Tests each URL for connectivity and authentication endpoint availability.

## 6. Main App Entry & Routing
- **File:** `lib/main.dart`
- Uses authentication wrapper to check login state on app start.
- Routes users to login or home screens based on authentication status.

---

## ⚠️ Network IP Configuration Alert

When switching networks (e.g., from home to work):
- Your backend server’s IP address may change (e.g., `192.168.0.203` at home, `192.168.0.101` at work).
- **Update the IP address in both** `lib/services/api_config.dart` **and** `lib/services/network_service.dart` **to match your backend’s current IP.**
- Example:
  ```dart
  static const List<String> _potentialUrls = [
    'http://192.168.0.203:5000', // Home network
    'http://192.168.0.101:5000', // Work network
    // ...other fallback IPs
  ];
  ```
- After updating, **restart your app** to apply the changes.

---

## Summary Table
| File                                      | Role/Responsibility                                 |
|--------------------------------------------|-----------------------------------------------------|
| `lib/screens/auth/login_screen.dart`       | Login UI, input, error display                      |
| `lib/services/auth_service.dart`           | Auth API calls, logic, error handling               |
| `lib/services/auth_storage.dart`           | Secure token storage                                |
| `lib/services/api_config.dart`             | API base URL management, endpoint helpers           |
| `lib/services/network_service.dart`        | Backend URL discovery, connectivity checks          |
| `lib/main.dart`                            | App entry, authentication wrapper, routing          |

---

## Best Practices
- Always update backend IPs in config files when changing networks.
- Use secure passwords and change test credentials before production.
- Ensure backend is reachable from your device (same WiFi network).
- Test login on both emulator and physical device after any network change.

---

This documentation will help you maintain, debug, and configure authentication in your PoaFix app for any environment.
