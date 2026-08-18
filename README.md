# cloud-commerce

A production-style e-commerce platform built on AWS and Kubernetes — not to ship a product, but to build the kind of infrastructure that would support one.

The project grew from a simple microservices app into a full AWS deployment with EKS, Terraform, a CI/CD pipeline, secrets management, observability, and security scanning. Each layer was added because the previous one needed it, not because a checklist said so.

---

## What this actually is

Most "production-ready" demo projects are one of two things: a toy app with an impressive README, or a real app with no infrastructure. This is neither.

The application itself is straightforward — a frontend, an auth service, a catalog, checkout, and payment service. What's not straightforward is everything around it: the VPC design, the EKS cluster, the Helm chart, the GitHub Actions pipeline that builds, scans, signs, and deploys images without ever touching a long-lived AWS credential, and the Grafana dashboards that pull from Prometheus, Loki, and Tempo.

The goal was a complete path from a code change to a validated workload running on AWS.

---

## Architecture

```
Users
  └─▶ Route 53 ──▶ CloudFront ──▶ AWS WAF ──▶ ALB ──▶ EKS
                                                         │
                              ┌──────────────────────────┤
                              │                          │
                           Ingress                   Data layer
                              │                          │
                    ┌─────────┼─────────┐       ┌───────┼────────┐
                    │         │         │       │       │        │
                 Frontend   Auth    Catalog   RDS   Redis    DynamoDB
                          Service   + Cart            │
                                   + Pay          ElastiCache
                                                      │
                                               SQS ──▶ EventBridge
```

Application workloads run inside EKS. Storage, caching, messaging, and event delivery are handled by AWS managed services. Secrets flow from AWS Secrets Manager through External Secrets Operator into Kubernetes — never from Git.

---

## Services

| Service | Stack | Does |
|---|---|---|
| Frontend | React | The user-facing app |
| Auth Service | Node.js | Authentication and sessions |
| Catalog Service | FastAPI / Python | Products and browsing |
| Checkout Service | Node.js | Cart and checkout flow |
| Payment Service | Node.js | Payment processing |

---

## Infrastructure

Terraform manages the full AWS environment. Nothing is created manually.

The current stack covers VPC and subnets, EKS with managed node groups, ECR, IAM, GitHub Actions OIDC, ALB Controller, ACM and Route 53, CloudFront, WAF, RDS PostgreSQL (Multi-AZ), ElastiCache Redis (Multi-AZ with failover), DynamoDB, S3, SQS, EventBridge, External Secrets Operator, and EBS CSI.

RDS and Redis are configured for Multi-AZ from the start. This was a deliberate choice — it forces dealing with real failover behavior rather than discovering it later.

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Destroy when you're done:

```bash
terraform destroy
```

Some resources charge even when idle. The workflow is: deploy, validate, test, destroy.

---

## Kubernetes

The application runs on EKS and is deployed with Helm.

```
helm/cloud-commerce/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployments
    ├── services
    ├── ingress
    ├── hpa
    ├── configmaps
    └── external-secrets
```

The cluster uses VPC CNI, CoreDNS, kube-proxy, EKS Pod Identity Agent, EBS CSI, and Metrics Server.

---

## Secrets

Secrets do not live in Git or in Kubernetes manifests.

```
AWS Secrets Manager
       ↓
External Secrets Operator
       ↓
Kubernetes Secret
       ↓
Application Pod
```

The External Secrets Operator syncs secrets from AWS Secrets Manager into the cluster at deployment time. Nothing sensitive touches the repository.

---

## CI/CD

Two workflows. CI validates every change. CD deploys to production.

### CI

Runs on every push to `main` and every pull request targeting it.

```
Checkout
  → Install dependencies
  → Build frontend
  → Validate Node services
  → Compile Python
  → Gitleaks (secret scanning)
  → Semgrep (SAST)
```

### CD

Deployment is split into a release stage and a deployment stage on purpose. The pipeline does not stop at `helm upgrade`.

```
GitHub
  → OIDC (no long-lived AWS keys)
  → ECR authentication
  → Build images (linux/amd64)
  → Trivy scan (HIGH + CRITICAL, unfixable ignored)
  → Push to ECR
  → Cosign signing
  → EKS access
  → helm lint
  → Server-side dry-run
  → helm upgrade --install
  → Rollout verification (all 5 deployments)
  → HPA verification (all 5 HPAs)
```

The five images are:

- `cloud-commerce-frontend`
- `cloud-commerce-auth-service`
- `cloud-commerce-catalog-service`
- `cloud-commerce-checkout-service`
- `cloud-commerce-payment-service`

---

## Security

Security was built alongside the deployment, not added at the end.

**GitHub OIDC** — GitHub Actions assumes an AWS IAM role through OIDC. No access key is stored anywhere.

**Gitleaks** — Scans repository history for accidentally committed secrets.

**Semgrep** — SAST over JavaScript, TypeScript, Python, and Dockerfiles.

**Trivy** — Container images are scanned before they are pushed to ECR. HIGH and CRITICAL vulnerabilities block the pipeline unless no fix is available.

**Cosign** — Images are signed after being pushed. The lifecycle is: Build → Scan → Push → Sign.

**AWS layer** — CloudTrail, GuardDuty, Secrets Manager, and S3 audit storage round out the security surface at the platform level.

---

## Observability

Three signals, one dashboard.

```
Applications / Kubernetes
  ├── Metrics ──▶ Prometheus ──┐
  ├── Logs ────▶ Loki ─────────┼──▶ Grafana
  └── Traces ──▶ Tempo ────────┘
```

Prometheus collects metrics from the cluster and applications. Loki handles centralized log collection. Tempo provides distributed tracing. Grafana brings them together for dashboards, SLO views, and alerts.

---

## Local development

```bash
npm ci
docker compose up --build
```

Stop:

```bash
docker compose down
```

Copy `.env.example` to `.env` for local configuration. Never commit real credentials.

---

## How this was built

The project was built in phases rather than starting with the full Kubernetes stack.

1. **Application** — service structure, dependencies, shared packages
2. **Containers** — Docker Compose for local development
3. **AWS networking** — VPC, subnets, routing, security groups, DNS, ACM
4. **Registry and IAM** — ECR and IAM foundation
5. **EKS** — cluster, managed node groups, add-ons
6. **Helm** — Kubernetes manifests organized into a chart
7. **Data and async** — RDS, Redis, DynamoDB, SQS, EventBridge, Secrets Manager
8. **Security and observability** — OIDC, scanning, signing, Prometheus, Loki, Tempo, Grafana
9. **Production delivery** — full deployment path, ALB/TLS, Route 53, CloudFront, runtime validation

Each phase built on the previous one. The Terraform files still carry phase comments where each piece of infrastructure was introduced.

---

## Cost

This architecture prioritizes availability, security, and realism. That costs money.

Resources that run charges even when idle include the NAT Gateway, ALB, RDS (Multi-AZ), Redis (Multi-AZ), and the EKS cluster itself.

**Deploy → validate → test → destroy** is the right workflow for development and learning.

Areas to optimize if you're running this longer-term: EKS node sizing, NAT Gateway usage, RDS and Redis instance sizes, ECR lifecycle policies, log retention, and CloudFront configuration.

---

## Repository layout

```
cloud-commerce/
├── .github/workflows/
│   ├── ci.yml
│   └── cd.yml
├── frontend/
├── auth-service/
├── catalog-service/
├── checkout-service/
├── payment-service/
├── packages/
├── helm/cloud-commerce/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── terraform/
│   └── (VPC, EKS, ECR, IAM, RDS, Redis, DynamoDB,
│      SQS, EventBridge, External Secrets, ALB,
│      ACM, Route 53, CloudFront, ...)
├── docker-compose.yml
├── package.json
└── .env.example
```<img width="441" height="590" alt="Screenshot 2026-08-18 at 4 18 21 PM" src="https://github.com/user-attachments/assets/e829aa7f-b64d-4d5d-a61a-3756354a2ad3" />
