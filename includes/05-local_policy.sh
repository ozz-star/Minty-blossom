#!/usr/bin/env bash
set -euo pipefail

invoke_local_policy () {
  echo -e "${CYAN}[Local Policy] Start${NC}"

  lp_sysctl_ipv6_all
  lp_sysctl_ipv6_default
  lp_sysctl_ipv4_all
  lp_sysctl_ipv4_default
  lp_sysctl_ipv4_misc
  lp_sysctl_fs_kernel
  lp_sysctl_persist_and_reload
  lp_secure_sudo

  echo -e "${CYAN}[Local Policy] Done${NC}"
}

# -------------------------------------------------------------------
# IPv6 sysctl (all interfaces)
# -------------------------------------------------------------------
lp_sysctl_ipv6_all () {
  : <<'AI_BLOCK'
// ...existing code...
# -------------------------------------------------------------------
# IPv6 sysctl (all interfaces)
# -------------------------------------------------------------------
lp_sysctl_ipv6_all () {
  declare -A settings=(
    ["net.ipv6.conf.all.accept_ra"]=0
    ["net.ipv6.conf.all.accept_redirects"]=0
    ["net.ipv6.conf.all.accept_source_route"]=0
    ["net.ipv6.conf.all.forwarding"]=0
  )

  for key in "${!settings[@]}"; do
    value=${settings[$key]}
    if sudo sysctl -w "${key}=${value}" >/dev/null 2>&1; then
      echo "Set sysctl (runtime): ${key}=${value}"
    else
      echo "Warning: Failed to set sysctl (runtime): ${key}=${value}" >&2
    fi
  done

  return 0
}

# -------------------------------------------------------------------
# IPv6 sysctl (default interface template)
# -------------------------------------------------------------------
lp_sysctl_ipv6_default () {
AI_BLOCK
}

# -------------------------------------------------------------------
# IPv6 sysctl (default interface template)
# -------------------------------------------------------------------
lp_sysctl_ipv6_default () {
  : <<'AI_BLOCK'
// ...existing code...
# -------------------------------------------------------------------
# IPv6 sysctl (default interface template)
# -------------------------------------------------------------------
lp_sysctl_ipv6_default () {
  declare -A settings=(
    ["net.ipv6.conf.default.accept_ra"]=0
    ["net.ipv6.conf.default.accept_redirects"]=0
    ["net.ipv6.conf.default.accept_source_route"]=0
  )

  for key in "${!settings[@]}"; do
    value=${settings[$key]}
    if sudo sysctl -w "${key}=${value}" >/dev/null 2>&1; then
      echo "Set sysctl (runtime): ${key}=${value}"
    else
      echo "Warning: Failed to set sysctl (runtime): ${key}=${value}" >&2
    fi
  done

  return 0
}

# -------------------------------------------------------------------
# IPv4 sysctl (all interfaces)
# -------------------------------------------------------------------
// ...existing code...
AI_BLOCK
}

# -------------------------------------------------------------------
# IPv4 sysctl (all interfaces)
# -------------------------------------------------------------------
lp_sysctl_ipv4_all () {
  : <<'AI_BLOCK'
// ...existing code...
# -------------------------------------------------------------------
# IPv4 sysctl (all interfaces)
# -------------------------------------------------------------------
lp_sysctl_ipv4_all () {
  declare -A settings=(
    ["net.ipv4.conf.all.accept_redirects"]=0
    ["net.ipv4.conf.all.accept_source_route"]=0
    ["net.ipv4.conf.all.log_martians"]=1
    ["net.ipv4.conf.all.rp_filter"]=1
    ["net.ipv4.conf.all.secure_redirects"]=0
    ["net.ipv4.conf.all.send_redirects"]=0
  )

  for key in "${!settings[@]}"; do
    value=${settings[$key]}
    if sudo sysctl -w "${key}=${value}" >/dev/null 2>&1; then
      echo "Set sysctl (runtime): ${key}=${value}"
    else
      echo "Warning: Failed to set sysctl (runtime): ${key}=${value}" >&2
    fi
  done

  return 0
}

# -------------------------------------------------------------------
# IPv4 sysctl (default interface template)
# -------------------------------------------------------------------
lp_sysctl_ipv4_default () {
AI_BLOCK
}

# -------------------------------------------------------------------
# IPv4 sysctl (default interface template)
# -------------------------------------------------------------------
lp_sysctl_ipv4_default () {
  : <<'AI_BLOCK'
// ...existing code...
# -------------------------------------------------------------------
# IPv4 sysctl (default interface template)
# -------------------------------------------------------------------
lp_sysctl_ipv4_default () {
  declare -A settings=(
    ["net.ipv4.conf.default.accept_redirects"]=0
    ["net.ipv4.conf.default.accept_source_route"]=0
    ["net.ipv4.conf.default.log_martians"]=1
    ["net.ipv4.conf.default.rp_filter"]=1
    ["net.ipv4.conf.default.secure_redirects"]=0
    ["net.ipv4.conf.default.send_redirects"]=0
  )

  for key in "${!settings[@]}"; do
    value=${settings[$key]}
    if sudo sysctl -w "${key}=${value}" >/dev/null 2>&1; then
      echo "Set sysctl (runtime): ${key}=${value}"
    else
      echo "Warning: Failed to set sysctl (runtime): ${key}=${value}" >&2
    fi
  done

  return 0
}

# -------------------------------------------------------------------
# IPv4 misc (ICMP, TCP, forwarding)
# -------------------------------------------------------------------
lp_sysctl_ipv4_misc () {
AI_BLOCK
}

# -------------------------------------------------------------------
# IPv4 misc (ICMP, TCP, forwarding)
# -------------------------------------------------------------------
lp_sysctl_ipv4_misc () {
  : <<'AI_BLOCK'
// ...existing code...
# -------------------------------------------------------------------
# IPv4 misc (ICMP, TCP, forwarding)
# -------------------------------------------------------------------
lp_sysctl_ipv4_misc () {
  declare -A settings=(
    ["net.ipv4.icmp_echo_ignore_broadcasts"]=1
    ["net.ipv4.icmp_ignore_bogus_error_responses"]=1
    ["net.ipv4.tcp_syncookies"]=1
    ["net.ipv4.ip_forward"]=0
  )

  for key in "${!settings[@]}"; do
    value=${settings[$key]}
    if sudo sysctl -w "${key}=${value}" >/dev/null 2>&1; then
      echo "Set sysctl (runtime): ${key}=${value}"
    else
      echo "Warning: Failed to set sysctl (runtime): ${key}=${value}" >&2
    fi
  done

  return 0
}

# -------------------------------------------------------------------
# Filesystem & kernel hardening
# -------------------------------------------------------------------
lp_sysctl_fs_kernel () {
AI_BLOCK
}

# -------------------------------------------------------------------
# Filesystem & kernel hardening
# -------------------------------------------------------------------
lp_sysctl_fs_kernel () {
// ...existing code...
# -------------------------------------------------------------------
# Filesystem & kernel hardening
# -------------------------------------------------------------------
lp_sysctl_fs_kernel () {
  declare -A settings=(
    ["fs.protected_hardlinks"]=1
    ["fs.protected_symlinks"]=1
    ["fs.suid_dumpable"]=0
    ["kernel.randomize_va_space"]=2
  )

  for key in "${!settings[@]}"; do
    value=${settings[$key]}
    if sudo sysctl -w "${key}=${value}" >/dev/null 2>&1; then
      echo "Set sysctl (runtime): ${key}=${value}"
    else
      echo "Warning: Failed to set sysctl (runtime): ${key}=${value}" >&2
    fi
  done

  return 0
}

# -------------------------------------------------------------------
# Persist sysctl settings and reload
# -------------------------------------------------------------------
// ...existing code...
AI_BLOCK
}

# -------------------------------------------------------------------
# Persist sysctl settings and reload
# -------------------------------------------------------------------
lp_sysctl_persist_and_reload () {
  : 
// ...existing code...
# -------------------------------------------------------------------
# Persist sysctl settings and reload
# -------------------------------------------------------------------
lp_sysctl_persist_and_reload () {
  local target="/etc/sysctl.d/99-hardening.conf"
  local temp_file
  temp_file=$(mktemp)

  # Aggregate all settings into one array
  declare -A all_settings=(
    ["net.ipv6.conf.all.accept_ra"]=0
    ["net.ipv6.conf.all.accept_redirects"]=0
    ["net.ipv6.conf.all.accept_source_route"]=0
    ["net.ipv6.conf.all.forwarding"]=0
    ["net.ipv6.conf.default.accept_ra"]=0
    ["net.ipv6.conf.default.accept_redirects"]=0
    ["net.ipv6.conf.default.accept_source_route"]=0
    ["net.ipv4.conf.all.accept_redirects"]=0
    ["net.ipv4.conf.all.accept_source_route"]=0
    ["net.ipv4.conf.all.log_martians"]=1
    ["net.ipv4.conf.all.rp_filter"]=1
    ["net.ipv4.conf.all.secure_redirects"]=0
    ["net.ipv4.conf.all.send_redirects"]=0
    ["net.ipv4.conf.default.accept_redirects"]=0
    ["net.ipv4.conf.default.accept_source_route"]=0
    ["net.ipv4.conf.default.log_martians"]=1
    ["net.ipv4.conf.default.rp_filter"]=1
    ["net.ipv4.conf.default.secure_redirects"]=0
    ["net.ipv4.conf.default.send_redirects"]=0
    ["net.ipv4.icmp_echo_ignore_broadcasts"]=1
    ["net.ipv4.icmp_ignore_bogus_error_responses"]=1
    ["net.ipv4.tcp_syncookies"]=1
    ["net.ipv4.ip_forward"]=0
    ["fs.protected_hardlinks"]=1
    ["fs.protected_symlinks"]=1
    ["fs.suid_dumpable"]=0
    ["kernel.randomize_va_space"]=2
  )

  # Create a timestamped backup if the file exists
  if [ -f "$target" ]; then
    local ts
    ts=$(date +%Y%m%d%H%M%S)
    sudo cp -a "$target" "${target}.bak.${ts}"
    echo "Created backup: ${target}.bak.${ts}"
  fi

  # Write all settings to a temporary file to ensure atomicity and idempotency
  {
    echo "# Hardening settings applied by script"
    for key in "${!all_settings[@]}"; do
      echo "${key} = ${all_settings[$key]}"
    done
  } > "$temp_file"

  # Overwrite the target file with the new settings
  sudo mv "$temp_file" "$target"
  sudo chown root:root "$target"
  sudo chmod 0644 "$target"
  echo "Wrote ${#all_settings[@]} hardening settings to $target"

  # Reload all sysctl configuration files
  if sudo sysctl --system >/dev/null 2>&1; then
    echo "Reloaded sysctl settings from all configuration files."
  else
    echo "Warning: Failed to reload sysctl settings." >&2
    return 1
  fi

  return 0
}

# -------------------------------------------------------------------
# Secure sudo (dangerous if misused; stub only)
# -------------------------------------------------------------------
// ...existing code...

# -------------------------------------------------------------------
# Secure sudo (dangerous if misused; stub only)
# -------------------------------------------------------------------
lp_secure_sudo () {
// ...existing code...
lp_secure_sudo () {
  set +e

  __as_root() {
    if [ "$(id -u)" -eq 0 ]; then
      "$@"
    elif command -v sudo >/dev/null 2>&1; then
      sudo "$@"
    else
      return 126
    fi
  }

  # 1) Remove files under /etc/sudoers.d (keep /etc/sudoers)
  if __as_root bash -c 'if [ -d /etc/sudoers.d ]; then find /etc/sudoers.d -mindepth 1 -type f -print -delete; else exit 2; fi'; then
    echo "Removed files under /etc/sudoers.d (kept /etc/sudoers)."
  else
    case $? in
      2) echo "Warning: /etc/sudoers.d not found; nothing to remove." >&2 ;;
      126) echo "Warning: Need root privileges to modify /etc/sudoers.d." >&2 ;;
      *) echo "Warning: Failed to remove some files under /etc/sudoers.d." >&2 ;;
    esac
  fi

  # 2) Purge sudo package non-interactively
  if __as_root env DEBIAN_FRONTEND=noninteractive apt-get -y purge sudo >/dev/null 2>&1; then
    echo "Purged sudo package."
  else
    echo "Warning: Failed to purge sudo package." >&2
  fi

  # 3) Install sudo again non-interactively
  if __as_root env DEBIAN_FRONTEND=noninteractive apt-get -y install sudo >/dev/null 2>&1; then
    echo "Installed sudo package."
  else
    echo "Warning: Failed to install sudo package." >&2
  fi

  set -e
  return 0
}
// ...existing code...