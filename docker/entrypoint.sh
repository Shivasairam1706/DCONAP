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

# Jupyter Password setup
if [ -z "$JUPYTER_PASSWORD" ]; then
  echo "No password set. Jupyter will use token authentication."
  exec su jupyteruser -c "$*"
else
  HASH=$(python3 -c "from notebook.auth import passwd; print(passwd('$JUPYTER_PASSWORD'))")
  mkdir -p /home/jupyteruser/.jupyter
  echo "c.NotebookApp.password = u'$HASH'" > /home/jupyteruser/.jupyter/jupyter_notebook_config.py
  exec su jupyteruser -c "$*"
fi
