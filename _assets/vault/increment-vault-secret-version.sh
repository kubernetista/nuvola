#!/usr/bin/env bash

# Increment the secret version in Vault

SECRET_NAME="fake-db-credentials"
SECRET_URL="test.example.com"
SECRET_USER="test-username"
SECRET_PASS="test-password"

# Load the index from the .env file if it exists
if [ -f .env ]; then
  source .env
  INDEX=${INDEX:-1}
else
  INDEX=0
fi

# Increment the index
INDEX=$((INDEX + 1))

# echo "INDEX=$INDEX"

PREFIX=$(printf "%02d-" $INDEX)
echo "PREFIX: $PREFIX"

vault kv put secret/${SECRET_NAME} url="https://${PREFIX}${SECRET_URL}" username="${PREFIX}${SECRET_USER}" password="${PREFIX}${SECRET_PASS}"

# Save the new index to the .env file
echo "INDEX=$INDEX" > .env
