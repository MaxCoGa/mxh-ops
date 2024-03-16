#!/bin/bash

ORGANIZATION=$ORGANIZATION
ACCESS_TOKEN=$ACCESS_TOKEN

# https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens?apiVersion=2022-11-28#organization-permissions-for-self-hosted-runners
# REG_TOKEN=$(curl -sX POST -H "Authorization: token ${ACCESS_TOKEN}" https://api.github.com/orgs/${ORGANIZATION}/actions/runners/registration-token | jq .token --raw-output)
# https://docs.github.com/en/rest/actions/self-hosted-runners?apiVersion=2022-11-28#create-a-registration-token-for-a-repository--fine-grained-access-tokens NEED administration:WRITE ON REPOS

# Fine-grained personal access tokens: https://github.com/settings/tokens
REG_TOKEN=$(curl -sX POST -H "Authorization: token ${ACCESS_TOKEN}" https://api.github.com/repos/${ORGANIZATION}/actions/runners/registration-token | jq .token --raw-output)

# Doesn't work
# curl -L \
#   -H "Accept: application/vnd.github+json" \
#   -H "Authorization: Bearer ${ACCESS_TOKEN}" \
#   -H "X-GitHub-Api-Version: 2022-11-28" \
#   "https://api.github.com/repos/${ORGANIZATION}/actions/runners/registration-token"

cd /home/docker/actions-runner

./config.sh --url https://github.com/${ORGANIZATION} --token ${REG_TOKEN} --unattended
# --name "testrunner" --labels 'self-hosted,Linux,X64' --work "_work"

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!