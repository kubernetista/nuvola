#!/usr/bin/env bash

set -euo pipefail

# GITEA_HOSTNAME="git.localtest.me"

# Clean up the registration token and remove any trailing newline characters
GITEA_RUNNER_REGISTRATION_TOKEN=$(echo -n "$GITEA_RUNNER_REGISTRATION_TOKEN" | tr -d '\r\n')

# Debugging output
echo  "   ======"
echo "GITEA_RUNNER_NAME: ${GITEA_RUNNER_NAME}"
echo "GITEA_RUNNER_LABELS: ${GITEA_RUNNER_LABELS}"
echo "GITEA_HOSTNAME: ${GITEA_HOSTNAME}"
echo "GITEA_INSTANCE_URL: ${GITEA_INSTANCE_URL}"
echo "CONFIG_FILE: ${CONFIG_FILE}"
echo "GITEA_RUNNER_REGISTRATION_TOKEN: ${GITEA_RUNNER_REGISTRATION_TOKEN}"

echo  "   ======"
env | sort
echo  "   ======"

# Sleep random time between 2-20 seconds
SLEEP_TIME=$((RANDOM % 19 + 2))
echo "Waiting ${SLEEP_TIME} seconds before starting ${GITEA_RUNNER_NAME}..."
sleep ${SLEEP_TIME}

# # Add Docker daemon cert configuration
# DOCKER_CERT_DIR="/etc/docker/certs.d/${GITEA_HOSTNAME}"
# mkdir -pv "$DOCKER_CERT_DIR"
# cp -v /usr/share/ca-certificates/extra/${GITEA_HOSTNAME}.crt "$DOCKER_CERT_DIR/ca.crt"

# # Update system CA certificates
# # dpkg-reconfigure ca-certificates
# update-ca-certificates --fresh

# Configure git to use the custom CA certificate
git config --system http.sslCAInfo /usr/share/ca-certificates/extra/${GITEA_HOSTNAME}.crt \
 && echo "git config CA updated"


# Rest of the original run.sh script

# Create the data directory if it does not exist
if [[ ! -d /data ]]; then
  mkdir -p /data
fi

cd /data

# Set the default state file
RUNNER_STATE_FILE=${RUNNER_STATE_FILE:-'.runner'}

# Set the default configuration file
CONFIG_ARG=""
if [[ ! -z "${CONFIG_FILE}" ]]; then
  CONFIG_ARG="--config ${CONFIG_FILE}"
fi

# Set the default extra arguments
EXTRA_ARGS=""
if [[ ! -z "${GITEA_RUNNER_LABELS}" ]]; then
  EXTRA_ARGS="${EXTRA_ARGS} --labels ${GITEA_RUNNER_LABELS}"
fi

# In case no token is set, it's possible to read the token from a file, i.e. a Docker Secret
if [[ -z "${GITEA_RUNNER_REGISTRATION_TOKEN}" ]] && [[ -f "${GITEA_RUNNER_REGISTRATION_TOKEN_FILE}" ]]; then
  GITEA_RUNNER_REGISTRATION_TOKEN=$(cat "${GITEA_RUNNER_REGISTRATION_TOKEN_FILE}")
fi

# Use the same ENV variable names as https://github.com/vegardit/docker-gitea-act-runner
test -f "$RUNNER_STATE_FILE" || echo "$RUNNER_STATE_FILE is missing or not a regular file"

# Initialize the registration counter
try=0

# If the runner state file does not exist, the runner has not been registered yet
if [[ ! -s "$RUNNER_STATE_FILE" ]]; then
  try=$((try + 1))
  success=0

  # The loop will try to register the runner with gitea, and if it fails, it will wait
  # a random time between 5-30 seconds before retrying
  while [[ $success -eq 0 ]] && [[ $try -lt ${GITEA_MAX_REG_ATTEMPTS:-10} ]]; do
      ((try++))
      echo "Trying to register runner (attempt $try):"
      echo -e "  act_runner register --instance ${GITEA_INSTANCE_URL} --token ${GITEA_RUNNER_REGISTRATION_TOKEN} --name ${GITEA_RUNNER_NAME:-`hostname`} ${CONFIG_ARG} ${EXTRA_ARGS} --no-interactive\n"

      # disable exit on error to allow for retries
      set +e

      # register the runner and capture exit code
      act_runner register \
        --instance "${GITEA_INSTANCE_URL}" \
        --token    "${GITEA_RUNNER_REGISTRATION_TOKEN}" \
        --name     "${GITEA_RUNNER_NAME:-`hostname`}" \
        ${CONFIG_ARG} ${EXTRA_ARGS} --no-interactive 2>&1 | tee /tmp/reg.log

      reg_exit_code=$?
      echo "Registration exit code: ${reg_exit_code}"

      # check if the runner was registered successfully
      if grep -q 'Runner registered successfully' /tmp/reg.log; then
          echo "SUCCESS"
          success=1
      else
          SLEEP_TIME=$((RANDOM % 26 + 5))
          echo "Registration failed. Waiting ${SLEEP_TIME} seconds before retry..."
          sleep ${SLEEP_TIME}

          # Break loop if max attempts reached
          if [[ $try -ge ${GITEA_MAX_REG_ATTEMPTS:-10} ]]; then
              echo "Max registration attempts reached. Exiting..."
              exit 1
          fi
      fi
  done

fi

# Prevent reading the token from the act_runner process
unset GITEA_RUNNER_REGISTRATION_TOKEN
unset GITEA_RUNNER_REGISTRATION_TOKEN_FILE

# Daemonize the act_runner process
exec act_runner daemon ${CONFIG_ARG}
