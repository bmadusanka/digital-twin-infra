#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Terragrunt OIDC Auth Provider for GitHub Actions
#
# Outputs JSON in the schema expected by Terragrunt's --auth-provider-cmd.
# This version uses the "awsRole" mode — Terragrunt will perform the
# sts:AssumeRoleWithWebIdentity call itself using the GitHub OIDC token.
#
# Usage:
#   ./auth-provider.sh <ASSUME_ROLE_ARN> <AWS_REGION> <ASSUME_SESSION_NAME> [ASSUME_SESSION_DURATION]
# Example:
#   ./auth-provider.sh arn:aws:iam::123456789012:role/github-oidc-role us-east-1 github-actions-terragrunt 900
# ------------------------------------------------------------------------------

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Input validation
# ------------------------------------------------------------------------------
ASSUME_ROLE_ARN="${1:-}"
AWS_REGION="${2:-}"
ASSUME_SESSION_NAME="${3:-}"
ASSUME_SESSION_DURATION="${4:-3600}"

if [[ -z "$ASSUME_ROLE_ARN" || -z "$AWS_REGION" || -z "$ASSUME_SESSION_NAME" ]]; then
  echo "Usage: $0 <ASSUME_ROLE_ARN> <AWS_REGION> <ASSUME_SESSION_NAME> [ASSUME_SESSION_DURATION]" >&2
  echo
  echo "Error: Missing required arguments." >&2
  echo "  ASSUME_ROLE_ARN        - The IAM role ARN to assume (required)" >&2
  echo "  AWS_REGION             - The AWS region (required)" >&2
  echo "  ASSUME_SESSION_NAME    - The session name for STS (required)" >&2
  echo "  ASSUME_SESSION_DURATION - The session duration in seconds (optional, default: 3600)" >&2
  exit 1
fi

# ------------------------------------------------------------------------------
# 2. Fetch GitHub OIDC token (requires permissions: id-token: write)
# ------------------------------------------------------------------------------
if [[ -z "${ACTIONS_ID_TOKEN_REQUEST_URL:-}" || -z "${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}" ]]; then
  echo "Missing GitHub OIDC env vars. Ensure 'permissions: id-token: write' in workflow." >&2
  exit 1
fi

OIDC_TOKEN="$(curl -sSf \
  -H "Authorization: Bearer ${ACTIONS_ID_TOKEN_REQUEST_TOKEN}" \
  "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=sts.amazonaws.com" \
  | jq -r '.value')"

if [[ -z "$OIDC_TOKEN" || "$OIDC_TOKEN" == "null" ]]; then
  echo "Failed to retrieve OIDC token from GitHub." >&2
  exit 1
fi

# ------------------------------------------------------------------------------
# 3. Output JSON for Terragrunt (awsRole mode)
# ------------------------------------------------------------------------------
cat <<EOF
{
  "awsRole": {
    "roleARN": "${ASSUME_ROLE_ARN}",
    "sessionName": "${ASSUME_SESSION_NAME}",
    "duration": ${ASSUME_SESSION_DURATION},
    "webIdentityToken": "${OIDC_TOKEN}"
  },
  "envs": {
    "AWS_REGION": "${AWS_REGION}"
  }
}
EOF
