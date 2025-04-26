########################################
# Stage 1: builder
########################################
ARG PYTHON_IMAGE=python:3.9-slim
FROM ${PYTHON_IMAGE} AS builder

# Build-time arguments (can override from CLI or Compose)
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG VENV_PATH=/opt/venv
ARG REQUIREMENTS_FILE=requirements.txt

# Install system deps for building and tini/jq
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    tini \
    jq \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create the jupyter group & user
RUN addgroup --gid ${GROUP_ID} jupytergroup \
    && useradd -ms /bin/bash -u ${USER_ID} -g jupytergroup jupyteruser

# Create a virtualenv & install Python deps
WORKDIR ${VENV_PATH}
RUN python3 -m venv . \
    && . bin/activate \
    && pip install --upgrade pip

COPY ${REQUIREMENTS_FILE} /tmp/
RUN . ${VENV_PATH}/bin/activate \
    && pip install --no-cache-dir -r /tmp/${REQUIREMENTS_FILE}


########################################
# Stage 2: runtime
########################################
ARG PYTHON_IMAGE=python:3.9-slim
FROM ${PYTHON_IMAGE} AS runtime

# Re-declare args in this stage
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG VENV_PATH=/opt/venv
ARG JUPYTER_WORKSPACE_DIR=/home/jupyteruser/work
ARG JUPYTER_PORT=8888

# Install minimal runtime deps
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    tini \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Copy over the venv from builder
COPY --from=builder ${VENV_PATH} ${VENV_PATH}

# Create jupyter user again
RUN addgroup --gid ${GROUP_ID} jupytergroup \
    && useradd -ms /bin/bash -u ${USER_ID} -g jupytergroup jupyteruser

# Grant passwordless sudo for su only
RUN mkdir -p /etc/sudoers.d \
    && usermod -aG sudo jupyteruser \
    && echo "jupyteruser ALL=(ALL) NOPASSWD: /usr/bin/su" > /etc/sudoers.d/jupyteruser-su \
    && chmod 0440 /etc/sudoers.d/jupyteruser-su

# Switch to non-root
USER jupyteruser
WORKDIR ${JUPYTER_WORKSPACE_DIR}

# Ensure our venv is first on PATH
ENV PATH="${VENV_PATH}/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    JUPYTER_PORT=${JUPYTER_PORT} \
    JUPYTER_WORKSPACE_DIR=${JUPYTER_WORKSPACE_DIR}

# Copy entrypoint and baseline code
COPY --chown=jupyteruser:jupytergroup entrypoint.sh /entrypoint.sh
COPY --chown=jupyteruser:jupytergroup ./baseline ${JUPYTER_WORKSPACE_DIR}

RUN chmod +x /entrypoint.sh

EXPOSE ${JUPYTER_PORT}

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
CMD jupyter-lab --ip=0.0.0.0 --port=${JUPYTER_PORT} --no-browser

# --- Logging ---
# All application logs (Jupyter, AWS fetch, etc.) go to stdout/stderr by default.
# You can mount a host directory to capture logs if needed:
#    docker run -v /host/logs:/home/jupyteruser/work/logs ...
