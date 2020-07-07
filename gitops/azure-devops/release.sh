#!/usr/bin/env bash

# shellcheck disable=SC1091
. build.sh --source-only

# Initialization
verify_access_token
init
helm init
get_os

# Fabrikate
get_fab_version
download_fab

# Clone HLD repo
git_connect

if [[ -n $FAB_ENV_NAME ]]
then
    echo "fab set --environment "$FAB_ENV_NAME" --subcomponent "$SUBCOMPONENT" "$YAML_PATH=$YAML_PATH_VALUE""
    fab set --environment "$FAB_ENV_NAME" --subcomponent "$SUBCOMPONENT" "$YAML_PATH=$YAML_PATH_VALUE"
else
    echo "fab set --subcomponent "$SUBCOMPONENT" "$YAML_PATH=$YAML_PATH_VALUE""
    fab set --subcomponent "$SUBCOMPONENT" "$YAML_PATH=$YAML_PATH_VALUE"
fi
if [ $? -ne 0 ]; then
    exit 1;
fi

echo "GIT STATUS"
git status

echo "GIT ADD"
git add -A

# Set git identity
git config user.email "admin@azuredevops.com"
git config user.name "Automated Account"

echo "GIT COMMIT"
git commit -m "$COMMIT_MESSAGE"

echo "GIT PUSH"
git_push
