# Authentication & User Management Documentation

This document provides a complete technical overview of authentication and user management in the Poafix system, covering frontend-to-backend flows, provider files, endpoints, payloads, and integration details.

---

## 1. Overview

- **Authentication is handled via JWT tokens.**
- **Users:** Clients, Service Providers, Admins.
- **Frontend:** Flutter (uses API endpoints for login, registration, etc.)
- **Backend:** Node.js/Express, MongoDB.

---

## 2. Endpoints Summary

### Service Provider
- `POST   /api/auth/signup/provider` — Register new provider
- `POST   /api/auth/login` — Login (provider or client)
- `GET    /api/providers/:providerId/upcoming-appointments` — Upcoming appointments
- `GET    /api/providers/:providerId/recent-activities` — Recent activities
- `GET    /api/providers/nearby` — Find nearby providers
- `GET    /api/providers/availability` — Provider availability
- `PUT    /api/providers/location` — Update provider location

### Client
- `POST   /api/clients/` — Register new client
- `POST   /api/auth/login` — Login (provider or client)
- `GET    /api/clients/:id/bookings` — Get bookings for client
- `POST   /api/clients/:id/location` — Update client location

### Common
- `GET    /api/health` — Health check
- `GET    /api/debug` — Debug info

---

## 3. Registration Flow (Provider)

### Frontend (Flutter)
- Collects all required fields:
  - name, email, password, phoneNumber, businessName, businessAddress
  - serviceOffered (array of objects: name, description, price, duration)
  - serviceType (string)
  - location (object: type 'Point', coordinates [lng, lat])
- Sends POST request to `/api/auth/signup/provider` with JSON payload.
- Receives JWT token and provider profile on success.

### Backend (Node.js)
- Validates payload against `ServiceProvider` schema.
- Hashes password, saves provider to MongoDB.
- Returns JWT token and provider profile.

---

## 4. Login Flow

### Frontend
- Sends POST request to `/api/auth/login` with email and password.
- Receives JWT token and user profile (provider or client).
- Stores token for authenticated requests.

### Backend
- Checks credentials against both Client and ServiceProvider models.
- Returns JWT token and user profile if valid.

---

## 5. JWT Token Usage

- Token is returned on successful registration/login.
- Token must be sent in `Authorization: Bearer <token>` header for protected endpoints.
- Token contains userId and userType.

---

## 6. Provider Model (Backend)

- See `models/ServiceProvider.js` for full schema.
- Key fields:
  - name, email, password, phoneNumber, businessName, businessAddress
  - serviceOffered (array of objects)
  - serviceType (string)
  - location (GeoJSON Point)
  - status, rating, experience, etc.

---

## 7. Frontend Integration

- Use `flutter_dotenv` to load API base URL from `.env.production` or `.env.development`.
- All API requests use the base URL and documented endpoints.
- Store JWT token securely (e.g., secure storage).
- Attach token to requests for protected endpoints.

---

## 8. Example Curl Commands

### Register Provider
```bash
curl -X POST https://your-backend-url/api/auth/signup/provider \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Provider",
    "email": "provider.test@example.com",
    "password": "TestPassword123",
    "phoneNumber": "+254700000000",
    "businessName": "Test Mechanic Garage",
    "businessAddress": "Nairobi CBD",
    "serviceOffered": [{
      "name": "mechanic",
      "description": "General mechanic services",
      "price": "5000",
      "duration": "2h"
    }],
    "serviceType": "mechanic",
    "location": { "type": "Point", "coordinates": [36.8219, -1.2921] }
  }'
```

### Login Provider
```bash
curl -X POST https://your-backend-url/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "provider.test@example.com",
    "password": "TestPassword123"
  }'
```

---

## 9. Error Handling

- Backend returns clear error messages for validation and authentication failures.
- Debug logs available in backend for troubleshooting.

---

## 10. Security Notes

- Never expose JWT secrets or private keys in frontend.
- Always use HTTPS in production.
- Store tokens securely on client devices.

---

**Maintainer:** GeoAziz
**Last updated:** August 27, 2025
