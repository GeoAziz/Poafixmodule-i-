# Environment Configuration Guide

This document explains how environment variables are managed for both the backend and frontend of the Poafix system, and how to use them for development and production.

---

## 1. Backend Environment Files

**Location:** `/home/devmahnx/poafix/`

- `.env.development` — Used for backend development
- `.env.production` — Used for backend production

**Sample Variables:**
```
MONGODB_URI=mongodb://localhost:27017/home_service_db
PORT=5000
JWT_SECRET=your_production_secret_key
PAYPAL_CLIENT_ID=...
PAYPAL_CLIENT_SECRET=...
PAYPAL_MODE=live/sandbox
FRONTEND_URL=https://your-frontend-url.com
PAYPAL_CALLBACK_URL=...
MPESA_CALLBACK_URL=...
```

**Usage:**
- Loaded by Node.js using `dotenv`.
- Contains secrets, DB URIs, payment keys, callback URLs, etc.
- Never expose backend `.env` files to the frontend.

---

## 2. Frontend Environment Files

**Location:** `/home/devmahnx/Poafixmodule-i-/`

- `.env.development` — Used for frontend development
- `.env.production` — Used for frontend production

**Sample Variables:**
```
API_BASE_URL=http://localhost:5000 (dev)
API_BASE_URL=https://your-production-backend.com (prod)
GOOGLE_MAPS_API_KEY=...
FRONTEND_ENV=development/production
```

**Usage:**
- Loaded by Flutter using `flutter_dotenv`.
- Contains only public config (API URLs, public keys, feature flags).
- Never include backend secrets, DB URIs, or private keys.

---

## 3. How Environment Selection Works

- **Backend:**
  - Run with: `ENV_FILE=.env.production npm start` (or similar)
  - Node.js loads the correct `.env` file for the environment.

- **Frontend:**
  - Flutter loads `.env.production` or `.env.development` based on build mode.
  - All API requests use `API_BASE_URL` from the frontend `.env` file.

---

## 4. Best Practices

- Keep backend and frontend `.env` files separate.
- Backend `.env` files: secrets, DB, payment keys, callback URLs.
- Frontend `.env` files: only public config (API URLs, public keys).
- Never copy backend secrets to frontend.
- Document any required variables for new developers.

---

## 5. Example Directory Structure

```
poafix/                # Backend
  .env.development
  .env.production
Poafixmodule-i-/       # Frontend
  .env.development
  .env.production
  config.md            # This documentation
```

---

## 6. Quick Reference Table

| File Location                | Purpose         | Contains Secrets? | Example Key           |
|------------------------------|-----------------|-------------------|----------------------|
| poafix/.env.development      | Backend Dev     | Yes               | MONGODB_URI          |
| poafix/.env.production       | Backend Prod    | Yes               | PAYPAL_CLIENT_ID     |
| Poafixmodule-i-/.env.development | Frontend Dev | No                | API_BASE_URL         |
| Poafixmodule-i-/.env.production  | Frontend Prod| No                | GOOGLE_MAPS_API_KEY  |

---

## 7. Troubleshooting

- If the frontend cannot connect to the backend, check `API_BASE_URL` in the frontend `.env` file.
- If backend fails to start, check for missing or incorrect variables in backend `.env` files.
- Never expose backend `.env` files to the public or to the frontend repo.

---

## 8. Onboarding Checklist

- Ensure both backend and frontend have their own `.env.development` and `.env.production` files.
- Backend: Fill in all secrets, DB URIs, payment keys.
- Frontend: Fill in only public config (API URLs, public keys).
- Test both environments before deploying.

---

**Maintainer:** GeoAziz
**Last updated:** August 27, 2025
