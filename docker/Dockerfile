FROM python:3.9

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    tini default-jre jq curl awscli && \
    rm -rf /var/lib/apt/lists/*

# Install Python packages
COPY requirements.txt /tmp/requirements.txt
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# User configuration
ARG UID=1000
ARG GID=1000
ENV UID=${UID}
ENV GID=${GID}

# Create a non-root user
RUN addgroup --gid ${GID} jupytergroup && \
    useradd -ms /bin/bash -u ${UID} -g jupytergroup jupyteruser

# Set working directory
RUN mkdir -p /home/jupyteruser/work && \
    chown -R ${UID}:${GID} /home/jupyteruser/work
WORKDIR /home/jupyteruser

# Copy baseline project files
COPY --chown=jupyteruser:jupytergroup ../baseline/ /home/jupyteruser/work/

# Optional: Install Hadoop if arguments are passed
ARG HADOOP_VERSION
ARG HADOOP_URL
RUN if [ -n "$HADOOP_VERSION" ] && [ -n "$HADOOP_URL" ]; then \
    curl -L -q "$HADOOP_URL" -o hadoop.tar.gz && \
    tar -xzf hadoop.tar.gz && \
    mkdir -p /home/jupyteruser/hadoop && \
    mv hadoop-${HADOOP_VERSION} /home/jupyteruser/hadoop && \
    rm hadoop.tar.gz && \
    echo "export PATH=\$PATH:/home/jupyteruser/hadoop/bin" >> /home/jupyteruser/.bashrc; \
    fi

# Entrypoint setup
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8888
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/local/bin/jupyter-lab", "--ip=0.0.0.0", "--port=8888", "--no-browser"]
