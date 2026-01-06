# GitHub Actions Workflow Behavior (Monorepo)

This document explains **which GitHub Actions workflows run** based on **what changes** are made in the repository.
It is intended to help contributors understand CI behavior and avoid accidental coupling between infrastructure,
runtime artifacts, and Airflow DAGs.

---

## High-level principle

> **A workflow runs only when it can produce a different result.**

Each workflow owns exactly one domain:
- **Terraform** → infrastructure state
- **Docker** → runtime artifacts
- **DAGs** → Airflow application code

This separation protects the long-lived Airflow VM and keeps CI deterministic.

---

## Repository layout (authoritative)

```text
.
├── Dockerfile              # Container image definition
├── requirements.txt        # Image runtime dependencies
├── src/                    # Image application code
├── dags/                   # Airflow DAG definitions
├── terraform/              # Infrastructure as code (Terraform)
│   ├── envs/               # Environment-specific config
│   ├── modules/            # Reusable Terraform modules
│   └── scripts/            # Infra-related helper scripts
├── docs/                   # Architecture & operations documentation
└── .github/workflows/      # CI workflows
```

---

## Workflow summary

| Workflow | File | Purpose |
|--------|------|---------|
| Terraform | terraform.yml | Plan/apply infrastructure |
| DAGs | dags.yml | Validate and deploy DAGs to GCS |
| Docker Build | docker-build.yml | Build Docker images |
| Image Promote | image-promote.yml | Promote images (SHA → prod) |
| PR Policy | pr-policy.yml | Enforce dependency graph invariants |

---

## Behavior by change type

### 1. Terraform-only changes

**Example changes**
- `terraform/**`

**What runs**
- ✅ `terraform.yml` (plan on PR, apply on merge)
- ❌ `dags.yml`
- ❌ `docker-build.yml`

---

### 2. DAG-only changes

**Example changes**
- `dags/**`

**What runs**
- ✅ `dags.yml`
- ❌ `terraform.yml`
- ❌ `docker-build.yml`

---

### 3. Docker / runtime changes

**Example changes**
- `Dockerfile`
- `requirements.txt`
- `src/**`

**What runs**
- ✅ `docker-build.yml`
- ❌ `terraform.yml`
- ❌ `dags.yml`

---

## Docker image lifecycle: build → promote

This repository uses a **two-phase image lifecycle**:
1. **Build & publish immutable images**
2. **Explicitly promote a chosen image to `prod`**

### Step 1: Build the image (Pull Request)
- Image is built only
- No registry writes
- No GCP authentication

### Step 2: Publish the image (merge to `main`)
- Image is built and pushed
- Tagged immutably with Git SHA

### Step 3: Promote the image (manual)
- Explicit promotion via `image-promote.yml`
- Re-tags SHA → `prod`
- No rebuild occurs

---

## TL;DR

```text
PR        → build image only
main      → build + push (SHA)
manual    → promote SHA → prod
DAGs      → reference prod or SHA
```

No `latest`.  
No surprises.  
Everything is intentional.
