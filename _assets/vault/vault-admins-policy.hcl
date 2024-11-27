# admin-policy.hcl
# Root-like policy for admin users

# Manage auth methods broadly across Vault
path "auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create, update, and delete auth methods
path "sys/auth/*"
{
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth"
{
  capabilities = ["read"]
}

# Manage secrets engines
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secrets engines.
path "sys/mounts"
{
  capabilities = ["read"]
}

# Manage policies
path "sys/policies/acl/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage secrets
path "secret/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage KV v2 secrets
path "secret/data/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage KV v2 metadata
path "secret/metadata/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# System health and capabilities
path "sys/health"
{
  capabilities = ["read", "sudo"]
}

# Manage tokens
path "auth/token/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}