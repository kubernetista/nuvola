#!/usr/bin/env bash

# Define the list of apps to check for upgrades
app_list=(
    "argo/argo-cd"
    "argo/argo-workflows"
    "argo/argo-events"
    "external-secrets/external-secrets"
    "gitea-charts/gitea"
    "kubetail/kubetail"
    "bitnami/jenkins"
    "traefik/traefik"
    "cnpg/cloudnative-pg"
    "cnpg/cluster"
    "hashicorp/vault"
)

echo -e "\nCurrent versions of the Helm charts:\n"

# find the current version of the apps and sort the output
fd . ../../apps --maxdepth 1 | xargs rg -N -B 1 'helm:' | rg "targetRevision:"  \
    | rg "targetRevision: (.*)" -r '$1' | gsed -E 's/- /  /' | sed -e "s|../../apps/||" \
    | awk '{printf "%-30s %s\n", $1, $2}' | sort -k1,1 | awk '{if ($1 ~ /\.OFF$/) {off[NR]=$0} else {print}} END {for (i in off) print off[i]}'

echo -e "\nUpdating Helm repos..."
helm repo update > /dev/null

echo -e "Verifying the latest versions of the apps Helm charts..."

# find the latest versions of the apps
output=""
for app in "${app_list[@]}"; do
  output+=$(helm search repo "$app" --versions | head -n 3 | tail -n +2)
  output+=$'\n'
done

echo -e "\nLatest 2 versions of the Helm charts for each app:\n"

# Add the header
header="NAME\tCHART VERSION\tAPP VERSION\tDESCRIPTION"
# Print the output in a table format
echo -e "$header\n$output" | column -s $'\t' -t
