#!/bin/bash
set -e

# Fetch AWS credentials from Secrets Manager if secret name is set
if [ -n "$AWS_SECRET_NAME" ]; then
  echo "Fetching AWS credentials..."
  if ! command -v aws &>/dev/null; then
    echo "AWS CLI not found. Exiting."
    exit 1
  fi

  if ! command -v jq &>/dev/null; then
    echo "jq not found. Exiting."
    exit 1
  fi

  CREDS=$(aws secretsmanager get-secret-value --secret-id "$AWS_SECRET_NAME" --query 'SecretString' --output text)
  export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | jq -r '.AWS_ACCESS_KEY_ID')
  export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r '.AWS_SECRET_ACCESS_KEY')
fi

# Change ownership of the mounted volume
if [ -d "$JUPYTER_MOUNT_PATH" ]; then
  echo "Changing ownership of $JUPYTER_MOUNT_PATH to UID:$UID GID:$GID"
  chown -R "$UID":"$GID" "$JUPYTER_MOUNT_PATH"
fi

# JupyterLab password setup
if [ -z "$JUPYTER_PASSWORD" ]; then
  echo "JUPYTER_PASSWORD environment variable not set. Using token-based authentication."
else
  echo "JUPYTER_PASSWORD is set. Enabling password authentication for JupyterLab."

  # Check if jupyter_server.auth is available
  if ! python3 -c "import jupyter_server.auth" &>/dev/null; then
    echo "Error: jupyter_server.auth module not found. Please install jupyterlab properly."
    exit 1
  fi

  HASH=$(python3 -c "from jupyter_server.auth import passwd; print(passwd('$JUPYTER_PASSWORD'))")
  mkdir -p /home/jupyteruser/.jupyter
  echo "c.ServerApp.password = u'$HASH'" > /home/jupyteruser/.jupyter/jupyter_server_config.py
fi

# Start JupyterLab as the jupyteruser
exec su jupyteruser -c "$@"
