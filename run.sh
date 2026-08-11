#!/bin/bash

# $0-run.sh, $1-dev/prod, $2- apply/destroy
# 2 arguments are expected for env and action. if it is not provided
# $# - counts the number of arguments provided. 
# if the cli argument input is not 2, then print the below.

set -e

# Execution command: run.sh <dev or prod> <apply or destroy> "

if [ $# -ne 2 ]; then
  echo "Use $0 env(dev|prod) action(apply|destroy)"
  exit 1
fi

ENV="$1"
ACTION="$2"

if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
    echo "Environment must be dev or prod"
    exit 1
fi

if [[ "$ACTION" != "apply" && "$ACTION" != "destroy" ]]; then
    echo "Action must be apply or destroy"
    exit 1
fi

git pull
rm -rf .terraform
terraform init -backend-config=env-"${ENV}"/state.tfvars
terraform "$ACTION" \
  -var-file=env-"${ENV}"/main.tfvars \
  -auto-approve

