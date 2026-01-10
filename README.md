# AMA Order System (Flutter App + Node.js API)

AMA Order System is a role-based order management app built in Flutter with a Node.js/Express API and a PostgreSQL database.

## App Overview (Flutter)

The Flutter app is the primary client for Makers, Takers, Accounters, and Admins. It handles authentication, role dashboards, order creation and tracking, item-level updates, and printable order PDFs.

### What the app does
- Role-based login and signup with admin approval for non-admin accounts.
- Maker workflow: create orders, assign takers and accounter, manage active and archived orders, bulk send archived orders, print PDFs.
- Taker workflow: view assigned active orders, mark items as collected/unavailable, move status from pending to in-progress to completed.
- Accounter workflow: view completed orders, mark orders as entered_erp, print PDFs.
- Admin workflow: overview stats, approve users, manage users and orders, view activity logs.
- Search and filter orders by status; status labels are consistent across dashboards.
- Order logs and activity logs displayed in maker/admin views.
- Dark mode toggle stored per user.
- PDF printing with Arabic-capable fonts (Noto Sans Arabic + Noto Naskh Arabic).

### Order lifecycle
- Order statuses: `pending`, `in-progress`, `completed`, `archived`, `entered_erp`.
- Item statuses: `collected`, `unavailable`, or unset.
- "Active" in the UI is a combined view of `pending` + `in-progress`.

### UX notes
- Order form shortcuts: `Ctrl+Enter` creates an active order, `F3` creates an archived order.
- Item name suggestions merge local cache with `/api/items/suggestions`.
- Taker view hides item prices.
- Web printing opens a PDF in a new tab; mobile/desktop uses the printing plugin.

### Data and state
- Provider + ChangeNotifier for auth, orders, admin data, and notifications.
- JWT is stored in `SharedPreferences` and restored on app launch.
- Theme preference is stored per user on the server.

### Flutter project structure
- `lib/main.dart` bootstraps providers and routes.
- `lib/src/` contains config, models, screens, services, state, utils, widgets.
- `assets/` stores fonts and the app logo used for the launcher icon.

## Flutter Configuration

- API base URL: `--dart-define=API_BASE_URL=http://<host>:<port>`
  - Default is `http://213.6.226.163:6001` from `lib/src/config/api_config.dart`.
- Allow self-signed certs (non-web only): `--dart-define=ALLOW_BAD_CERTS=true`.
- On web, if `API_BASE_URL` is blank or localhost, the client uses the current origin.

## Server Overview (Node.js/Express)

The backend is an Express API with Sequelize models backed by PostgreSQL. It supports JWT auth, role-based authorization, email notifications, push notifications, and activity logging.

### Server features
- JWT auth (365-day tokens) and bcrypt password hashing.
- Admin approval flow for new non-admin users.
- Role-aware order queries and status transitions.
- Email notifications (nodemailer with SMTP).
- Web push notifications (web-push + VAPID keys).
- Activity logs for audit and admin dashboards.
- Item and order title suggestion endpoints.

### Data model summary
- User: roles (`maker`, `taker`, `accounter`, `admin`), approval state, email, theme preference.
- Order: status, city, maker, accounter, assigned takers, assigned accounter.
- OrderItem: quantity, price, item status.
- OrderLog: description/status history.
- ActivityLog: audit trail for admin.
- Notification + PushSubscription: in-app and push delivery.

### Server defaults
- Binds to `0.0.0.0`, default port `6001` (override with `PORT`).
- CORS enabled for all origins.
- Certificate auth middleware exists but is disabled in `AMA-Order-System/server/index.js` (HTTP only by default).

## Prerequisites

- Flutter SDK (Dart >= 3.10.1).
- Node.js + npm.
- PostgreSQL database.

## Install

### Flutter app
```bash
flutter pub get
```

### Server
```bash
cd AMA-Order-System/server
npm install
```

### Optional web frontend (React/Vite)
```bash
cd AMA-Order-System/ama-order-system-front
npm install
```

## Configuration

### Server `.env`
Create `AMA-Order-System/server/.env`:
```env
PORT=6001
JWT_SECRET=change-me
DB_NAME=ama_order_system
DB_USER=postgres
DB_PASSWORD=your_password
DB_HOST=localhost
DB_PORT=5432
EMAIL_USER=your_email@gmail.com
EMAIL_PASSWORD=your_app_password
```

Notes:
- Server auto-syncs schema on startup and seeds a default admin if none exists.
- Replace VAPID keys in `AMA-Order-System/server/utils/push.js` for production.

### Flutter app
```bash
flutter run --dart-define=API_BASE_URL=http://<server-ip>:6001
```

Self-signed HTTPS (mobile/desktop only):
```bash
flutter run --dart-define=API_BASE_URL=https://<server-ip>:6001 --dart-define=ALLOW_BAD_CERTS=true
```

## Run

### 1) Start PostgreSQL
Ensure the database exists and matches your `.env` credentials.

### 2) Start the server
```bash
cd AMA-Order-System/server
npm start
```

Other modes:
```bash
npm run dev     # nodemon
npm run test    # runs on port 3004
```

### 3) Run the Flutter app
```bash
flutter run
```

Web:
```bash
flutter run -d chrome
```

If testing on a device, set `API_BASE_URL` to your LAN IP and allow inbound access on the server port.

## Default admin account

On first server start, a default admin is created if none exists:
- Username: `admin`
- Password: `admin123`

Change this immediately after first login.

## API Summary

Auth:
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/me`
- `PUT /api/auth/theme`
- `GET /api/auth/takers`
- `GET /api/auth/accounters`

Orders:
- `POST /api/orders`
- `GET /api/orders`
- `PUT /api/orders/:id`
- `DELETE /api/orders/:id`
- `GET /api/orders/suggestions`
- `POST /api/orders/bulk-email`
- `GET /api/orders/maker`
- `GET /api/orders/taker`
- `GET /api/orders/admin`
- `GET /api/orders/accounter`

Items:
- `GET /api/items/suggestions`
- `PATCH /api/items/:itemId/status`

Notifications:
- `POST /api/notifications/subscribe`
- `GET /api/notifications`
- `PUT /api/notifications/:id/read`
- `PUT /api/notifications/read-all`

Admin:
- `GET /api/admin/stats`
- `GET /api/admin/users`
- `GET /api/admin/users/pending`
- `PUT /api/admin/users/:id/approve`
- `PUT /api/admin/users/:id/email`
- `DELETE /api/admin/users/:id`
- `GET /api/admin/orders`
- `GET /api/admin/orders/:id`
- `DELETE /api/admin/orders/:id`
- `GET /api/admin/logs`
- `GET /api/admin/logs/all`

## Utilities (server)

- `AMA-Order-System/server/check_users.js` prints maker/taker accounts.
- `AMA-Order-System/server/check_subs.js` lists push subscriptions.
- `AMA-Order-System/server/test_push.js` sends a test push notification.
- `AMA-Order-System/server/verify_push.js` verifies push setup.
- `AMA-Order-System/server/debug_db.js` dumps sample data.

## Testing and linting

Flutter:
```bash
flutter test
flutter analyze
dart format .
```

Server:
- No automated tests; use Postman or curl.
- `npm run test` is a dev server on port 3004.

## Build

```bash
flutter build apk
flutter build ios
flutter build web
```

## Deployment and network notes

- See `AMA-Order-System/INTERNET_SETUP.md` for LAN/public IP guidance, port forwarding, and environment-specific setup.
- See `AMA-Order-System/SECURITY_README.md` for network access notes and certificate guidance.

## Troubleshooting

- "Account pending admin approval": approve the user in Admin > Users.
- Cannot connect from a device: update `API_BASE_URL` to the LAN IP and allow the port in your firewall.
- HTTPS/self-signed errors: use `ALLOW_BAD_CERTS=true` for non-web clients or switch to HTTP.
- Email not sending: verify SMTP creds in `.env` and check server logs.

## Repository structure

- `lib/` Flutter app (entrypoint at `lib/main.dart`).
- `assets/` fonts and images.
- `AMA-Order-System/server/` Node/Express API.
- `AMA-Order-System/ama-order-system-front/` optional React/Vite frontend.
- `test/` Flutter widget tests.

## Security

- Do not commit `.env` or secrets.
- Rotate `JWT_SECRET`, email credentials, and web-push keys before production.
- Consider enabling TLS and certificate auth if exposing the server publicly.
