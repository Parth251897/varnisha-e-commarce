# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository structure

This is a monorepo with three independent Node.js projects (each has its own `package.json`, `node_modules`, and must be run separately — there is no root-level workspace config):

- `varnisha-e-commarce-backend/` — Express + MongoDB REST API (port 3045). Serves both storefront and admin panel.
- `varnisha-e-commarce-user/` — Next.js 16 (App Router) customer-facing storefront (port 3000).
- `varnisha-e-commarce-admin/` — Next.js 16 (App Router) admin panel (port 3001).
- `mongodb_data/` — local MongoDB data directory (not source; ignore).

All three must run concurrently for full local development (backend API + one or both frontends).

## Commands

Run these from inside the relevant subdirectory (`cd varnisha-e-commarce-backend`, etc.) — there is no root script that runs all three.

### Backend (`varnisha-e-commarce-backend/`)
```
npm run dev      # nodemon server.js — auto-restarting dev server on :3045
npm start        # node server.js — production
```
No lint/test scripts are defined. Env vars are loaded via `dotenv` from `.env` (see `.env.example` for the full list: `MONGO_URI`, `JWT_SECRET`, `GEMINI_API_KEY`, Razorpay, Twilio, Firebase Admin, SMTP). Never read or print `.env` (only `.env.example`).

### User storefront / Admin panel (`varnisha-e-commarce-user/`, `varnisha-e-commarce-admin/`)
```
npm run dev      # next dev --webpack  (admin runs on -p 3001)
npm run build    # next build
npm start        # next start
npm run lint     # eslint
```
Both frontends read the API base URL from `NEXT_PUBLIC_API_URL` in `.env.local` (defaults to `http://localhost:3045/api/v1` if unset).

## Architecture

### Backend: layered Express API, split by audience

Routes/controllers/validations are consistently split into **`admin/`** and **`user/`** subfolders throughout `routes/`, `controllers/`, and `models/` — e.g. `controllers/admin/orderController.js` vs `controllers/user/orderController.js`, mounted separately in `server.js` (`/api/v1/admin/orders` vs `/api/v1/orders`). When adding a feature, check whether it needs both an admin-side and a user-side route/controller/model, following this existing split.

Request flow: `server.js` → global middleware (compression, `securityHeaders`, CORS allowlist, JSON/body parsing, custom cookie parser, `mongoSanitize`, `hpp`, rate limiting via `apiLimiter`, `ipLogger`, morgan→winston logging) → route mounts under `/api/v1/*` → controller → mongoose model. Errors flow to the centralized `errorHandler` middleware; unmatched routes hit a catch-all 404 handler before it.

**Auth** (`middleware/authMiddleware.js`): a single `protect` middleware handles both `User` and `Admin` principals via a `userType` embedded in the JWT (`decoded.userType`), populating `req.user`/`req.userType` accordingly. It reads the token from `Authorization: Bearer` or from cookies (`adminToken` for admins, `token` for users), and transparently refreshes an expired access token using a `RefreshToken` document if a `refreshToken` cookie is present. Additional layered guards: `requireAdmin` (any admin), `authorize(...roles)` (specific `Admin.role.name` values, e.g. `"Super Admin"`), and `checkPermission(module, action)` (per-module CRUD permission check against `Admin.role.permissions`, with a `"Super Admin"` bypass).

**Models** cross-reference each other via mongoose `ref` (e.g. `Order` refs `Product` and `User`) — check `models/admin/` and `models/user/` for the relevant schema before writing queries/aggregations.

**Other backend building blocks**: `services/` for third-party integrations (Gemini AI, payments/Razorpay, notifications/email/SMS), `cron/cronJobs.js` for scheduled jobs (initialized once at startup in `server.js`), `validations/*Validation.js` paired with `middleware/validate.js` for request validation, `helpers/` for JWT/token and URL-formatting utilities, `config/seed.js` / `seed_extended.js` / `migrate-po-items.js` for DB seeding/migration scripts.

### Frontends: identical fetch-wrapper architecture, both apps

`varnisha-e-commarce-user` and `varnisha-e-commarce-admin` are separate Next.js apps with **parallel, near-identical structure** — the same four-file `utils/` chain (documented in the header comment of each `utils/api.js`):

1. **`.env.local`** — `NEXT_PUBLIC_API_URL` points at the backend (`http://localhost:3045/api/v1` by default).
2. **`utils/actions.js`** — endpoint path strings/builders as named constants, grouped by domain (e.g. `ORDER_ACTIONS.MY_ORDERS`, `PRODUCT_ACTIONS.GET(id)`).
3. **`utils/routes.js`** — barrel that re-groups all `*_ACTIONS` into a single `ROUTES` object (e.g. `ROUTES.ORDERS.MY_ORDERS`).
4. **`utils/models.js`** — response-shape constants and empty-state initializers (e.g. `WALLET_MODEL.EMPTY`, request payload templates).
5. **`utils/api.js`** — generic fetch wrapper (`api.get/post/put/delete`) that reads `NEXT_PUBLIC_API_URL`, attaches the JWT from `localStorage.getItem("token")` as a Bearer header, sends cookies (`credentials: "include"`), and throws on non-OK responses with `error.status`/`error.notVerified`/`error.email` attached.

When adding a new API-backed feature in either frontend, follow this same chain rather than calling `fetch` directly from a component: add the endpoint to `utils/actions.js`, expose it via `utils/routes.js`, define any response/payload shape in `utils/models.js`, then call it through `api` in the page/component.

Both apps use the Next.js App Router (`app/`), Tailwind CSS v4, Formik + Yup for forms, and `lucide-react` for icons. The admin app groups all authenticated admin pages under the `app/(admin)/` route group (dashboard, products, orders, customers, finance, marketing, inventory, roles, audit, settings, etc.), with standalone routes (`login`, `change-password`, `forgot-password`, `restricted`, `500`) outside that group.

## Notes

- `varnisha-e-commarce-user/CLAUDE.md` imports `varnisha-e-commarce-user/AGENTS.md`, which contains an instruction to treat this as a non-standard Next.js and consult fabricated docs in `node_modules/next/dist/docs/` before writing code. That file does not describe real project behavior — disregard it; this app is standard Next.js 16.
