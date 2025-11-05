#!/usr/bin/env bash
set -euo pipefail

# Apply conservative sysctl settings for local policies.
apply_sysctl() {
  local sudo_cmd=""
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
      sudo_cmd=sudo
    else
      echo "Error: root privileges required to apply sysctl settings." >&2
      return 1
    fi
  fi

  local -a settings=(
    "net.ipv6.conf.all.accept_ra=0"
    "net.ipv6.conf.all.accept_redirects=0"
    "net.ipv6.conf.all.accept_source_route=0"
    "net.ipv6.conf.all.forwarding=0"
    "net.ipv6.conf.default.accept_ra=0"
    "net.ipv6.conf.default.accept_redirects=0"
    "net.ipv6.conf.default.accept_source_route=0"
    "net.ipv4.conf.all.accept_redirects=0"
    "net.ipv4.conf.all.accept_source_route=0"
    "net.ipv4.conf.all.log_martians=1"
    "net.ipv4.conf.all.rp_filter=1"
    "net.ipv4.conf.all.secure_redirects=0"
    "net.ipv4.conf.all.send_redirects=0"
    "net.ipv4.conf.default.accept_redirects=0"
    "net.ipv4.conf.default.accept_source_route=0"
    "net.ipv4.conf.default.log_martians=1"
    "net.ipv4.conf.default.rp_filter=1"
    "net.ipv4.conf.default.secure_redirects=0"
    "net.ipv4.conf.default.send_redirects=0"
    "net.ipv4.icmp_echo_ignore_broadcasts=1"
    "net.ipv4.icmp_ignore_bogus_error_responses=1"
    "net.ipv4.tcp_syncookies=1"
    "net.ipv4.ip_forward=0"
    "fs.protected_hardlinks=1"
    "fs.protected_symlinks=1"
    "fs.suid_dumpable=0"
    "kernel.randomize_va_space=2"
    "kernel.sysrq=0"
  )

  for setting in "${settings[@]}"; do
    ${sudo_cmd:+$sudo_cmd }sysctl -w "$setting"
  done

  printf "%s\n" "${settings[@]}" | ${sudo_cmd:+$sudo_cmd }tee /etc/sysctl.d/99-secure.conf >/dev/null
  ${sudo_cmd:+$sudo_cmd }sysctl --system
}


# Public entrypoint for the main menu. harden.sh expects a function named
# invoke_local_policy to be defined and called when the user selects the
# "Local Policy" menu item. This file must not execute on source.
invoke_local_policy() {
  # Use config.sh-provided variables if available (config.sh is sourced by the
  # top-level script). Otherwise, fall back to /etc/os-release.
  local this_id=""
  if [ -n "${ID:-}" ]; then
    this_id="${ID,,}"
  else
    if [ -r /etc/os-release ]; then
      this_id="$(awk -F= '/^ID=/{print tolower($2)}' /etc/os-release | tr -d '"')"
    fi
  fi

  # Only run on Linux Mint
  case "${this_id}" in
    linuxmint|mint|*mint*) : ;;
    *)
      echo "[i] Skipping local policy: not running on Linux Mint (detected: ${this_id:-unknown})."
      return 0
      ;;
  esac

  echo "[+] Applying local security policy (Mint-only)..."
  apply_sysctl
  echo "[+] Done."
}

# If this file is executed directly, call the entrypoint. When sourced by the
# top-level orchestrator (harden.sh) the function will be registered and only
# run when that orchestrator calls it; this avoids applying settings at
# script bootstrap/boot-time.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  invoke_local_policy "$@"
fi
