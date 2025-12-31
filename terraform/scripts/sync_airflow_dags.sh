#!/usr/bin/env bash
set -euo pipefail

# Provided by startup template
DAG_BUCKET_URI="${DAG_BUCKET_URI:-}"
DAGS_DIR="${DAGS_DIR:-/opt/airflow/dags}"

HASH_FILE="/var/lib/airflow-dag-sync/bucket.md5"
STATE_DIR="$(dirname "$HASH_FILE")"

if [[ -z "${DAG_BUCKET_URI}" ]]; then
  echo "[dag-sync] DAG_BUCKET_URI is empty; skipping."
  exit 0
fi

mkdir -p "${STATE_DIR}"
mkdir -p "${DAGS_DIR}"

echo "[dag-sync] Checking DAG bucket: ${DAG_BUCKET_URI}"

# Hash the bucket contents deterministically:
# - list all objects recursively
# - print "md5  size  uri" for each object
# - sort for stable ordering
# - md5 the whole listing => "bucket fingerprint"
NEW_HASH="$(
  gsutil ls -r "${DAG_BUCKET_URI}/**" 2>/dev/null \
  | while read -r obj; do
      # Skip "directory placeholder" entries if any
      [[ "${obj}" == */ ]] && continue
      gsutil hash -m -h "${obj}" | awk -v uri="${obj}" '
        /^Hash \(md5\):/ {md5=$3}
        /^Content-Length:/ {sz=$2}
        END { if (md5 != "") print md5, sz, uri }
      '
    done \
  | LC_ALL=C sort \
  | md5sum \
  | awk '{print $1}'
)"

OLD_HASH=""
if [[ -f "${HASH_FILE}" ]]; then
  OLD_HASH="$(cat "${HASH_FILE}" || true)"
fi

if [[ "${NEW_HASH}" == "${OLD_HASH}" && -n "${NEW_HASH}" ]]; then
  echo "[dag-sync] No changes detected (hash=${NEW_HASH}). Skipping rsync."
  exit 0
fi

echo "[dag-sync] Changes detected (old=${OLD_HASH:-<none>} new=${NEW_HASH}). Syncing..."

# Sync bucket -> local dags directory
gsutil -m rsync -r -d "${DAG_BUCKET_URI}" "${DAGS_DIR}"

# Permissions (adjust user/group as needed)
chown -R al:al "${DAGS_DIR}" || true
chmod -R 755 "${DAGS_DIR}" || true

echo "${NEW_HASH}" > "${HASH_FILE}"
echo "[dag-sync] Sync complete."
