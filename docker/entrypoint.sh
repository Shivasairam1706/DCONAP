#!/bin/bash

# Get AWS credentials from Secrets Manager (or use IAM role if on ECS)
if [ -n "$AWS_SECRET_NAME" ]; then  # Check if secret name is set
    aws --version # Check if aws cli is installed in docker
    aws secretsmanager get-secret-value --secret-id "$AWS_SECRET_NAME" --query 'SecretString' --output text | jq -r . | jq -r '.AWS_ACCESS_KEY_ID' > /tmp/aws_access_key_id
    aws secretsmanager get-secret-value --secret-id "$AWS_SECRET_NAME" --query 'SecretString' --output text | jq -r . | jq -r '.AWS_SECRET_ACCESS_KEY' > /tmp/aws_secret_access_key
    export AWS_ACCESS_KEY_ID=$(cat /tmp/aws_access_key_id)
    export AWS_SECRET_ACCESS_KEY=$(cat /tmp/aws_secret_access_key)
    rm /tmp/aws_access_key_id
    rm /tmp/aws_secret_access_key
fi

# Change ownership of the mounted volume's target directory if it exists
if [ -d "$JUPYTER_MOUNT_PATH" ]; then
  chown -R $UID:$GID "$JUPYTER_MOUNT_PATH"
fi

# Check if the password environment variable is set
if [ -z "$JUPYTER_PASSWORD" ]; then
  echo "JUPYTER_PASSWORD environment variable not set. Using token-based authentication."
  exec "$@"  # Execute the original CMD (JupyterLab with no password)
else
  # Generate the password hash and start JupyterLab
  jupyter server password "$JUPYTER_PASSWORD"
  exec "$@"  # Execute the original CMD (JupyterLab with password)
fi