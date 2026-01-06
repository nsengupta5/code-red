# IAM Considerations


## Billing Alerts & Observability

This document explains **why specific IAM roles are required** for the billing alerts, observability, and Slack notification pipeline in this repository. It is intended to prevent accidental removal of required permissions and to document deliberate security trade-offs.

---

## Architecture Context

The billing alerting flow is:

```
GCP Billing Budget
   → Pub/Sub Topic
     → Eventarc
       → Cloud Functions Gen 2
         → Cloud Run (under the hood)
           → Slack Webhook
```

Cloud Functions **Gen 2** run on Cloud Run and are triggered asynchronously by Eventarc. This has important IAM implications that differ from Gen 1 Cloud Functions.

---

## Key IAM Design Decisions

### 1. `allUsers → roles/run.invoker` (REQUIRED)

**Where:** Cloud Run service backing the Cloud Function

**Why this exists:**

For Pub/Sub–triggered Cloud Functions Gen 2, Eventarc delivers events **without an end-user authentication token**. Cloud Run will reject these requests unless unauthenticated invocation is explicitly allowed.

Granting:

```
allUsers → roles/run.invoker
```

enables Eventarc delivery and is a **documented requirement** for this trigger model.

**Why this is safe:**

- No public HTTP endpoint is advertised
- Ingress is restricted to Google-managed infrastructure
- Only Eventarc can reach the service in practice
- No human or workload can invoke the function directly

⚠️ **Do not remove this binding** unless the trigger model changes. Removing it will cause billing alerts to silently stop.

---

### 2. Eventarc Service Agent

```
service-<PROJECT_NUMBER>@gcp-sa-eventarc.iam.gserviceaccount.com
```

- May optionally have `roles/run.invoker`
- Redundant once `allUsers` is granted
- Safe but not required

This binding may be removed for cleanliness but is not harmful if retained.

---

### 3. Pub/Sub Service Agent (NOT REQUIRED)

```
service-<PROJECT_NUMBER>@gcp-sa-pubsub.iam.gserviceaccount.com
```

Pub/Sub **does not invoke Cloud Run directly** and therefore does **not** require `roles/run.invoker`.

Any such binding added during troubleshooting can and should be removed.

---

## Billing Alerts Function Service Account

```
billing-alerts-sa@<project>.iam.gserviceaccount.com
```

### Required Roles (Minimal Set)

- `roles/pubsub.subscriber` – consume billing alert messages
- `roles/secretmanager.secretAccessor` – read Slack webhook URL
- `roles/logging.logWriter` – write execution logs

No broader roles are required.

---

## Cloud Build Service Account

```
<PROJECT_NUMBER>@cloudbuild.gserviceaccount.com
```

### Required Roles

- `roles/cloudbuild.builds.builder`
- `roles/artifactregistry.writer`

These are required for building and publishing Cloud Functions Gen 2 artifacts.

❌ `roles/editor` was used temporarily during debugging and **must not remain**.

---

## Terraform Deployer Service Account

```
terraform-deployer@<project>.iam.gserviceaccount.com
```

### Expected Roles

- `roles/run.admin` – manage Cloud Run IAM bindings
- `roles/iam.serviceAccountAdmin`
- `roles/resourcemanager.projectIamAdmin`
- `roles/secretmanager.admin`
- `roles/billing.admin` (billing account scope)

These roles allow Terraform CI/CD to fully manage infrastructure without requiring Owner or Editor access.

---

## Organization / Project Policy Overrides

### Service Account Key Creation

The project-level override:

```
iam.disableServiceAccountKeyCreation = false
```

is intentionally applied to support CI/CD and integration workflows. This override is:

- Scoped to the project
- Documented
- Not applied at the organization level

---

## Security Summary

- All permissions are **least privilege** and **intentional**
- Any seemingly risky binding is documented with rationale
- Temporary debugging roles (e.g. Editor) have been removed
- IAM is codified in Terraform where possible

This configuration reflects the **minimum viable IAM** required to support Cloud Functions Gen 2, Eventarc, Pub/Sub, and Slack-based billing alerts reliably.

---

## Reviewer Notes

If reviewing this repository:

- The `allUsers → roles/run.invoker` binding is required by design
- Removing it will break Pub/Sub delivery
- This behaviour is specific to Cloud Functions Gen 2

Please refer to this document before modifying IAM bindings.
