sudo tee /etc/sysctl.d/99-secure.conf >/dev/null <<'EOF'
# ==========================
# Hardened sysctl policy
# Linux Mint secure defaults
# ==========================

# --- Kernel Hardening ---
kernel.randomize_va_space = 2     # Full ASLR
kernel.sysrq = 0                  # Disable SysRq (prevent misuse)
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.suid_dumpable = 0

# --- IPv4 Hardening ---
net.ipv4.ip_forward = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1

# Apply to all live interfaces
net.ipv4.conf.*.accept_redirects = 0
net.ipv4.conf.*.accept_source_route = 0
net.ipv4.conf.*.log_martians = 1
net.ipv4.conf.*.rp_filter = 1

# --- IPv6 Hardening ---
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.*.accept_redirects = 0
net.ipv6.conf.*.accept_ra = 0
EOF
sudo sysctl --system
