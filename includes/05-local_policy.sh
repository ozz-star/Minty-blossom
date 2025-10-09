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
  local -a settings=(
    "net.ipv6.conf.all.accept_ra=0"
    "net.ipv6.conf.all.accept_redirects=0"
    "net.ipv6.conf.all.accept_source_route=0"
    "net.ipv6.conf.all.forwarding=0"
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
# IPv6 sysctl (default interface template)
# -------------------------------------------------------------------
# ...existing code...
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
# ...existing code...
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
# ...existing code...
```# filepath: c:\Users\Jes\Linux-Fox1\Linux-Fox1\includes\05-local_policy.sh
# ...existing code...
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
# ...existing code...

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
  
// ...existing code...
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
// ...existing code...
```// filepath: c:\Users\Jes\Linux-Fox1\Linux-Fox1\includes\05-local_policy.sh
// ...existing code...
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
// ...existing code...

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
``'lp_sysctl_fs_kernel () {
  local -a settings=(
    "fs.protected_hardlinks=1"
    "fs.protected_symlinks=1"
    "fs.suid_dumpable=0"
    "kernel.randomize_va_space=2"
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

  # Keys managed by this script (match earlier runtime changes)
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
# Secure sudo (dangerous if misused; stub only)
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