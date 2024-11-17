# catthehacker/ubuntu:runner-latest
FROM ghcr.io/catthehacker/ubuntu:runner-latest

# Switch to root user
USER root

# Update Ubuntu to latest packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

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
