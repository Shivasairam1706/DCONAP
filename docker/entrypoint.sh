#!/usr/bin/env bash
set -euo pipefail

#-------------------------------
# Globals & Defaults (override via ENV)
#-------------------------------
JUPYTER_USER_DIR="${JUPYTER_WORKSPACE_DIR:-/home/jupyteruser/work}"
LOG_DIR="${LOG_DIR:-${JUPYTER_USER_DIR}/logs}"
JUPYTER_PORT="${JUPYTER_PORT:-8888}"
JUPYTER_PASSWORD="${JUPYTER_PASSWORD:-}"
JUPYTER_TOKEN="${JUPYTER_TOKEN:-}"
OWNER_UID="${UID:-1000}"
OWNER_GID="${GID:-1000}"
JUPYTER_CONFIG_DIR="/home/jupyteruser/.jupyter"

# Ensure log dir and config dir exist & owned correctly
mkdir -p "${LOG_DIR}" "${JUPYTER_CONFIG_DIR}"
chown -R "${OWNER_UID}:${OWNER_GID}" "${JUPYTER_USER_DIR}" "${LOG_DIR}" "${JUPYTER_CONFIG_DIR}"

# Redirect all stdout/stderr to a logfile (and console)
LOGFILE="${LOG_DIR}/entrypoint.$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "${LOGFILE}") 2>&1

echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] Starting entrypoint"
echo "  Workspace: ${JUPYTER_USER_DIR}"
echo "  Log file:  ${LOGFILE}"

#-------------------------------
# Jupyter Auth Setup
#-------------------------------
if [[ -n "${JUPYTER_PASSWORD}" ]]; then
  echo "[$(date)] Configuring password auth for JupyterLab"
  HASH=$(python3 - <<PYCODE
from jupyter_server.auth import passwd
print(passwd("${JUPYTER_PASSWORD}"))
PYCODE
  )
  cat > "${JUPYTER_CONFIG_DIR}/jupyter_server_config.py" <<EOF
c.ServerApp.password = u'${HASH}'
c.ServerApp.port = ${JUPYTER_PORT}
c.ServerApp.open_browser = False
c.ServerApp.notebook_dir = '${JUPYTER_USER_DIR}'
EOF

elif [[ -n "${JUPYTER_TOKEN}" ]]; then
  echo "[$(date)] Configuring token auth for JupyterLab"
  cat > "${JUPYTER_CONFIG_DIR}/jupyter_server_config.py" <<EOF
c.ServerApp.token = '${JUPYTER_TOKEN}'
c.ServerApp.port = ${JUPYTER_PORT}
c.ServerApp.open_browser = False
c.ServerApp.notebook_dir = '${JUPYTER_USER_DIR}'
EOF

else
  echo "[$(date)] No JUPYTER_PASSWORD or JUPYTER_TOKEN provided; using default token-based auth"
fi

#-------------------------------
# Final Exec
#-------------------------------
echo "[$(date)] Executing: $*"
exec "$@"
