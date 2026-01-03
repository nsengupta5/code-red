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

## Repository layout (simplified)

```text
.
├── terraform/          # Terraform root modules
├── modules/            # Shared Terraform modules
├── envs/               # Environment-specific Terraform config
├── scripts/startup/    # VM startup / bootstrap scripts
├── dags/               # Airflow DAG definitions
├── docker/             # Dockerfiles and image build context
├── images/             # Additional image sources
└── .github/workflows/  # CI workflows
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
- `modules/**`
- `envs/**`
- `scripts/startup/**`

**What runs**
- ✅ `terraform.yml` (plan on PR, apply on merge)
- ❌ `dags.yml`
- ❌ `docker-build.yml`

**Why**
- Infrastructure state may change
- VM lifecycle, IAM, networking, or metadata may be affected

**Safety rails**
- Apply runs only if the plan has real changes
- VM recreation is flagged as a danger zone in PR comments

---

### 2. DAG-only changes

**Example changes**
- `dags/**`

**What runs**
- ✅ `dags.yml`
- ❌ `terraform.yml`
- ❌ `docker-build.yml`

**What happens**
- DAGs are parsed in CI using an ephemeral Airflow instance
- DAGs are synced to the GCS DAG bucket on merge to `main`
- The Airflow VM picks up changes via its sync mechanism

---

### 3. Docker / runtime changes

**Example changes**
- `docker/**`
- `images/**`
- `Dockerfile`
- `requirements*.txt`
- `pyproject.toml`

**What runs**
- ✅ `docker-build.yml`
- ❌ `terraform.yml`
- ❌ `dags.yml`

---

## Docker image lifecycle: build → promote

This repository uses a **two-phase image lifecycle**:
1. **Build & publish immutable images**
2. **Explicitly promote a chosen image to `prod`**

This avoids hidden runtime changes and keeps Airflow and Dataflow jobs deterministic.

---

### Step 1: Build the image (Pull Request)

**Trigger**
- Open a PR that changes Docker-related files

**What happens**
- `docker-build.yml` runs
- Image is **built only**
- Image is **not pushed**
- No GCP authentication is used

**Why**
- Validates Dockerfile and build logic
- Safe for forks and PRs
- No registry side effects

---

### Step 2: Publish the image (merge to `main`)

**Trigger**
- Merge PR into `main`

**What happens**
- `docker-build.yml` runs again
- Image is built and **pushed to Artifact Registry**
- Image is tagged **immutably** with the Git SHA

Example:
```
buggy-oom:4f2a9c1
```

**What does NOT happen**
- No `latest` tag is created
- No image is promoted automatically

---

### Step 3: Promote the image (manual, explicit)

**Trigger**
- Manual run of `image-promote.yml`

**Inputs**
- `image_sha`: SHA tag to promote
- `target_tag`: usually `prod`

**What happens**
- The SHA-tagged image is re-tagged as `prod`
- No rebuild occurs

Result:
```
buggy-oom:4f2a9c1   (immutable)
buggy-oom:prod     (points to chosen SHA)
```

**Why**
- Promotion is a conscious decision
- Rollbacks are trivial (re-promote an older SHA)

---

### Step 4: How DAGs reference images

**Option A: Pin to SHA**
- Fully deterministic
- Requires DAG change for every update

**Option B: Use `prod` (recommended)**
- DAGs remain unchanged
- Promotion controls behavior
- Rollback requires no DAG change

**Forbidden**
- `latest` tag (blocked by CI)

---

## Pull request behavior

- Terraform runs **plan only**
- Docker images build but do not push
- DAGs are parsed but not deployed
- No infrastructure or runtime mutations occur

---

## Merge to main behavior

- Terraform applies **only if changes exist**
- Docker images are built and pushed (SHA tags)
- DAGs are synced to GCS

---

## Why this matters (Airflow-specific)

- Airflow VM is long-lived
- SQLite metadata DB is sensitive to restarts
- Avoiding unnecessary churn improves stability

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
