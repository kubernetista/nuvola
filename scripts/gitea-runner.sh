#!/usr/bin/env bash

# export RUNNER_TOKEN="<token>"
echo ${RUNNER_TOKEN}
# export RUNNER_TOKEN_B64=$(echo ${RUNNER_TOKEN} | base64)
# echo ${RUNNER_TOKEN_B64}

# Update 📋  the token in the Runner deployment
envsubst < ./gitea-runner/rootless.yaml.template > ./gitea-runner/rootless.yaml
