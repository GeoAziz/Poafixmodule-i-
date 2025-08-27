# API Endpoints Documentation

This document lists the main API endpoints for both client and service provider flows in the Poafix backend. Use these for frontend integration and for testing with curl in development and production.

---

## 1. Client Endpoints

- `POST   /api/clients/login` — Client login
- `GET    /api/clients/` — List all clients
- `GET    /api/clients/:id` — Get client by ID
- `POST   /api/clients/` — Create new client
- `PATCH  /api/clients/:id` — Update client by ID
- `GET    /api/clients/:id/bookings` — Get bookings for client
- `POST   /api/clients/:id/location` — Update client location
- `POST   /api/clients/update-last-active` — Update last active timestamp
- `GET    /api/clients/profile/:clientId` — Get client profile
- `GET    /api/clients/nearby-providers` — Find nearby providers

---


## 2. Service Provider Endpoints

- `POST   /api/auth/signup/provider` — Register new service provider
  - Required payload:
    ```json
    {
      "name": "...",
      "email": "...",
      "password": "...",
      "phoneNumber": "...",
      "businessName": "...",
      "businessAddress": "...",
      "serviceOffered": [{
        "name": "...",
        "description": "...",
        "price": "...",
        "duration": "..."
      }],
      "serviceType": "...",
      "location": { "type": "Point", "coordinates": [lng, lat] }
    }
    ```
- `POST   /api/auth/login` — Login (provider or client)
- `GET    /api/providers/:providerId/upcoming-appointments` — Upcoming appointments
- `GET    /api/providers/:providerId/recent-activities` — Recent activities
- `GET    /api/providers/nearby` — Find nearby providers
- `GET    /api/providers/availability` — Provider availability
- `PUT    /api/providers/location` — Update provider location

---

## 3. Common & Auth Endpoints

- `POST   /api/auth/login` — Login (generic)
- `GET    /api/health` — Health check
- `GET    /api/debug` — Debug info

---

## 4. Admin Endpoints (for reference)

- `POST   /api/admin/login` — Admin login
- `GET    /api/admin/dashboard` — Dashboard data
- `GET    /api/admin/analytics` — Analytics
- `GET    /api/admin/clients` — List clients
- `POST   /api/admin/reports` — Submit report

---

## 5. Booking & History Endpoints

- `GET    /api/recurring-bookings/` — List recurring bookings
- `POST   /api/recurring-bookings/` — Create recurring booking
- `PATCH  /api/recurring-bookings/:recurringBookingId` — Update recurring booking
- `PATCH  /api/recurring-bookings/:recurringBookingId/cancel` — Cancel recurring booking
- `PATCH  /api/recurring-bookings/:recurringBookingId/pause` — Pause recurring booking
- `GET    /api/service-history/` — List service history
- `POST   /api/service-history/` — Create service history
- `GET    /api/service-history/:historyId` — Get service history by ID

---

## 6. Payment Endpoints

- `POST   /api/payments/mpesa/initiate` — Initiate MPesa payment
- `POST   /api/payments/paypal/initiate` — Initiate PayPal payment
- `GET    /api/payments/status/:paymentId` — Get payment status

---

## 7. Usage

- All endpoints are relative to your base URL (see `.env.production` and `.env.development`).
- Example (production):
  `https://09ecb564d140.ngrok-free.app/api/clients/login`
- Example (development):
  `http://localhost:5000/api/clients/login`

---

**Maintainer:** GeoAziz
**Last updated:** August 27, 2025
