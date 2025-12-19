# Terraform GCP Composer & Dataflow Repository Guide

This document explains how this repository is structured, how Terraform is used, and how local development, GitHub Actions, and Google Cloud Platform (GCP) work together.

---

## High-level goals

This repository is designed to:

- Provision **Google Cloud infrastructure using Terraform (IaC)**
- Use **GitHub Actions with Workload Identity Federation** (no service account keys)
- Support **Cloud Composer 2** and **Dataflow** in a trial / dev GCP project
- Safely manage state using a **remote GCS backend**
- Allow Composer to be **enabled or disabled** to control cost

---

## Repository structure

```
.
├── .github/
│   └── workflows/
│       └── terraform.yml        # GitHub Actions CI pipeline
│
├── terraform/
│   ├── envs/
│   │   └── dev/
│   │       ├── backend.tf       # Remote state (GCS)
│   │       ├── main.tf          # Providers + module wiring
│   │       ├── variables.tf     # Environment-level variables
│   │
│   └── modules/
│       ├── iam/
│       │   ├── main.tf          # Service accounts + IAM bindings
│       │   ├── variables.tf
│       │   └── outputs.tf
│       │
│       └── composer/
│           ├── main.tf          # Cloud Composer environment
│           └── variables.tf
│
├── .terraform.lock.hcl          # Provider version lock (COMMIT THIS)
├── .gitignore
└── README.md
```

---

## Key concepts

### 1. Terraform modules

- **`modules/iam`**
  - Owns *all* service accounts
  - Grants IAM roles
  - Outputs service account emails

- **`modules/composer`**
  - Creates the Cloud Composer environment
  - Does **not** create service accounts
  - Accepts a service account email as input

This separation keeps identity management isolated from infrastructure logic.

---

### 2. Environment wiring (`envs/dev`)

The `envs/dev` folder is the **root Terraform module** for the dev environment.

It is responsible for:

- Selecting providers
- Configuring the Terraform backend
- Instantiating child modules
- Passing outputs between modules

Example (simplified):

```hcl
module "iam" {
  source     = "../../modules/iam"
  project_id = var.project_id
}

module "composer" {
  count                  = var.enable_composer ? 1 : 0
  source                 = "../../modules/composer"
  name                   = "dev-composer"
  region                 = var.region
  service_account_email  = module.iam.composer_service_account_email
}
```

---

### 3. Terraform state (CRITICAL)

This repo uses a **remote backend**:

- **Backend:** Google Cloud Storage (GCS)
- **Purpose:** Share Terraform state between
  - Local machine
  - GitHub Actions CI

`terraform/envs/dev/backend.tf`

```hcl
terraform {
  backend "gcs" {
    bucket  = "<existing-unique-bucket-name>"
    prefix = "dev"
  }
}
```

Important rules:

- There should be **NO `terraform.tfstate` file committed**
- The `.terraform/` directory is ignored
- Both local and CI must run Terraform from `terraform/envs/dev`

---

### 4. GitHub Actions authentication

CI uses **Workload Identity Federation**:

- No service account keys
- No secrets stored in GitHub

Flow:

1. GitHub Actions requests an OIDC token
2. GCP validates it against a Workload Identity Pool
3. Terraform runs as `terraform-deployer@...`

Key permissions for the deployer SA:

- `roles/resourcemanager.projectIamAdmin`
- `roles/iam.serviceAccountAdmin`
- `roles/storage.admin` (for state bucket)

---

### 5. GitHub Actions Terraform workflow (simplified)

```yaml
- uses: actions/checkout@v4

- uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: <provider-path>
    service_account: terraform-deployer@PROJECT.iam.gserviceaccount.com

- uses: hashicorp/setup-terraform@v3

- name: Terraform Init
  working-directory: terraform/envs/dev
  run: terraform init -reconfigure

- name: Terraform Plan
  working-directory: terraform/envs/dev
  run: terraform plan

- name: Terraform Apply
  working-directory: terraform/envs/dev
  run: terraform apply -auto-approve
```

**Every Terraform command must set `working-directory`.**

---

### 6. Cloud Composer specifics

- Cloud Composer 2 runs on **GKE Autopilot**
- Provisioning typically takes **20–30 minutes**
- Requires **explicit service account configuration**
- Highly sensitive to **CPU and SSD quotas**

Because of cost and quota sensitivity, **Composer is toggled on/off via Git**, not CLI flags.

---

### 7. Toggling Cloud Composer on and off (Git-driven)

Composer creation is controlled by a committed Terraform variables file. This ensures:

- Local runs and CI behave identically
- Composer is never created accidentally
- Desired state is visible in Git history

#### The control file

```
terraform/envs/dev/dev.auto.tfvars
```

```hcl
enable_composer = false
```

Terraform automatically loads `*.auto.tfvars` files, so **no `-var` flags are required**.

#### Variable definition

In `terraform/envs/dev/variables.tf`:

```hcl
variable "enable_composer" {
  description = "Enable or disable the Cloud Composer environment"
  type        = bool
}
```

The variable intentionally has **no default** to force an explicit choice per environment.

#### Module wiring

In `terraform/envs/dev/main.tf`:

```hcl
module "composer" {
  count = var.enable_composer ? 1 : 0

  source                = "../../modules/composer"
  name                  = "dev-composer"
  region                = var.region
  project_id            = var.project_id
  service_account_email = module.iam.composer_service_account_email
}
```

When `enable_composer = false`, the module does not exist and Composer is destroyed.

#### Turning Composer ON

1. Edit `dev.auto.tfvars`
2. Set:
   ```hcl
   enable_composer = true
   ```
3. Commit and push
4. GitHub Actions applies the change

#### Turning Composer OFF

1. Edit `dev.auto.tfvars`
2. Set:
   ```hcl
   enable_composer = false
   ```
3. Commit and push
4. GitHub Actions destroys the Composer environment

IAM resources and service accounts are **not destroyed**.

---


### 8. Local development workflow

Before running Terraform locally:

```bash
gcloud auth login
gcloud auth application-default login
gcloud auth application-default set-quota-project <project-id>
```

Then:

```bash
cd terraform/envs/dev
terraform init -reconfigure
terraform plan
terraform apply
```

Local and CI behavior should now be identical.

---

## Common pitfalls (and how this repo avoids them)

| Problem | Mitigation |
|------|-----------|
| Service account already exists (409) | Import + shared remote state |
| CI and local plans differ | GCS backend |
| Accidental provider upgrades | `.terraform.lock.hcl` committed |
| Composer too expensive | `enable_composer` toggle |
| Leaked credentials | OIDC (no keys) |

---

## Summary

This repository follows production-grade Terraform practices:

- Clear module boundaries
- Centralized IAM management
- Secure CI authentication
- Shared remote state
- Cost-aware Composer usage

Once this foundation is in place, adding Dataflow pipelines, DAG deployment, or additional environments becomes straightforward.

---

## Next possible extensions

- Add a `prod` environment
- Add Dataflow service accounts and templates
- Add budget alerts
- Add manual approval for `terraform apply`
- Add Composer DAG deployment pipeline

---

End of document.

