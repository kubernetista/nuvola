# catthehacker/ubuntu:runner-latest
FROM ghcr.io/catthehacker/ubuntu:runner-latest

# ARG GITEA_HOSTNAME="git.localtest.me"

# Switch to root user
USER root

# Update Ubuntu to latest packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create directories for certificates
RUN mkdir -p /usr/share/ca-certificates/extra \
    && mkdir -p /etc/docker/certs.d/git.localtest.me

# Copy and install custom CA certificate
COPY ./git.localtest.me.crt /usr/share/ca-certificates/extra/
RUN echo "extra/git.localtest.me.crt" >> /etc/ca-certificates.conf \
    && update-ca-certificates

# Configure Docker to trust the certificate
RUN cp /usr/share/ca-certificates/extra/git.localtest.me.crt \
    /etc/docker/certs.d/git.localtest.me/ca.crt

# Add run.sh
COPY ./run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

# Add Tini
ENV TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/sbin/tini
RUN chmod +x /usr/sbin/tini

# Add act_runner
COPY --from=gitea/act_runner:nightly  /usr/local/bin/act_runner /usr/local/bin/act_runner

# # Install necessary packages and clean up
# RUN apt-get update && \
#     apt-get install -y --no-install-recommends \
#     curl \
#     git \
#     && apt-get clean && \
#     rm -rf /var/lib/apt/lists/*

# # Install buildah
# RUN apt-get update && \
#     apt-get upgrade -y && \
#     apt-get install -y --no-install-recommends \
#     buildah \
#     && apt-get clean && \
#     rm -rf /var/lib/apt/lists/*

# Switch back to a non-root user (if necessary)
# USER runner

# Clean up Entrypoint
ENTRYPOINT []

# Replace Entrypoint with CMD
CMD ["/sbin/tini","--","run.sh"]
