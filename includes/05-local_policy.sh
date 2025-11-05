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
  # Explicitly ensure SysRq is disabled on runtime and persisted
  lp_disable_sysrq
  # Ensure ASLR (Address Space Layout Randomization) is enabled at runtime and persisted
  lp_enable_aslr
  lp_sysctl_persist_and_reload
  lp_secure_sudo

  echo -e "${CYAN}[Local Policy] Done${NC}"
}

# -------------------------------------------------------------------
# IPv6 sysctl (all interfaces)
# -------------------------------------------------------------------
lp_sysctl_ipv6_all () {
  local -a settings=(
    "net.ipv6.conf.all.accept_source_route=0"
    "net.ipv6.conf.all.forwarding=0"
  )
  local item key val
    # Ensure SysRq disabled at runtime and persisted
    lp_disable_sysrq
  for item in "${settings[@]}"; do
    key="${item%%=*}"
    val="${item#*=}"
    if sysctl -w "$key=$val" >/dev/null 2>&1; then
      echo "set $key=$val"
    else
      echo "failed $key=$val" >&2
    fi
  done
}

# -------------------------------------------------------------------
# IPv6 sysctl (default interface template)
# -------------------------------------------------------------------
lp_sysctl_ipv6_default () {
  local -a settings=(
    "net.ipv6.conf.default.accept_ra=0"
    "net.ipv6.conf.default.accept_redirects=0"
    "net.ipv6.conf.default.accept_source_route=0"
  )
  local item key val
  for item in "${settings[@]}"; do
    key="${item%%=*}"
    val="${item#*=}"
    if sysctl -w "$key=$val" >/dev/null 2>&1; then
      echo "set $key=$val"
    else
      echo "failed $key=$val" >&2
    fi
  done
}

# -------------------------------------------------------------------
# IPv4 sysctl (all interfaces)
# -------------------------------------------------------------------
lp_sysctl_ipv4_all () {
  local -a settings=(
    "net.ipv4.conf.all.accept_redirects=0"
    "net.ipv4.conf.all.accept_source_route=0"
    "net.ipv4.conf.all.log_martians=1"
    "net.ipv4.conf.all.rp_filter=1"
    "net.ipv4.conf.all.secure_redirects=0"
    "net.ipv4.conf.all.send_redirects=0"
  )
  local item key val
  for item in "${settings[@]}"; do
    key="${item%%=*}"
    val="${item#*=}"
    if sysctl -w "$key=$val" >/dev/null 2>&1; then
      echo "set $key=$val"
    else
      echo "failed $key=$val" >&2
    fi
  done
}

# -------------------------------------------------------------------
# IPv4 sysctl (default interface template)
# -------------------------------------------------------------------
lp_sysctl_ipv4_default () {
  local -a settings=(
    "net.ipv4.conf.default.accept_redirects=0"
    "net.ipv4.conf.default.accept_source_route=0"
    "net.ipv4.conf.default.log_martians=1"
    "net.ipv4.conf.default.rp_filter=1"
    "net.ipv4.conf.default.secure_redirects=0"
    "net.ipv4.conf.default.send_redirects=0"
  )
  local item key val
  for item in "${settings[@]}"; do
    key="${item%%=*}"
    val="${item#*=}"
    if sysctl -w "$key=$val" >/dev/null 2>&1; then
      echo "set $key=$val"
    else
      echo "failed $key=$val" >&2
    fi
  done
}

# -------------------------------------------------------------------
# IPv4 misc (ICMP, TCP, forwarding)
# -------------------------------------------------------------------
lp_sysctl_ipv4_misc () {
  local -a settings=(
    "net.ipv4.icmp_echo_ignore_broadcasts=1"
    "net.ipv4.icmp_ignore_bogus_error_responses=1"
    "net.ipv4.tcp_syncookies=1"
    "net.ipv4.ip_forward=0"
  )
  local item key val
  for item in "${settings[@]}"; do
    key="${item%%=*}"
    val="${item#*=}"
    if sysctl -w "$key=$val" >/dev/null 2>&1; then
      echo "set $key=$val"
    else
      echo "failed $key=$val" >&2
    fi
  done
}

# -------------------------------------------------------------------
# Filesystem & kernel hardening
# -------------------------------------------------------------------
lp_sysctl_fs_kernel () {
  local -a settings=(
    "fs.protected_hardlinks=1"
    "fs.protected_symlinks=1"
    "fs.suid_dumpable=0"
    "kernel.randomize_va_space=2"
    "kernel.sysrq=0"
  )
  local item key val
  for item in "${settings[@]}"; do
    key="${item%%=*}"
    val="${item#*=}"
    if sysctl -w "$key=$val" >/dev/null 2>&1; then
      echo "set $key=$val"
    else
      echo "failed $key=$val" >&2
    fi
  done
}

# -------------------------------------------------------------------
# Persist sysctl settings and reload
# -------------------------------------------------------------------
lp_sysctl_persist_and_reload () {
  local outfile="/etc/sysctl.d/99-hardening.conf"
  local tmp
  tmp="$(mktemp)" || { echo "Warning: mktemp failed" >&2; return 1; }

  local -a keys=(
    net.ipv6.conf.all.accept_ra
    net.ipv6.conf.all.accept_redirects
    net.ipv6.conf.all.accept_source_route
    net.ipv6.conf.all.forwarding
    net.ipv6.conf.default.accept_ra
    net.ipv6.conf.default.accept_redirects
    net.ipv6.conf.default.accept_source_route
    net.ipv4.conf.all.accept_redirects
    net.ipv4.conf.all.accept_source_route
    net.ipv4.conf.all.log_martians
    net.ipv4.conf.all.rp_filter
    net.ipv4.conf.all.secure_redirects
    net.ipv4.conf.all.send_redirects
    net.ipv4.conf.default.accept_redirects
    net.ipv4.conf.default.accept_source_route
    net.ipv4.conf.default.log_martians
    net.ipv4.conf.default.rp_filter
    net.ipv4.conf.default.secure_redirects
    net.ipv4.conf.default.send_redirects
    net.ipv4.icmp_echo_ignore_broadcasts
    net.ipv4.icmp_ignore_bogus_error_responses
    net.ipv4.tcp_syncookies
    net.ipv4.ip_forward
    fs.protected_hardlinks
    fs.protected_symlinks
    fs.suid_dumpable
    kernel.randomize_va_space
    kernel.sysrq
  )

  {
    echo "# Linux-Fox1 hardening sysctl (managed)"
    echo "# Do not edit manually; changes may be overwritten"
  } > "$tmp"

  local key val count=0
  for key in "${keys[@]}"; do
    val="$(sysctl -n "$key" 2>/dev/null)"
    if [ -n "$val" ]; then
      printf "%s = %s\n" "$key" "$val" >> "$tmp"
      count=$((count+1))
    fi
  done

  if [ -f "$outfile" ]; then
    local backup="${outfile}.$(date +%Y%m%d-%H%M%S).bak"
    if cp -a -- "$outfile" "$backup"; then
      echo "Backup: $backup"
    else
      echo "Warning: failed to create backup of $outfile" >&2
    fi
  fi

  if install -m 0644 -T -- "$tmp" "$outfile" 2>/dev/null; then
    :
  elif mv -- "$tmp" "$outfile"; then
    chmod 0644 "$outfile" || true
  else
    echo "Warning: failed to write $outfile" >&2
    rm -f -- "$tmp"
    return 1
  fi

  echo "Wrote: $outfile ($count entries)"

  if sysctl --system >/dev/null 2>&1; then
    echo "Reload: sysctl --system OK"
  elif sysctl -p "$outfile" >/dev/null 2>&1; then
    echo "Reload: sysctl -p $outfile OK"
  else
    echo "Warning: failed to reload sysctl settings" >&2
  fi
}


# -------------------------------------------------------------------
# Explicit disable SysRq helper (robust)
# Ensures kernel.sysrq=0 at runtime and persists it to /etc/sysctl.d/99-hardening.conf
# Works on Ubuntu/Mint; uses sudo when necessary.
# -------------------------------------------------------------------
lp_disable_sysrq () {
  local outfile="/etc/sysctl.d/99-hardening.conf"
  local ts tmp
  ts=$(date +%Y%m%d%H%M%S)

  echo "Disabling SysRq (kernel.sysrq=0)"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    echo "DRY RUN: would run 'sysctl -w kernel.sysrq=0'"
    echo "DRY RUN: would persist 'kernel.sysrq = 0' to $outfile"
    return 0
  fi

  # Set runtime value (use sudo if not root)
  if [ "$(id -u)" -ne 0 ]; then
    if sudo sysctl -w kernel.sysrq=0 >/dev/null 2>&1; then
      echo "Set runtime kernel.sysrq=0 (via sudo)"
    else
      echo "Warning: failed to set runtime kernel.sysrq=0 via sudo" >&2
    fi
  else
    if sysctl -w kernel.sysrq=0 >/dev/null 2>&1; then
      echo "Set runtime kernel.sysrq=0"
    else
      echo "Warning: failed to set runtime kernel.sysrq=0" >&2
    fi
  fi

  # Persist the setting into the sysctl conf (create backup)
  if [ -f "$outfile" ]; then
    sudo cp -a -- "$outfile" "${outfile}.bak.${ts}" || echo "Warning: failed to backup $outfile" >&2
  fi

  tmp=$(mktemp) || tmp="/tmp/99-hardening.${ts}.tmp"

  # Remove existing kernel.sysrq lines (case-insensitive) and preserve other settings
  if [ -f "$outfile" ]; then
    sudo sed -E '/^\s*kernel\.sysrq\b/Id' "$outfile" > "$tmp" || sudo cp -a "$outfile" "$tmp"
  else
    : > "$tmp"
  fi

  printf '%s\n' 'kernel.sysrq = 0' | sudo tee -a "$tmp" > /dev/null
  sudo install -m 0644 "$tmp" "$outfile"
  sudo rm -f "$tmp" || true

  echo "Persisted kernel.sysrq=0 to $outfile (backup: ${outfile}.bak.${ts} if existed)"
  return 0
}

# -------------------------------------------------------------------
# Enable ASLR (Address Space Layout Randomization)
# Ensures kernel.randomize_va_space=2 at runtime and persists it to /etc/sysctl.d/99-hardening.conf
# Works on Ubuntu/Mint; uses sudo when necessary.
# -------------------------------------------------------------------
lp_enable_aslr () {
  local outfile="/etc/sysctl.d/99-hardening.conf"
  local ts tmp
  ts=$(date +%Y%m%d%H%M%S)

  echo "Enabling ASLR (kernel.randomize_va_space=2)"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    echo "DRY RUN: would run 'sysctl -w kernel.randomize_va_space=2'"
    echo "DRY RUN: would persist 'kernel.randomize_va_space = 2' to $outfile"
    return 0
  fi

  # Set runtime value (use sudo if not root)
  if [ "$(id -u)" -ne 0 ]; then
    if sudo sysctl -w kernel.randomize_va_space=2 >/dev/null 2>&1; then
      echo "Set runtime kernel.randomize_va_space=2 (via sudo)"
    else
      echo "Warning: failed to set runtime kernel.randomize_va_space=2 via sudo" >&2
    fi
  else
    if sysctl -w kernel.randomize_va_space=2 >/dev/null 2>&1; then
      echo "Set runtime kernel.randomize_va_space=2"
    else
      echo "Warning: failed to set runtime kernel.randomize_va_space=2" >&2
    fi
  fi

  # Persist the setting into the sysctl conf (create backup)
  if [ -f "$outfile" ]; then
    sudo cp -a -- "$outfile" "${outfile}.bak.${ts}" || echo "Warning: failed to backup $outfile" >&2
  fi

  tmp=$(mktemp) || tmp="/tmp/99-hardening.${ts}.tmp"

  # Remove existing kernel.randomize_va_space lines (case-insensitive) and preserve other settings
  if [ -f "$outfile" ]; then
    sudo sed -E '/^\s*kernel\.randomize_va_space\b/Id' "$outfile" > "$tmp" || sudo cp -a "$outfile" "$tmp"
  else
    : > "$tmp"
  fi

  printf '%s\n' 'kernel.randomize_va_space = 2' | sudo tee -a "$tmp" > /dev/null
  sudo install -m 0644 "$tmp" "$outfile"
  sudo rm -f "$tmp" || true

  echo "Persisted kernel.randomize_va_space=2 to $outfile (backup: ${outfile}.bak.${ts} if existed)"
  return 0
}

# -------------------------------------------------------------------
# Verify local policy: runtime vs persisted checks for SysRq and ASLR
# Prints status lines and returns 0 if both match persisted values, non-zero otherwise.
# DRY_RUN safe: will only print what it would check.
# -------------------------------------------------------------------
lp_verify_local_policy () {
  local ok=0
  local runtime_sysrq persisted_sysrq
  local runtime_aslr persisted_aslr
  local outfile="/etc/sysctl.d/99-hardening.conf"

  echo "Verifying local policy settings..."

  # Runtime checks (use sysctl -n to get values)
  runtime_sysrq=$(sysctl -n kernel.sysrq 2>/dev/null || echo "")
  runtime_aslr=$(sysctl -n kernel.randomize_va_space 2>/dev/null || echo "")

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    echo "DRY RUN: would check runtime kernel.sysrq (got: ${runtime_sysrq:-<missing>})"
    echo "DRY RUN: would check runtime kernel.randomize_va_space (got: ${runtime_aslr:-<missing>})"
  fi

  # Persisted checks
  if [ -f "$outfile" ]; then
    persisted_sysrq=$(grep -Ei '^\s*kernel\.sysrq' "$outfile" 2>/dev/null | tail -n1 | awk -F'=' '{gsub(/ /, "", $2); print $2}' || echo "")
    persisted_aslr=$(grep -Ei '^\s*kernel\.randomize_va_space' "$outfile" 2>/dev/null | tail -n1 | awk -F'=' '{gsub(/ /, "", $2); print $2}' || echo "")
  else
    persisted_sysrq=""
    persisted_aslr=""
  fi

  printf "Runtime kernel.sysrq: %s\n" "${runtime_sysrq:-<missing>}"
  printf "Persisted kernel.sysrq: %s\n" "${persisted_sysrq:-<missing>}"
  if [ "${runtime_sysrq}" != "${persisted_sysrq}" ] || [ -z "${runtime_sysrq}" ]; then
    echo "Mismatch: kernel.sysrq runtime != persisted or missing" >&2
    ok=1
  else
    echo "OK: kernel.sysrq matches persisted value"
  fi

  printf "Runtime kernel.randomize_va_space: %s\n" "${runtime_aslr:-<missing>}"
  printf "Persisted kernel.randomize_va_space: %s\n" "${persisted_aslr:-<missing>}"
  if [ "${runtime_aslr}" != "${persisted_aslr}" ] || [ -z "${runtime_aslr}" ]; then
    echo "Mismatch: kernel.randomize_va_space runtime != persisted or missing" >&2
    ok=1
  else
    echo "OK: kernel.randomize_va_space matches persisted value"
  fi

  return "$ok"
}

# -------------------------------------------------------------------
# Secure sudo (dangerous if misused; Debian/Ubuntu/Mint)
# -------------------------------------------------------------------
lp_secure_sudo () {
  local _restore_errexit=0
  case $- in *e*) _restore_errexit=1 ;; esac
  set +e

  if [ -d /etc/sudoers.d ]; then
    if find /etc/sudoers.d -mindepth 1 -type f -print -delete 2>/dev/null; then
      echo "Removed files under /etc/sudoers.d (kept /etc/sudoers)."
    else
      echo "Warning: Failed to remove some files under /etc/sudoers.d." >&2
    fi
  else
    echo "Warning: /etc/sudoers.d not found; nothing to remove." >&2
  fi

  if command -v apt-get >/dev/null 2>&1; then
    if env DEBIAN_FRONTEND=noninteractive apt-get -y purge sudo >/dev/null 2>&1; then
      echo "Purged sudo package."
    else
      echo "Warning: Failed to purge sudo package." >&2
    fi

    if env DEBIAN_FRONTEND=noninteractive apt-get -y install sudo >/dev/null 2>&1; then
      echo "Installed sudo package."
    else
      echo "Warning: Failed to install sudo package." >&2
    fi
  else
    echo "Warning: apt-get not found; cannot purge/reinstall sudo." >&2
  fi

  [ "$_restore_errexit" -eq 1 ] && set -e
  return 0
}
