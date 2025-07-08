# PoaFix Flutter App — `lib/` Directory Structure

This document describes the purpose of each folder in the `lib/` directory.

---

## Folders

| Folder      | Purpose                                                                 |
|-------------|-------------------------------------------------------------------------|
| screens/    | All UI screens and navigation flows.                                     |
| models/     | Data models (e.g., User, Booking, Provider).                            |
| services/   | Business logic, API calls, storage, and integrations.                   |
| widgets/    | Reusable UI components.                                                 |
| providers/  | State management (Provider, Riverpod, etc.).                            |
| utils/      | Utility functions and helpers.                                          |
| constants/  | App-wide constants (e.g., service types, asset paths).                  |
| core/       | Core app logic, interceptors, shared models/services.                   |
| config/     | Configuration files (API endpoints, DB config, etc.).                   |
| middleware/ | Middleware logic (e.g., authentication checks).                         |
| .deprecated/| Archived legacy/unused code for reference.                              |

---

## Notes

- **Only keep folders that are actively used and referenced.**
- **Move legacy or unused folders/files to `.deprecated/` for safe keeping.**
- **Update this documentation as you add, remove, or refactor folders.**

---

## How to Add a New Folder

1. Create the folder in `lib/`.
2. Add a short description here.
3. Ensure it fits the app’s architecture and is referenced where needed.

---

## Contact

For questions, contact the lead developer or check the code comments.