#!/usr/bin/env bash
set -euo pipefail

apply_sysctl() {
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
    sysctl -w "$setting"
  done

  printf "%s\n" "${settings[@]}" | sudo tee /etc/sysctl.d/99-secure.conf >/dev/null
  sudo sysctl --system
}

echo "[+] Applying local security policy..."
apply_sysctl
echo "[+] Done."
