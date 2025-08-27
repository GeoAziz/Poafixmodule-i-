# PoaFix (mess)

A modern Flutter project for the PoaFix platform.

## Project Overview

PoaFix is a service platform connecting clients and service providers. This repository contains the main Flutter app codebase, organized for maintainability and scalability.

---

## Directory Structure

- `lib/` — Main application source code (see `lib.md` for details)
- `test/` — Unit and widget tests
- `android/`, `ios/`, `linux/`, `macos/`, `windows/` — Platform-specific code
- `.deprecated/` — Archived legacy/unused code for reference

---

## Developer Docs

- [`lib.md`](lib/lib.md) — Explains the structure and purpose of each folder in `lib/`
- [`screens.md`](lib/screens/screens.md) — Documents all screens and their roles

---

## Getting Started

1. Install Flutter: [Flutter Install Guide](https://docs.flutter.dev/get-started/install)
2. Run `flutter pub get` to fetch dependencies.
3. Use `flutter run` to start the app.

---

## Contributing

- Keep code and documentation organized.
- Move unused/legacy code to `.deprecated/`.
- Update `lib.md` and `screens.md` as you add or refactor features.

---

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [PoaFix Internal Wiki](#) (add link if available)

---

## Environment Switching (Dev/Prod)

This project uses `.env.development` and `.env.production` files to manage backend URLs and secrets for development and production.

### How It Works
- The app loads the correct `.env` file at startup using [flutter_dotenv](https://pub.dev/packages/flutter_dotenv).
- The file is selected automatically based on build mode:
  - **Debug/Development:** Loads `.env.development` (when running `flutter run`)
  - **Release/Production:** Loads `.env.production` (when building with `flutter build apk --release`)
- The selected file sets `API_BASE_URL`, which is used for all backend API calls.

### How to Use
1. **Set your backend URLs in both env files:**
   - `.env.development` for local/ngrok/dev
   - `.env.production` for live/production
2. **Run in development:**
   ```bash
   flutter run
   ```
   - Connects to dev backend
3. **Build for production:**
   ```bash
   flutter build apk --release
   ```
   - Connects to prod backend

### Example .env Files
```
# .env.development
API_BASE_URL=http://localhost:5000
```
```
# .env.production
API_BASE_URL=https://your-production-url.com
```

### Notes
- No manual code changes needed to switch environments.
- All API calls use the loaded `API_BASE_URL`.
- You can add more secrets/configs to these files as needed.

---

For any issues, check your env files and make sure your backend is running and accessible from your device.

---

For questions, contact the lead developer or check the code comments.
