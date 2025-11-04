#!/usr/bin/env bash
set -euo pipefail

invoke_local_policy () {
  # Interactive menu for local policy tasks
  declare -A LP_DONE=()
  while true; do
    echo -e "${CYAN}\n[Local Policy] Menu${NC}"
    printf "1) Apply IPv6 (all interfaces)\n"
    printf "2) Apply IPv6 (default template)\n"
    printf "3) Apply IPv4 (all interfaces)\n"
    printf "4) Apply IPv4 (default template)\n"
    printf "5) Apply IPv4 misc (ICMP/TCP/forwarding)\n"
    printf "6) Filesystem & kernel hardening (includes sysrq)\n"
    printf "7) Persist sysctl settings and reload\n"
    printf "8) Secure sudo (remove NOPASSWD tokens)\n"
  printf "9) Disable SysRq key (kernel.sysrq=0)\n"
  printf "10) Enable ASLR (Address Space Layout Randomization)\n"
    printf "a) Run ALL of the above\n"
    printf "b) Back to main menu\n"

    read -rp $'Enter choice: ' choice
    case "$choice" in
      1)
        lp_sysctl_ipv6_all; LP_DONE[1]=1
        ;;
      2)
        lp_sysctl_ipv6_default; LP_DONE[2]=1
        ;;
      3)
        lp_sysctl_ipv4_all; LP_DONE[3]=1
        ;;
      4)
        lp_sysctl_ipv4_default; LP_DONE[4]=1
        ;;
      5)
        lp_sysctl_ipv4_misc; LP_DONE[5]=1
        ;;
      6)
        lp_sysctl_fs_kernel; LP_DONE[6]=1
        ;;
      7)
        lp_sysctl_persist_and_reload; LP_DONE[7]=1
        ;;
      8)
        lp_secure_sudo; LP_DONE[8]=1
        ;;
      9)
        lp_disable_sysrq; LP_DONE[9]=1
        ;;
      10)
        lp_enable_aslr; LP_DONE[10]=1
        ;;
      a|A)
        lp_sysctl_ipv6_all; LP_DONE[1]=1
        lp_sysctl_ipv6_default; LP_DONE[2]=1
        lp_sysctl_ipv4_all; LP_DONE[3]=1
        lp_sysctl_ipv4_default; LP_DONE[4]=1
        lp_sysctl_ipv4_misc; LP_DONE[5]=1
        lp_sysctl_fs_kernel; LP_DONE[6]=1
        lp_sysctl_persist_and_reload; LP_DONE[7]=1
        lp_secure_sudo; LP_DONE[8]=1
  lp_disable_sysrq; LP_DONE[9]=1
  lp_enable_aslr; LP_DONE[10]=1
        echo -e "${CYAN}[Local Policy] Completed all sections.${NC}"
        ;;
      b|B|q|Q)
        echo -e "${CYAN}[Local Policy] Returning to main menu.${NC}"
        break
        ;;
      *)
        echo "Invalid option"
        ;;
    esac
  done
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

  # Ensure per-interface martians logging is enabled for all interfaces
  if [ -d /sys/class/net ]; then
    for iface in $(ls /sys/class/net); do
      # Skip loopback
      if [ "$iface" = "lo" ]; then continue; fi
      if sysctl -w "net.ipv4.conf.${iface}.log_martians=1" >/dev/null 2>&1; then
        echo "set net.ipv4.conf.${iface}.log_martians=1"
      else
        echo "failed net.ipv4.conf.${iface}.log_martians=1" >&2
      fi
    done
  fi
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

  # Add per-interface martians keys to the persisted list (if interfaces present)
  if [ -d /sys/class/net ]; then
    for iface in $(ls /sys/class/net); do
      # include per-interface log_martians entries (skip lo)
      if [ "$iface" != "lo" ]; then
        keys+=("net.ipv4.conf.${iface}.log_martians")
      fi
    done
  fi

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
# Explicit disable SysRq helper
# -------------------------------------------------------------------
lp_disable_sysrq () {
  local ts
  ts=$(date +%Y%m%d%H%M%S)

  echo "lp_disable_sysrq: disabling SysRq (kernel.sysrq=0)"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    echo "DRY RUN: would run 'sysctl -w kernel.sysrq=0'"
    echo "DRY RUN: would persist kernel.sysrq via lp_sysctl_persist_and_reload"
    return 0
  fi

  # Set at runtime
  if sudo sysctl -w kernel.sysrq=0 >/dev/null 2>&1; then
    echo "Set runtime kernel.sysrq=0"
  else
    echo "Warning: failed to set runtime kernel.sysrq=0" >&2
  fi

  # Persist by calling the existing persistence routine which writes current sysctl values
  if lp_sysctl_persist_and_reload >/dev/null 2>&1; then
    echo "Persisted kernel.sysrq=0 via lp_sysctl_persist_and_reload"
  else
    echo "Warning: failed to persist kernel.sysrq via lp_sysctl_persist_and_reload" >&2
  fi

  return 0
}


# -------------------------------------------------------------------
# Enable Address Space Layout Randomization (ASLR)
# Sets kernel.randomize_va_space=2 and persists using lp_sysctl_persist_and_reload
# -------------------------------------------------------------------
lp_enable_aslr () {
  echo "lp_enable_aslr: enabling ASLR (kernel.randomize_va_space=2)"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    echo "DRY RUN: would run 'sysctl -w kernel.randomize_va_space=2'"
    echo "DRY RUN: would persist kernel.randomize_va_space via lp_sysctl_persist_and_reload"
    return 0
  fi

  if sudo sysctl -w kernel.randomize_va_space=2 >/dev/null 2>&1; then
    echo "Set runtime kernel.randomize_va_space=2"
  else
    echo "Warning: failed to set runtime kernel.randomize_va_space=2" >&2
  fi

  if lp_sysctl_persist_and_reload >/dev/null 2>&1; then
    echo "Persisted kernel.randomize_va_space=2 via lp_sysctl_persist_and_reload"
  else
    echo "Warning: failed to persist kernel.randomize_va_space via lp_sysctl_persist_and_reload" >&2
  fi

  return 0
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