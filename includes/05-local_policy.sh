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
  keys=(
    "net.ipv6.conf.all.accept_ra=0"
    "net.ipv6.conf.all.accept_redirects=0"
    "net.ipv6.conf.all.accept_source_route=0"
    "net.ipv6.conf.all.forwarding=0"
  )
  for kv in "${keys[@]}"; do
    key=${kv%%=*}
    val=${kv#*=}
    if sudo sysctl -w "$key=$val" >/dev/null 2>&1; then
      echo "Set runtime: $key=$val"
    else
      echo "Failed to set runtime: $key=$val" >&2
      # continue on errors
    fi
  done
}

# -------------------------------------------------------------------
# IPv6 sysctl (default interface template)
# -------------------------------------------------------------------
lp_sysctl_ipv6_default () {
  keys=(
    "net.ipv6.conf.default.accept_ra=0"
    "net.ipv6.conf.default.accept_redirects=0"
    "net.ipv6.conf.default.accept_source_route=0"
  )
  for kv in "${keys[@]}"; do
    key=${kv%%=*}
    val=${kv#*=}
    if sudo sysctl -w "$key=$val" >/dev/null 2>&1; then
      echo "Set runtime: $key=$val"
    else
      echo "Failed to set runtime: $key=$val" >&2
    fi
  done
}

# -------------------------------------------------------------------
# IPv4 sysctl (all interfaces)
# -------------------------------------------------------------------
lp_sysctl_ipv4_all () {
  keys=(
    "net.ipv4.conf.all.accept_redirects=0"
    "net.ipv4.conf.all.accept_source_route=0"
    "net.ipv4.conf.all.log_martians=1"
    "net.ipv4.conf.all.rp_filter=1"
    "net.ipv4.conf.all.secure_redirects=0"
    "net.ipv4.conf.all.send_redirects=0"
  )
  for kv in "${keys[@]}"; do
    key=${kv%%=*}
    val=${kv#*=}
    if sudo sysctl -w "$key=$val" >/dev/null 2>&1; then
      echo "Set runtime: $key=$val"
    else
      echo "Failed to set runtime: $key=$val" >&2
    fi
  done
}

# -------------------------------------------------------------------
# IPv4 sysctl (default interface template)
# -------------------------------------------------------------------
lp_sysctl_ipv4_default () {
  keys=(
    "net.ipv4.conf.default.accept_redirects=0"
    "net.ipv4.conf.default.accept_source_route=0"
    "net.ipv4.conf.default.log_martians=1"
    "net.ipv4.conf.default.rp_filter=1"
    "net.ipv4.conf.default.secure_redirects=0"
    "net.ipv4.conf.default.send_redirects=0"
  )
  for kv in "${keys[@]}"; do
    key=${kv%%=*}
    val=${kv#*=}
    if sudo sysctl -w "$key=$val" >/dev/null 2>&1; then
      echo "Set runtime: $key=$val"
    else
      echo "Failed to set runtime: $key=$val" >&2
    fi
  done
}

# -------------------------------------------------------------------
# IPv4 misc (ICMP, TCP, forwarding)
# -------------------------------------------------------------------
lp_sysctl_ipv4_misc () {
  keys=(
    "net.ipv4.icmp_echo_ignore_broadcasts=1"
    "net.ipv4.icmp_ignore_bogus_error_responses=1"
    "net.ipv4.tcp_syncookies=1"
    "net.ipv4.ip_forward=0"
  )
  for kv in "${keys[@]}"; do
    key=${kv%%=*}
    val=${kv#*=}
    if sudo sysctl -w "$key=$val" >/dev/null 2>&1; then
      echo "Set runtime: $key=$val"
    else
      echo "Failed to set runtime: $key=$val" >&2
    fi
  done
}

# -------------------------------------------------------------------
# Filesystem & kernel hardening
# -------------------------------------------------------------------
lp_sysctl_fs_kernel () {
  keys=(
    "fs.protected_hardlinks=1"
    "fs.protected_symlinks=1"
    "fs.suid_dumpable=0"
    "kernel.randomize_va_space=2"
  )
  for kv in "${keys[@]}"; do
    key=${kv%%=*}
    val=${kv#*=}
    if sudo sysctl -w "$key=$val" >/dev/null 2>&1; then
      echo "Set runtime: $key=$val"
    else
      echo "Failed to set runtime: $key=$val" >&2
    fi
  done
}

# -------------------------------------------------------------------
# Persist sysctl settings and reload
# -------------------------------------------------------------------
lp_sysctl_persist_and_reload () {
  # Consolidate all desired settings
  declare -A sysctl_map=(
    [net.ipv6.conf.all.accept_ra]=0
    [net.ipv6.conf.all.accept_redirects]=0
    [net.ipv6.conf.all.accept_source_route]=0
    [net.ipv6.conf.all.forwarding]=0

    [net.ipv6.conf.default.accept_ra]=0
    [net.ipv6.conf.default.accept_redirects]=0
    [net.ipv6.conf.default.accept_source_route]=0

    [net.ipv4.conf.all.accept_redirects]=0
    [net.ipv4.conf.all.accept_source_route]=0
    [net.ipv4.conf.all.log_martians]=1
    [net.ipv4.conf.all.rp_filter]=1
    [net.ipv4.conf.all.secure_redirects]=0
    [net.ipv4.conf.all.send_redirects]=0

    [net.ipv4.conf.default.accept_redirects]=0
    [net.ipv4.conf.default.accept_source_route]=0
    [net.ipv4.conf.default.log_martians]=1
    [net.ipv4.conf.default.rp_filter]=1
    [net.ipv4.conf.default.secure_redirects]=0
    [net.ipv4.conf.default.send_redirects]=0

    [net.ipv4.icmp_echo_ignore_broadcasts]=1
    [net.ipv4.icmp_ignore_bogus_error_responses]=1
    [net.ipv4.tcp_syncookies]=1
    [net.ipv4.ip_forward]=0

    [fs.protected_hardlinks]=1
    [fs.protected_symlinks]=1
    [fs.suid_dumpable]=0
    [kernel.randomize_va_space]=2
  )

  target=/etc/sysctl.d/99-hardening.conf
  ts=$(date +%Y%m%d%H%M%S)
  if [ -f "$target" ]; then
    sudo cp -a "$target" "${target}.bak.${ts}"
    echo "Backup created: ${target}.bak.${ts}"
  fi

  # Write to a temp file then move into place to ensure idempotence
  tmpfile="/tmp/99-hardening.conf.$$"
  : > "$tmpfile"
  for k in "${!sysctl_map[@]}"; do
    echo "$k = ${sysctl_map[$k]}" >> "$tmpfile"
  done

  # Ensure consistent ordering (sort) to reduce churn
  sudo sort -u "$tmpfile" -o "$tmpfile"
  sudo mv "$tmpfile" "$target"
  echo "Wrote sysctl settings to $target"

  # Reload sysctl settings; continue on errors but report
  if sudo sysctl --system >/dev/null 2>&1; then
    echo "sysctl --system reloaded successfully"
  else
    echo "sysctl --system reload failed" >&2
  fi
}

# -------------------------------------------------------------------
# Secure sudo (dangerous if misused; stub only)
# -------------------------------------------------------------------
lp_secure_sudo () {
  # Remove files under /etc/sudoers.d/ but never remove /etc/sudoers
  if [ -d /etc/sudoers.d ]; then
    sudo find /etc/sudoers.d -maxdepth 1 -type f -print0 | while IFS= read -r -d '' f; do
      if [ "$(basename "$f")" = "sudoers" ]; then
        echo "Skipping /etc/sudoers.d/sudoers"
        continue
      fi
      if sudo rm -f "$f" >/dev/null 2>&1; then
        echo "Removed $f"
      else
        echo "Warning: failed to remove $f" >&2
      fi
    done
  else
    echo "/etc/sudoers.d does not exist"
  fi

  # Detect package manager and perform purge & reinstall non-interactively
  if command -v apt-get >/dev/null 2>&1; then
    pkg_mgr=apt
  elif command -v apt >/dev/null 2>&1; then
    pkg_mgr=apt
  elif command -v dnf >/dev/null 2>&1; then
    pkg_mgr=dnf
  elif command -v yum >/dev/null 2>&1; then
    pkg_mgr=yum
  elif command -v pacman >/dev/null 2>&1; then
    pkg_mgr=pacman
  else
    pkg_mgr=unknown
  fi

  case "$pkg_mgr" in
    apt)
      if sudo DEBIAN_FRONTEND=noninteractive apt-get -y purge sudo >/dev/null 2>&1; then
        echo "Purged sudo (apt)"
      else
        echo "Warning: failed to purge sudo with apt" >&2
      fi
      if sudo DEBIAN_FRONTEND=noninteractive apt-get -y install sudo >/dev/null 2>&1; then
        echo "Installed sudo (apt)"
      else
        echo "Warning: failed to install sudo with apt" >&2
      fi
      ;;
    dnf)
      if sudo dnf -y remove sudo >/dev/null 2>&1; then
        echo "Removed sudo (dnf)"
      else
        echo "Warning: failed to remove sudo with dnf" >&2
      fi
      if sudo dnf -y install sudo >/dev/null 2>&1; then
        echo "Installed sudo (dnf)"
      else
        echo "Warning: failed to install sudo with dnf" >&2
      fi
      ;;
    yum)
      if sudo yum -y remove sudo >/dev/null 2>&1; then
        echo "Removed sudo (yum)"
      else
        echo "Warning: failed to remove sudo with yum" >&2
      fi
      if sudo yum -y install sudo >/dev/null 2>&1; then
        echo "Installed sudo (yum)"
      else
        echo "Warning: failed to install sudo with yum" >&2
      fi
      ;;
    pacman)
      if sudo pacman -R --noconfirm sudo >/dev/null 2>&1; then
        echo "Removed sudo (pacman)"
      else
        echo "Warning: failed to remove sudo with pacman" >&2
      fi
      if sudo pacman -S --noconfirm sudo >/dev/null 2>&1; then
        echo "Installed sudo (pacman)"
      else
        echo "Warning: failed to install sudo with pacman" >&2
      fi
      ;;
    *)
      echo "Warning: unknown package manager; cannot purge/reinstall sudo" >&2
      ;;
  esac
}
