# -----------------------------------------------------------------
# Safer defensive countermeasures orchestration (UFW)
# - Adds required allow rules (SSH, DNS, DHCP, outbound allow) BEFORE enabling
# - Updates loopback and ICMP handling safely
# -----------------------------------------------------------------
invoke_defensive_countermeasures () {
  echo -e "${CYAN}[Defensive Countermeasures] Start${NC}"

  # If ufw isn't installed, other functions will skip themselves
  # 1) Reset but keep a quick backup
  dcm_ufw_reset_factory

  # 2) Ensure essential allow rules exist BEFORE enabling
  dcm_ufw_allow_ssh
  dcm_ufw_allow_dns
  dcm_ufw_allow_dhcp
  dcm_ufw_set_default_policies

  # 3) Now enable and ensure it starts on boot
  dcm_ufw_enable_and_boot

  # 4) Loopback & spoof protection (safe)
  dcm_ufw_loopback_policy

  # 5) Insert ICMP drop blocks (optional) — done after enable and after backup
  dcm_ufw_deny_ping

  echo -e "${CYAN}[Defensive Countermeasures] Done${NC}"
}

# ------------------------------------------------------------
# UFW: reset to factory defaults (non-interactive) with backup
# ------------------------------------------------------------
dcm_ufw_reset_factory () {
  if ! command -v ufw >/dev/null 2>&1; then
    echo "ufw not installed; skipping reset" >&2
    return 0
  fi

  # Backup current rules files if present
  ts=$(date +%Y%m%d%H%M%S)
  for f in /etc/ufw/ufw.conf /etc/ufw/before.rules /etc/ufw/before6.rules /etc/ufw/after.rules /etc/ufw/after6.rules; do
    [ -f "$f" ] && sudo cp -a "$f" "${f}.bak.${ts}" && echo "Backup created: ${f}.bak.${ts}"
  done

  # Use --force to avoid interactive prompt
  if sudo ufw --force reset >/dev/null 2>&1; then
    echo "UFW reset to factory defaults"
  else
    echo "Warning: ufw reset failed" >&2
  fi
}

# ------------------------------------------------------------
# UFW: explicitly set sensible default policies
#  - allow outgoing (so normal client traffic works)
#  - deny incoming by default
# ------------------------------------------------------------
dcm_ufw_set_default_policies () {
  if ! command -v ufw >/dev/null 2>&1; then
    echo "ufw not installed; skipping default policy set" >&2
    return 0
  fi

  # Explicitly set defaults (idempotent)
  sudo ufw default allow outgoing >/dev/null 2>&1 || echo "Warning: failed to set default allow outgoing" >&2
  sudo ufw default deny incoming >/dev/null 2>&1 || echo "Warning: failed to set default deny incoming" >&2
  echo "Set UFW defaults: outgoing=allow, incoming=deny"
}

# ------------------------------------------------------------
# UFW: ensure enabled now and on boot (idempotent)
# ------------------------------------------------------------
dcm_ufw_enable_and_boot () {
  if ! command -v ufw >/dev/null 2>&1; then
    echo "ufw not installed; cannot enable" >&2
    return 0
  fi

  # Enable UFW now (idempotent)
  if sudo ufw status | grep -q "Status: active" 2>/dev/null; then
    echo "UFW already enabled"
  else
    # Enable non-interactively
    if sudo ufw --force enable >/dev/null 2>&1; then
      echo "UFW enabled"
    else
      echo "Warning: failed to enable UFW" >&2
    fi
  fi

  # Ensure systemd unit enabled for boot
  if systemctl is-enabled ufw >/dev/null 2>&1; then
    echo "ufw.service already enabled at boot"
  else
    if sudo systemctl enable ufw >/dev/null 2>&1; then
      echo "Enabled ufw.service at boot"
    else
      echo "Warning: failed to enable ufw.service at boot" >&2
    fi
  fi
}

# ------------------------------------------------------------
# UFW: loopback policy (allow lo in/out, deny spoofed loopback)
# - non-destructive, checks existing rules first
# ------------------------------------------------------------
dcm_ufw_loopback_policy () {
  if ! command -v ufw >/dev/null 2>&1; then
    echo "ufw not installed; skipping loopback rules" >&2
    return 0
  fi

  add_if_missing() {
    local rule="$1"
    local desc="$2"
    if sudo ufw status verbose | grep -F -- "$rule" >/dev/null 2>&1; then
      echo "Already present: $desc"
    else
      if sudo ufw $rule >/dev/null 2>&1; then
        echo "Added: $desc"
      else
        echo "Warning: failed to add $desc" >&2
      fi
    fi
  }

  add_if_missing "allow in on lo" "allow in on lo"
  add_if_missing "allow out on lo" "allow out on lo"
  add_if_missing "deny in from 127.0.0.0/8" "deny in from 127.0.0.0/8"
  add_if_missing "deny in from ::1" "deny in from ::1"
}

# ------------------------------------------------------------
# UFW: explicit allow rules to prevent lockout / loss of internet
#  - SSH (explicit port fallback), DNS (53 TCP/UDP), DHCP (67/68 UDP)
# ------------------------------------------------------------
dcm_ufw_allow_ssh () {
  if ! command -v ufw >/dev/null 2>&1; then
    echo "ufw not installed; skipping SSH allow" >&2
    return 0
  fi

  # Try to add by profile name first; fall back to port 22/tcp
  if sudo ufw app list | grep -Fq "OpenSSH"; then
    sudo ufw allow OpenSSH >/dev/null 2>&1 && echo "Allowed SSH via profile: OpenSSH" || echo "Warning: failed to allow OpenSSH" >&2
  else
    # add explicit TCP/22 rule
    if sudo ufw status | grep -Fq "22/tcp" >/dev/null 2>&1; then
      echo "SSH (22/tcp) already allowed"
    else
      if sudo ufw allow 22/tcp >/dev/null 2>&1; then
        echo "Allowed SSH on port 22/tcp"
      else
        echo "Warning: failed to allow SSH on 22/tcp" >&2
      fi
    fi
  fi
}

dcm_ufw_allow_dns () {
  if ! command -v ufw >/dev/null 2>&1; then
    echo "ufw not installed; skipping DNS allow" >&2
    return 0
  fi

  # Allow DNS outbound (TCP and UDP 53). Use ufw allow out to be explicit.
  sudo ufw allow out proto udp to any port 53 >/dev/null 2>&1 || echo "Warning: failed to allow outbound DNS udp:53" >&2
  sudo ufw allow out proto tcp to any port 53 >/dev/null 2>&1 || echo "Warning: failed to allow outbound DNS tcp:53" >&2
  echo "Ensured outbound DNS allowed (TCP/UDP 53)"
}

dcm_ufw_allow_dhcp () {
  if ! command -v ufw >/dev/null 2>&1; then
    echo "ufw not installed; skipping DHCP allow" >&2
    return 0
  fi

  # DHCP client needs to send/receive on UDP ports 67/68 (client uses 68)
  # Allow DHCP client traffic (outbound) — some systems do this automatically
  sudo ufw allow out proto udp to any port 68 >/dev/null 2>&1 || true
  sudo ufw allow in proto udp from any port 67 to any port 68 >/dev/null 2>&1 || true
  echo "Ensured DHCP client traffic allowed (UDP 67/68) — best effort"
}

# ------------------------------------------------------------
# UFW: deny ICMP echo-request (ping)
# - This is applied after essential allow rules and enable
# - Uses backups and idempotent insertion
# ------------------------------------------------------------
dcm_ufw_deny_ping () {
  if ! command -v ufw >/dev/null 2>&1; then
    echo "ufw not installed; skipping deny-ping changes" >&2
    return 0
  fi

  before4=/etc/ufw/before.rules
  before6=/etc/ufw/before6.rules
  ts=$(date +%Y%m%d%H%M%S)

  # Backup and only modify if files exist; also validate content before overwriting
  [ -f "$before4" ] && sudo cp -a "$before4" "${before4}.bak.${ts}" && echo "Backup created: ${before4}.bak.${ts}"
  [ -f "$before6" ] && sudo cp -a "$before6" "${before6}.bak.${ts}" && echo "Backup created: ${before6}.bak.${ts}"

  marker4_start="# BEGIN: drop-icmp-echo-request (student-inserted)"
  marker4_end="# END: drop-icmp-echo-request (student-inserted)"
  marker6_start="# BEGIN: drop-icmpv6-echo-request (student-inserted)"
  marker6_end="# END: drop-icmpv6-echo-request (student-inserted)"

  # IPv4: safe insert — build new content and validate
  if [ -f "$before4" ]; then
    sudo awk -v s="$marker4_start" -v e="$marker4_end" 'BEGIN{inside=0} { if ($0==s) {inside=1; next} if ($0==e) {inside=0; next} if (!inside) print }' "$before4" | sudo tee "${before4}.tmp" >/dev/null

    cat > /tmp/ufw-drop-icmp-block.$$ <<'BLOCK'
# BEGIN: drop-icmp-echo-request (student-inserted)
# Drop IPv4 ICMP echo-request (ping)
    -A ufw-before-input -p icmp --icmp-type echo-request -j DROP
# END: drop-icmp-echo-request (student-inserted)
BLOCK

    # Insert block after chain header if present; else append before COMMIT
    if sudo grep -q "^:ufw-before-input" "${before4}.tmp"; then
      sudo awk -v blockfile="/tmp/ufw-drop-icmp-block.$$" ' { print } /^:ufw-before-input/ { while((getline line < blockfile) > 0) print line; close(blockfile) }' "${before4}.tmp" | sudo tee "${before4}.new" >/dev/null
    else
      sudo cat "${before4}.tmp" > "${before4}.new"
      sudo cat /tmp/ufw-drop-icmp-block.$$ >> "${before4}.new"
    fi

    # Validate the resulting file is non-empty before moving
    if [ -s "${before4}.new" ]; then
      sudo mv "${before4}.new" "$before4"
      echo "Updated $before4 with drop-icmp block"
    else
      echo "Warning: new $before4 would be empty; aborting update" >&2
    fi
    rm -f "${before4}.tmp" /tmp/ufw-drop-icmp-block.$$
  fi

  # IPv6: similar safe insert
  if [ -f "$before6" ]; then
    sudo awk -v s="$marker6_start" -v e="$marker6_end" 'BEGIN{inside=0} { if ($0==s) {inside=1; next} if ($0==e) {inside=0; next} if (!inside) print }' "$before6" | sudo tee "${before6}.tmp" >/dev/null

    cat > /tmp/ufw-drop-icmp6-block.$$ <<'BLOCK6'
# BEGIN: drop-icmpv6-echo-request (student-inserted)
# Drop IPv6 ICMP echo-request (ping)
    -A ufw6-before-input -p ipv6-icmp --icmpv6-type echo-request -j DROP
# END: drop-icmpv6-echo-request (student-inserted)
BLOCK6

    if sudo grep -q "^:ufw6-before-input" "${before6}.tmp"; then
      sudo awk -v blockfile="/tmp/ufw-drop-icmp6-block.$$" ' { print } /^:ufw6-before-input/ { while((getline line < blockfile) > 0) print line; close(blockfile) }' "${before6}.tmp" | sudo tee "${before6}.new" >/dev/null
    else
      sudo cat "${before6}.tmp" > "${before6}.new"
      sudo cat /tmp/ufw-drop-icmp6-block.$$ >> "${before6}.new"
    fi

    if [ -s "${before6}.new" ]; then
      sudo mv "${before6}.new" "$before6"
      echo "Updated $before6 with drop-icmpv6 block"
    else
      echo "Warning: new $before6 would be empty; aborting update" >&2
    fi
    rm -f "${before6}.tmp" /tmp/ufw-drop-icmp6-block.$$
  fi

  # Reload UFW to apply changes and ensure reload succeeded
  if sudo ufw reload >/dev/null 2>&1; then
    echo "UFW reloaded with new ICMP drop rules"
  else
    echo "Warning: UFW reload failed" >&2
  fi
}
