FROM python:3.9

# Install system dependencies and tini
RUN apt-get update && apt-get install -y --no-install-recommends adduser tini default-jre jq curl && rm -rf /var/lib/apt/lists/*

# Install Python packages (multi-stage build for optimization - RECOMMENDED)
COPY docker/requirements.txt /tmp/
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r /tmp/requirements.txt
RUN rm /tmp/requirements.txt

# Get UID and GID from build arguments
ARG UID=1000
ARG GID=1000
ENV UID=${UID}
ENV GID=${GID}

# Create the group and user
RUN addgroup --gid ${GID} jupytergroup
RUN useradd -ms /bin/bash -u ${UID} -g jupytergroup jupyteruser

# Switch to the non-root user
USER jupyteruser

# Set working directory
WORKDIR /home/jupyteruser

# Copy code and set ownership
COPY --chown=jupyteruser:jupytergroup baseline/ /home/jupyteruser/work/

# Expose port
EXPOSE 8888

# Volume mount
ARG JUPYTER_MOUNT_PATH
VOLUME $JUPYTER_MOUNT_PATH:/home/jupyteruser/work

# Copy entrypoint script and make it executable
COPY --chown=jupyteruser:jupytergroup docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Install Hadoop (using curl - recommended)
ARG HADOOP_VERSION=3.3.6
ARG HADOOP_URL=https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz

RUN curl -L -q "$HADOOP_URL" -o hadoop.tar.gz && tar -xzf hadoop.tar.gz && mkdir /home/jupyteruser/hadoop && mv hadoop-${HADOOP_VERSION} /home/jupyteruser/hadoop && rm hadoop.tar.gz
# Set PATH in .bashrc (more persistent)
USER jupyteruser
# Important: Set PATH for the user
RUN echo "export PATH=$PATH:/home/jupyteruser/hadoop/bin" >> /home/jupyteruser/.bashrc
RUN chown jupyteruser:jupytergroup /home/jupyteruser/.bashrc    


# Start JupyterLab (using the entrypoint script)
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/local/bin/jupyter-lab", "--ip=0.0.0.0", "--port=8888", "--no-browser"]