# Cloud Commerce Platform

A full-stack ecommerce reference implementation using a monorepo architecture:

- **Frontend:** React + TypeScript + Vite + Framer Motion + Lucide React
- **Auth:** Node.js + Express + JWT + bcrypt
- **Catalog:** FastAPI with product catalog, categories, images and prices
- **Checkout:** Node.js + Express, server-side cart/order calculation
- **Payments:** Node.js + Express + Razorpay Standard Checkout
- **Containerization:** Docker + Docker Compose

## Architecture

```text
                    ┌──────────────────────┐
                    │ React + Vite Frontend │
                    │ Framer Motion         │
                    │ Lucide React          │
                    └──────────┬───────────┘
                               │
            ┌──────────────────┼──────────────────┐
            ▼                  ▼                  ▼
     ┌────────────┐     ┌────────────┐     ┌────────────┐
     │ Auth       │     │ Catalog    │     │ Checkout   │
     │ Node/Express│    │ FastAPI    │     │ Node/Express│
     └────────────┘     └────────────┘     └─────┬──────┘
                                                  │
                                                  ▼
                                           ┌────────────┐
                                           │ Payment    │
                                           │ Razorpay   │
                                           └────────────┘
```

## Run locally

1. Copy `.env.example` to `.env` and add Razorpay **Test Mode** credentials.
2. Install dependencies:

```bash
npm install
cd catalog-service && python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt && cd ..
```

3. Start the Node services and FastAPI service:

```bash
npm run dev
cd catalog-service && uvicorn main:app --reload --port 4002
```

4. Start the frontend at `http://localhost:5173`.

## Docker

```bash
docker compose up --build
```

Frontend: `http://localhost:8080`

## Razorpay integration

The payment service creates a Razorpay Order server-side, returns the order ID to the browser, and verifies the payment signature server-side. Do not expose `RAZORPAY_KEY_SECRET` to the frontend.

For production, configure Razorpay webhooks on a public HTTPS endpoint and handle `payment.captured`, `payment.failed`, and related events. The included webhook endpoint validates the Razorpay signature.

## Notes

This starter intentionally keeps user/order state in process memory so the complete project can run without a database. For production, replace the repositories with PostgreSQL/Redis and add durable idempotency, inventory reservation, queues, observability, rate limiting, and secrets management.
