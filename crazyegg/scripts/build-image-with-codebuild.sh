#!/usr/bin/env bash

set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-localstack}"
BRANCH_NAME="${BRANCH_NAME:-crazyegg}"
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-173509387151}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command aws

echo "Starting CodeBuild project '${PROJECT_NAME}' for branch '${BRANCH_NAME}'..." >&2

build_id="$(
  aws codebuild start-build \
    --project-name "${PROJECT_NAME}" \
    --source-version "refs/heads/${BRANCH_NAME}" \
    --region "${AWS_REGION}" \
    --query 'build.id' \
    --output text
)"

if [ -z "${build_id}" ] || [ "${build_id}" = "None" ]; then
  echo "Failed to start CodeBuild project '${PROJECT_NAME}'." >&2
  exit 1
fi

encoded_build_id="${build_id//:/%3A}"
build_url="https://${AWS_REGION}.console.aws.amazon.com/codesuite/codebuild/${AWS_ACCOUNT_ID}/projects/${PROJECT_NAME}/build/${encoded_build_id}/?region=${AWS_REGION}"

echo "${build_url}"

if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "${build_url}" >/dev/null 2>&1 &
elif command -v open >/dev/null 2>&1; then
  open "${build_url}" >/dev/null 2>&1 &
fi