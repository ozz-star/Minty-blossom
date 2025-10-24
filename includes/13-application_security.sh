#!/usr/bin/env bash
set -euo pipefail

# Submenu orchestrator only; no task bodies.
invoke_application_security_menu () {
  while true; do
    echo
    echo "Application Security Menu"
    echo "  1) Secure Firefox"
    echo "  2) Secure Chrome/Chromium"
    echo "  3) Secure OpenSSH"
    echo "  4) Secure Samba"
    echo "  5) Secure DNS (resolvers)"
    echo "  6) Secure NGINX/Apache"
    echo "  7) Return to Main Menu"
    read -rp $'\nEnter choice: ' app_choice
    case "$app_choice" in
      1) appsec_secure_firefox ;;
      2) appsec_secure_chromium ;;
      3) appsec_secure_ssh ;;
      4) appsec_secure_samba ;;
      5) appsec_secure_dns ;;
      6) appsec_secure_web ;;
      7) return ;;
      *) echo "Invalid option";;
    esac
  done
}

# Sub-orchestrators (no bodies yet)
appsec_secure_firefox () {
  # Configure system-wide Firefox policies to enable Safe Browsing and
  # block dangerous downloads. This writes /etc/firefox/policies/policies.json
  # (Debian/Ubuntu location). Respects DRY_RUN if set in the environment.

  local policies_dir="/etc/firefox/policies"
  local policies_file="${policies_dir}/policies.json"
  local ts tmpfile
  ts=$(date +%Y%m%d%H%M%S)

  echo "[AppSec] Securing Firefox: will enable Safe Browsing and block dangerous downloads"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    echo "DRY RUN: would ensure directory ${policies_dir} exists (mkdir -p)"
    if [ -f "$policies_file" ]; then
      echo "DRY RUN: would backup existing $policies_file -> ${policies_file}.bak.${ts}"
      echo "DRY RUN: would write policies JSON to $policies_file with Safe Browsing download protections"
    else
      echo "DRY RUN: would create $policies_file with Safe Browsing download protections"
    fi
    return 0
  fi

  # Create policy directory if missing
  if [ ! -d "$policies_dir" ]; then
    sudo mkdir -p "$policies_dir"
    echo "Created directory $policies_dir"
  fi

  # Backup existing policies file if present
  if [ -f "$policies_file" ]; then
    sudo cp -a "$policies_file" "${policies_file}.bak.${ts}"
    echo "Backup created: ${policies_file}.bak.${ts}"
  fi

  # Write policies.json (atomic write)
  tmpfile="${policies_file}.tmp.${ts}"
  cat <<'JSON' > "$tmpfile"
{
  "policies": {
    "Preferences": {
      "browser.safebrowsing.malware.enabled": true,
      "browser.safebrowsing.phishing.enabled": true,
      "browser.safebrowsing.downloads.enabled": true,
      "browser.safebrowsing.downloads.remote.block_potentially_unwanted": true,
      "browser.safebrowsing.downloads.remote.block_uncommon": true,
      "security.OCSP.enabled": 1,
      "security.OCSP.require": true,
      "security.enterprise_roots.enabled": true
    }
  }
}
JSON

  sudo mv "$tmpfile" "$policies_file"
  sudo chown root:root "$policies_file"
  sudo chmod 0644 "$policies_file"

  echo "Wrote Firefox policies to $policies_file (Safe Browsing + certificate checks enabled)"
  echo "If you need to revert, restore the backup file located at ${policies_file}.bak.<timestamp>"

  # Also apply to /usr/lib/firefox/distribution if present (older/default package path)
  dist_dir="/usr/lib/firefox/distribution"
  dist_file="${dist_dir}/policies.json"
  if [ -d "$dist_dir" ]; then
    if [ -f "$dist_file" ]; then
      sudo cp -a "$dist_file" "${dist_file}.bak.${ts}"
      echo "Backup created: ${dist_file}.bak.${ts}"
    fi
    sudo cp -a "$policies_file" "$dist_file"
    sudo chown root:root "$dist_file"
    sudo chmod 0644 "$dist_file"
    echo "Also wrote policies to $dist_file"
  fi

  # Note on snap-installed Firefox
  if command -v snap >/dev/null 2>&1 && snap list firefox >/dev/null 2>&1; then
    echo "Note: Firefox is installed as a snap on this system. Snap-packaged Firefox may not read /etc/firefox/policies;"
    echo "you may need to apply policies inside the snap environment or use distro-specific guidance."
    echo "For snap, check /var/snap/firefox/common or consult snap packaging docs."
  fi
}
appsec_secure_chromium  () { echo "[AppSec] Chrome/Chromium orchestrator (TODO)"; }
appsec_secure_ssh       () { echo "[AppSec] OpenSSH orchestrator (TODO)"; }
appsec_secure_samba     () { echo "[AppSec] Samba orchestrator (TODO)"; }
appsec_secure_dns       () { echo "[AppSec] DNS/resolvers orchestrator (TODO)"; }
appsec_secure_web       () { echo "[AppSec] Web server orchestrator (TODO)"; }
