#!/usr/bin/env bash
set -euo pipefail

invoke_defensive_countermeasures () {
  echo -e "${CYAN}[Defensive Countermeasures] Start${NC}"

  dcm_ufw_reset_factory
  dcm_ufw_enable_and_boot
  dcm_ufw_loopback_policy
  dcm_ufw_deny_ping
  dcm_ufw_allow_ssh

  echo -e "${CYAN}[Defensive Countermeasures] Done${NC}"
}

# ------------------------------------------------------------
# UFW: reset to factory defaults (non-interactive)
# ------------------------------------------------------------
dcm_ufw_reset_factory () {
  if ! command -v ufw >/dev/null 2>&1; then
    echo "ufw not installed; skipping reset" >&2
    return 0
  fi

  # Use --force to avoid interactive prompt
  if sudo ufw --force reset >/dev/null 2>&1; then
    echo "UFW reset to factory defaults"
  else
    echo "Warning: ufw reset failed" >&2
  fi
}

# ------------------------------------------------------------
# UFW: ensure enabled now and on boot
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
    if sudo ufw --force enable >/dev/null 2>&1; then
      echo "UFW enabled"
    else
      echo "Warning: failed to enable UFW" >&2
    fi
  fi

  # Enable systemd unit for ufw so it starts on boot
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
# ------------------------------------------------------------
dcm_ufw_loopback_policy () {
  if ! command -v ufw >/dev/null 2>&1; then
    echo "ufw not installed; skipping loopback rules" >&2
    return 0
  fi

  # Helper to add a rule if not already present
  add_rule() {
    local rule_cmd="$1"
    local desc="$2"
    if sudo ufw status numbered | grep -F -- "$rule_cmd" >/dev/null 2>&1; then
      echo "Already present: $desc"
    else
      if sudo ufw $rule_cmd >/dev/null 2>&1; then
        echo "Added: $desc"
      else
        echo "Warning: failed to add $desc" >&2
      fi
    fi
  }

  # Allow in on loopback
  add_rule "allow in on lo" "allow in on lo"
  # Allow out on loopback
  add_rule "allow out on lo" "allow out on lo"
  # Deny inbound claiming 127.0.0.0/8
  add_rule "deny in from 127.0.0.0/8" "deny in from 127.0.0.0/8"
  # Deny inbound claiming ::1
  add_rule "deny in from ::1" "deny in from ::1"
}

# ------------------------------------------------------------
# UFW: deny ICMP echo-request (ping) responses
# ------------------------------------------------------------
dcm_ufw_deny_ping () {
  if ! command -v ufw >/dev/null 2>&1; then
    echo "ufw not installed; skipping deny-ping changes" >&2
    return 0
  fi

  before4=/etc/ufw/before.rules
  before6=/etc/ufw/before6.rules
  ts=$(date +%Y%m%d%H%M%S)

  # Backup files if they exist
  if [ -f "$before4" ]; then
    sudo cp -a "$before4" "${before4}.bak.${ts}"
    echo "Backup created: ${before4}.bak.${ts}"
  else
    echo "Warning: $before4 not found" >&2
  fi
  if [ -f "$before6" ]; then
    sudo cp -a "$before6" "${before6}.bak.${ts}"
    echo "Backup created: ${before6}.bak.${ts}"
  else
    echo "Warning: $before6 not found" >&2
  fi

  # Idempotent insertion markers
  marker4_start="# BEGIN: drop-icmp-echo-request (student-inserted)"
  marker4_end="# END: drop-icmp-echo-request (student-inserted)"
  marker6_start="# BEGIN: drop-icmpv6-echo-request (student-inserted)"
  marker6_end="# END: drop-icmpv6-echo-request (student-inserted)"

  # IPv4: insert block into ufw-before-input chain region (before generic accepts)
  if [ -f "$before4" ]; then
    # Remove existing block if present
    sudo awk -v s="$marker4_start" -v e="$marker4_end" '
      BEGIN{inside=0}
      { if ($0==s) {inside=1; next} if ($0==e) {inside=0; next} if (!inside) print }
    ' "$before4" | sudo tee "${before4}.tmp" >/dev/null

    # Construct insertion: drop ICMP echo-request in the ufw-before-input chain
    cat > /tmp/ufw-drop-icmp-block.$$ <<'BLOCK'
# BEGIN: drop-icmp-echo-request (student-inserted)
# Drop IPv4 ICMP echo-request (ping)
    # drop ICMP echo-request (type 8)
    -A ufw-before-input -p icmp --icmp-type echo-request -j DROP
# END: drop-icmp-echo-request (student-inserted)
BLOCK

    # Insert the block before the first occurrence of a generic ICMP accept (if present), else append before the COMMIT
    if sudo grep -q "ufw-before-input" "${before4}.tmp"; then
      # place block near the ufw-before-input chain definition
      sudo awk -v blockfile="/tmp/ufw-drop-icmp-block.$$" '
        { print }
        /:ufw-before-input/ {
          # after chain header, print block
          while((getline line < blockfile) > 0) print line
          close(blockfile)
        }
      ' "${before4}.tmp" | sudo tee "${before4}.new" >/dev/null
    else
      # fallback: append block at end
      sudo cat "${before4}.tmp" > "${before4}.new"
      sudo cat /tmp/ufw-drop-icmp-block.$$ >> "${before4}.new"
    fi

    sudo mv "${before4}.new" "$before4"
    rm -f "${before4}.tmp" /tmp/ufw-drop-icmp-block.$$
    echo "Updated $before4 with drop-icmp block"
  fi

  # IPv6: similar insertion into before6.rules
  if [ -f "$before6" ]; then
    sudo awk -v s="$marker6_start" -v e="$marker6_end" '
      BEGIN{inside=0}
      { if ($0==s) {inside=1; next} if ($0==e) {inside=0; next} if (!inside) print }
    ' "$before6" | sudo tee "${before6}.tmp" >/dev/null

    cat > /tmp/ufw-drop-icmp6-block.$$ <<'BLOCK6'
# BEGIN: drop-icmpv6-echo-request (student-inserted)
# Drop IPv6 ICMP echo-request (ping)
    # ICMPv6 echo-request
    -A ufw6-before-input -p ipv6-icmp --icmpv6-type echo-request -j DROP
# END: drop-icmpv6-echo-request (student-inserted)
BLOCK6

    if sudo grep -q "ufw6-before-input" "${before6}.tmp"; then
      sudo awk -v blockfile="/tmp/ufw-drop-icmp6-block.$$" '
        { print }
        /:ufw6-before-input/ {
          while((getline line < blockfile) > 0) print line
          close(blockfile)
        }
      ' "${before6}.tmp" | sudo tee "${before6}.new" >/dev/null
    else
      sudo cat "${before6}.tmp" > "${before6}.new"
      sudo cat /tmp/ufw-drop-icmp6-block.$$ >> "${before6}.new"
    fi

    sudo mv "${before6}.new" "$before6"
    rm -f "${before6}.tmp" /tmp/ufw-drop-icmp6-block.$$
    echo "Updated $before6 with drop-icmpv6 block"
  fi

  # Reload UFW to apply changes
  if sudo ufw reload >/dev/null 2>&1; then
    echo "UFW reloaded with new ICMP drop rules"
  else
    echo "Warning: UFW reload failed" >&2
  fi
}

# ------------------------------------------------------------
# UFW: allow SSH
# ------------------------------------------------------------
dcm_ufw_allow_ssh () {
  if ! command -v ufw >/dev/null 2>&1; then
    echo "ufw not installed; skipping SSH allow" >&2
    return 0
  fi

  # Prefer common profile names provided by UFW: OpenSSH, ssh, SSH
  profiles=("OpenSSH" "ssh" "SSH")
  chosen=""
  for p in "${profiles[@]}"; do
    if sudo ufw app list | grep -Fq "$p" >/dev/null 2>&1; then
      chosen="$p"
      break
    fi
  done

  if [ -z "$chosen" ]; then
    # fallback to using the name 'OpenSSH' even if not listed; ufw will accept it in many systems
    chosen="OpenSSH"
  fi

  # Idempotent add: check if rule already exists for the profile
  if sudo ufw status | grep -Fq "$chosen" >/dev/null 2>&1; then
    echo "SSH profile already allowed: $chosen"
  else
    if sudo ufw allow "$chosen" >/dev/null 2>&1; then
      echo "Allowed SSH via profile: $chosen"
    else
      echo "Warning: failed to allow SSH via profile: $chosen" >&2
    fi
  fi
}
