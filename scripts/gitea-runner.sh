#!/usr/bin/env bash

# export RUNNER_TOKEN="<token>"
echo "Gitea Runner Token: ${RUNNER_TOKEN}"
export RUNNER_TOKEN_B64=$(echo ${RUNNER_TOKEN} | base64)
echo -e "Gitea Runner Token base64: ${RUNNER_TOKEN_B64}\n"

RUNNER_DIR="gitea-runner"
RUNNER_DEPOLYMENT="deploy-rootless.yaml"
RUNNER_DEPOLYMENT_DIND="deploy-dind.yaml"


# Update 📋  the token in the Runner deployment

if [ -f "./${RUNNER_DIR}/${RUNNER_DEPOLYMENT}.template" ]; then
    envsubst < ./${RUNNER_DIR}/${RUNNER_DEPOLYMENT}.template     > ./${RUNNER_DIR}/${RUNNER_DEPOLYMENT}
else
  echo "File ./${RUNNER_DIR}/${RUNNER_DEPOLYMENT}.template does not exist."
fi

if [ -f "./${RUNNER_DIR}/${RUNNER_DEPOLYMENT_DIND}.template" ]; then
    envsubst < ./${RUNNER_DIR}/${RUNNER_DEPOLYMENT_DIND}.template     > ./${RUNNER_DIR}/${RUNNER_DEPOLYMENT_DIND}
else
  echo "File ./${RUNNER_DIR}/${RUNNER_DEPOLYMENT_DIND}.template does not exist."
fi

envsubst < ./${RUNNER_DIR}/secret-runner-token.yaml.template > ./${RUNNER_DIR}/secret-runner-token.yaml
