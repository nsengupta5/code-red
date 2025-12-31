# Airflow DAG Deployment and Synchronization

This document explains **how Apache Airflow DAGs are updated**, **how they are synced to Google Cloud Storage (GCS)**, and **how they are automatically synchronized onto the Airflow VM** in this repository.

---

## High-level architecture

The DAG deployment flow follows this pattern:

```
Local development  →  GCS DAG bucket  →  Airflow VM (via systemd timer)
```

- DAGs are authored and version-controlled in this repository
- DAG files are synced to a dedicated **GCS bucket**
- The Airflow VM periodically pulls DAGs from GCS into `/opt/airflow/dags`

This design keeps the Airflow VM **stateless with respect to DAG code** and avoids manual SSH-based updates.

---

## DAG source of truth

The **source of truth** for DAGs is this repository.

Typical location:

```
dags/
  ├── csv_to_bq.py
  ├── example_dag.py
  └── ...
```

All DAG changes should:

1. Be made locally
2. Be committed to version control
3. Be synced to GCS

---

## Syncing DAGs from local → GCS

DAGs are uploaded to GCS **automatically via the Terraform CI pipeline**. Manual sync is still possible for local testing, but CI is the primary mechanism.

---

### CI-based DAG deployment (primary path)

DAG deployment is handled as part of the Terraform GitHub Actions workflow.

Relevant pipeline step:

```yaml
- name: Setup gcloud
  uses: google-github-actions/setup-gcloud@v2

- name: Sync Airflow DAGs to GCS
  run: |
    gsutil rsync -d -r dags/ gs://airflow-dags-258083003066/
```

This step runs on every pipeline execution and ensures:

- DAGs in the repository are treated as the **source of truth**
- New or modified DAGs are uploaded to GCS
- Removed DAGs are deleted from GCS (`-d` flag)

No manual action is required to deploy DAG changes.

---

### Manual local → GCS sync (optional)

For development or debugging, DAGs can still be synced manually:

```bash
./terraform/scripts/sync_airflow_dags.sh
```

Internally this uses:

```bash
gsutil rsync -d -r ./dags gs://<bucket-name>/dags
```

Manual sync should **not** be used as the primary deployment mechanism in shared environments.

---

## Syncing DAGs from GCS → Airflow VM

### Where DAGs live on the VM

On the Airflow VM, DAGs are stored in:

```
/opt/airflow/dags
```

Airflow is configured to load DAGs from this directory.

---

### DAG sync mechanism

The Airflow VM runs a **systemd timer** that periodically syncs DAGs from GCS.

#### Sync script

The script is installed at:

```
/usr/local/bin/sync-airflow-dags.sh
```

It performs:

```bash
gsutil rsync -r gs://<bucket-name>/dags /opt/airflow/dags
```

The script is:

- Idempotent
- Safe to run repeatedly
- Independent of Airflow services

---

### systemd service

```
airflow-dag-sync.service
```

- Type: `oneshot`
- Runs the DAG sync script once per invocation
- Can be triggered manually or by the timer

Manual run:

```bash
sudo systemctl start airflow-dag-sync.service
```

---

### systemd timer

```
airflow-dag-sync.timer
```

Key properties:

- Runs every **2 minutes** (configurable)
- Starts shortly after boot
- Uses `Persistent=true` to catch up missed runs

Check status:

```bash
systemctl status airflow-dag-sync.timer
```

List scheduled timers:

```bash
systemctl list-timers | grep airflow
```

---

## End-to-end DAG update flow

1. Modify or add a DAG locally
2. Commit changes to the repo
3. Run the local DAG → GCS sync script
4. The Airflow VM automatically pulls updates within the next timer interval
5. Airflow detects DAG changes and updates the UI

No VM restart is required.

---

## Troubleshooting

### DAG changes not appearing

Check:

```bash
systemctl status airflow-dag-sync.timer
journalctl -u airflow-dag-sync.service
```

Verify files:

```bash
ls -lt /opt/airflow/dags
```

---

### Force an immediate sync

```bash
sudo systemctl start airflow-dag-sync.service
```

---

## Design rationale

This approach was chosen because it:

- Avoids SSH-based DAG management
- Keeps Airflow VMs immutable
- Makes DAG updates fast and predictable
- Works well for both dev and prod

---

## Notes

- Executor and database configuration must be compatible (e.g. SQLite requires SequentialExecutor)
- The sync mechanism is independent of Airflow itself
- GCS acts as the deployment boundary between CI/CD and runtime

---

**Summary:**

> DAGs are edited locally, synced to GCS, and automatically pulled onto the Airflow VM using a systemd timer — ensuring consistent, repeatable, and hands-off DAG deployment.

