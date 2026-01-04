# GCP Organization Policies

This directory manages **GCP Organization and Project Policy overrides**
that apply governance and security controls across the platform.

## Scope

Policies in this directory are:
- **Not application infrastructure**
- Applied independently of environment Terraform
- Owned by platform / security maintainers

## Managed Policies

### iam.disableServiceAccountKeyCreation (Project Override)

- **Default org policy:** Enforced (service account keys disabled)
- **Project override:** Disabled for a specific project

#### Rationale
The GCP Billing Budgets API does not reliably support Workload Identity
Federation in CI/CD pipelines. A service account key is required to
create billing budgets via Terraform.

This override:
- Applies only to a single project
- Keeps the org-wide restriction enforced else
