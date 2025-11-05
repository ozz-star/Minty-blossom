#!/usr/bin/env bash
set -euo pipefail

# Helper to apply the SysRq disable from this repository.
# Usage: run this on the target Linux host from the repo root with sudo.

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root (use sudo)."
  exit 1
fi

if [ ! -f ./includes/05-local_policy.sh ]; then
  echo "Cannot find ./includes/05-local_policy.sh. Run this from the repository root." >&2
  exit 1
fi

# shellcheck disable=SC1090
source ./includes/05-local_policy.sh

echo "Applying: disable SysRq (kernel.sysrq=0)"
lp_disable_sysrq

echo "Done. Verify with: sysctl kernel.sysrq && grep -E '^\s*kernel.sysrq' /etc/sysctl.d/99-hardening.conf"
