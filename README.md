# FoodShare Kenya

**Project by Muusi Nguutu Nzyoka**

[Live site](https://foodshare.nzyoka.com/)

A Flutter mobile application that connects restaurants with surplus food to shelters and community organisations in Kenya, reducing food waste while fighting hunger.

---

## Project overview

| | |
|---|---|
| Status | Active development |
| Type | Individual social impact project |
| Platform | Flutter (Android primary, web supported) |
| Target region | Kenya (Nairobi, Mombasa, Nakuru, Eldoret, Kisumu) |

---

## Tech stack

### Frontend
- Flutter / Dart
- State management: `flutter_riverpod ^3.3.2`
- Real-time chat: `web_socket_channel ^2.4.0`
- Push notifications: `firebase_messaging ^15.1.4` + `flutter_local_notifications ^17.0.0`
- Image handling: `image_picker`, `cached_network_image`
- Secure token storage: `flutter_secure_storage`
- Maps and location: `google_maps_flutter`, `geolocator`, `geocoding`

### Backend
- FastAPI (Python), hosted on Railway
- PostgreSQL (asyncpg connection pool, Railway managed)
- JWT authentication (access + refresh tokens)
- Google Sign-In via ID token verification
- Cloudinary for food photo storage
- Firebase Admin SDK for FCM push notifications

### Infrastructure
- Backend: Railway (auto-deploy from GitHub)
- Web frontend: Netlify (auto-deploy from GitHub)
- Database: Railway PostgreSQL
- Media: Cloudinary
- Push: Firebase Cloud Messaging

---

## User roles

### Restaurants (food donors)
- Post surplus food donations with photos, quantities, pickup times, and category
- Manage listings (edit, pause, cancel)
- Review and accept or decline shelter requests
- Chat with shelters to coordinate pickup
- Track donation history

### Shelters (food recipients)
- Browse available donations filtered by city, category, and keyword
- Send request messages to restaurants
- Track request status across pending / approved / declined tabs
- Chat with restaurants for approved donations
- View request history

---

## Implemented features

### Authentication
- Google Sign-In with JWT (access + refresh token pair)
- Role selection at registration (restaurant or shelter)
- Profile completion gate before accessing main features
- FCM device token registered on login for push notifications

### Donations
- Create listings with photos (Cloudinary upload), description, quantity, category, pickup window, and city
- Edit and manage listing status (available, reserved, completed, cancelled)
- Location-based browse with city and category filters, keyword search

### Requests
- Shelters send a personalised request message per donation
- Restaurants approve or decline; approval updates donation status to reserved
- Duplicate request prevention per shelter per donation
- Push notification to restaurant on new request; to shelter on status change

### Chat
- Per-donation chat thread between restaurant and shelter
- Real-time message delivery via WebSocket (WSS)
- Message history loaded on open, deduplicated against live stream
- Notification dismissal: opening a chat cancels any pending chat notifications in the notification centre
- Push notification to recipient when a new message arrives, showing the business or organisation name (not Google account name)

### Push notifications
- All notification types (new request, request approved/declined, delivery complete, new donation, new chat message) show as heads-up banners on Android
- Foreground banners rendered by `flutter_local_notifications` using the `foodshare_default` high-importance channel
- Background and terminated state banners delivered by FCM directly to the same channel
- Explicit `POST_NOTIFICATIONS` permission requested on Android 13+
- Per-user notification preference toggles respected server-side

### Themes and UI
- Light and dark mode with system default fallback, persisted across sessions
- Status bar icon brightness adapts to current theme (fixes invisible icons on Samsung in light mode)
- Kenyan city integration throughout

---

## Architecture notes

### Real-time chat (WebSocket)
The backend exposes a `wss://<host>/chats/<chat_id>/ws?token=<jwt>` endpoint on a separate router without HTTP auth middleware, since WebSocket upgrade requests cannot carry an Authorization header. The Flutter client connects on chat open and keeps the channel alive until the screen is disposed. Incoming messages are deduplicated by ID to prevent doubling when the sender receives their own broadcast.

### Push notification channel consistency
The backend always sets `channel_id = "foodshare_default"` in the FCM `AndroidConfig` for every message type. The Flutter app creates this channel with `Importance.max` at startup before any notification fires. Both sides must agree on the same ID for Android to route messages to the high-importance channel and show heads-up banners.

### CORS and error handling
All FastAPI error responses (422, HTTPException, 500) explicitly include `Access-Control-Allow-Origin` headers. Without this, Starlette's `ServerErrorMiddleware` bypasses `CORSMiddleware` on unhandled exceptions, causing the browser to report a CORS error instead of the real HTTP error.

### Image storage
Food photos are uploaded directly to Cloudinary via the `/upload/image` endpoint and stored as URLs in PostgreSQL. Firebase Storage is not used.

---

## Database schema (PostgreSQL)

| Table | Purpose |
|---|---|
| `users` | Shared user record (id, email, user_type, fcm_token, notification_prefs) |
| `restaurants` | Restaurant profile (business_name, city, address, etc.) |
| `shelters` | Shelter profile (organization_name, city, capacity, etc.) |
| `donations` | Food listings |
| `requests` | Shelter requests for a donation |
| `chats` | Chat thread linking a donation, restaurant, and shelter |
| `messages` | Individual chat messages |

---

## Environment variables

### Backend (Railway)
| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string |
| `JWT_SECRET` | Secret for signing JWT tokens |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name |
| `CLOUDINARY_API_KEY` | Cloudinary API key |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret |
| `FIREBASE_CREDENTIALS_JSON` | Firebase Admin SDK service account JSON (single line) |
| `ENVIRONMENT` | `production` or `development` |

### Frontend (Netlify / build)
| Variable | Description |
|---|---|
| `ENVIRONMENT` | Passed via `--dart-define=ENVIRONMENT=production` |

---

## Building

### Development
```bash
flutter run --dart-define=ENVIRONMENT=development
```

### Release APK
```bash
flutter build apk --release --dart-define=ENVIRONMENT=production
```

Core library desugaring is enabled (`isCoreLibraryDesugaringEnabled = true`) in `android/app/build.gradle.kts` to satisfy the `flutter_local_notifications` requirement.

---

## Screens

| Screen | Role |
|---|---|
| Restaurant dashboard | Overview, quick stats, navigation hub |
| Add / edit donation | Create or update a food listing |
| My donations | Manage active and past donations |
| Donation requests | Review and act on shelter requests |
| Shelter dashboard | Overview and navigation hub |
| Browse donations | Discover available food with filters |
| My requests | Track request status |
| Reserved donations | Donations approved for this shelter |
| Chat screen | Real-time messaging per donation thread |
| Chats list | All active conversations |
| Profile / edit profile | View and update profile details |
| Settings | Theme toggle, notification preferences |

---

## Cities supported

Nairobi, Mombasa, Nakuru, Eldoret, Kisumu

---

## Contact

Developer: Muusi Nguutu Nzyoka  
Email: khrismnjamez@gmail.com  
Project type: Individual social impact initiative
