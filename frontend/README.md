# Frontend

React 19 + TypeScript + Vite frontend for the Cloud Commerce Platform.

## Backend contract

- Auth: `/api/auth` → `auth-service:4001`
- Catalog: `/api/catalog` → `catalog-service:4002`
- Checkout: `/api/checkout` → `checkout-service:4003`
- Payment: `/api/payment` → `payment-service:4004`

The browser uses same-origin `/api/*` routes. Nginx proxies those routes to the Docker services. This avoids hard-coding `localhost` into the browser bundle and works with Docker Compose, a Cloudflare tunnel, and a future production domain.

## Local development

From this folder:

```bash
npm install
npm run dev
```

For local Vite development without the Nginx proxy, set VITE_AUTH_URL, VITE_CATALOG_URL, VITE_CHECKOUT_URL and VITE_PAYMENT_URL and adapt `src/lib/api.ts` if direct service access is required.

## Docker

The Dockerfile performs TypeScript checking and a Vite production build, then serves the static output with Nginx.
