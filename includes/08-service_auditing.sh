#!/usr/bin/env bash
set -euo pipefail

invoke_service_auditing () {
  echo -e "${CYAN}[Service Auditing] Start${NC}"

  sa_purge_unwanted_services

  echo -e "${CYAN}[Service Auditing] Done${NC}"
}

# -------------------------------------------------------------------
# Interactively purge unwanted packages listed in $UNWANTED
# -------------------------------------------------------------------
sa_purge_unwanted_services () {
  # Read $UNWANTED and ensure it's set
  if [ -z "${UNWANTED:-}" ]; then
    echo "No unwanted services configured."
    return 0
  fi

  # Iterate over whitespace-separated package names
  for pkg in $UNWANTED; do
    # Check if package is installed (dpkg-query returns 0 if installed)
    if dpkg-query -W -f='${Status}' "$pkg" >/dev/null 2>&1; then
      # Prompt the user
      printf "Is the service %s a critical service? (Y/n) " "$pkg"
      read -r ans || ans=Y
      # Default to Y on empty
      if [ -z "$ans" ]; then
        ans=Y
      fi

      case "$ans" in
        [nN])
          echo "Purging $pkg..."
          # Attempt to purge; use sudo apt-get in non-interactive mode
          sa_purge_pkg "$pkg"
          ;;
        *)
          echo "$pkg kept."
          ;;
      esac
    else
      echo "$pkg not installed. Skipping..."
      # continue on errors
    fi
  done
}


# Helper: robustly purge a package on Debian/Ubuntu/Mint
sa_purge_pkg () {
  pkg="$1"
  ts=$(date +%Y%m%d%H%M%S)

  # If not installed, exit early
  if ! dpkg-query -W -f='${Status}' "$pkg" >/dev/null 2>&1; then
    echo "$pkg not installed. Skipping purge."
    return 0
  fi

  echo "Attempting to purge $pkg"
  # Try apt-get purge non-interactively
  if sudo DEBIAN_FRONTEND=noninteractive apt-get -y -qq purge "$pkg" >/dev/null 2>&1; then
    echo "Purged $pkg"
  else
    echo "Initial purge failed for $pkg; attempting dpkg recovery and retry" >&2
    sudo dpkg --configure -a || true
    sudo apt-get -f install -y -qq || true
    if sudo DEBIAN_FRONTEND=noninteractive apt-get -y -qq purge "$pkg" >/dev/null 2>&1; then
      echo "Purged $pkg on retry"
    else
      echo "Warning: Could not purge $pkg via apt. Will attempt to disable/stop service units if present." >&2

      # Attempt to stop/disable/mask any systemd service with the package name or common unit names
      # Try common unit name patterns
      units=("${pkg}.service" "${pkg}-service.service" "${pkg//_/-}.service")
      for u in "${units[@]}"; do
        if systemctl list-units --full --all --plain | grep -q "^\s*${u}"; then
          sudo systemctl stop "$u" || true
          sudo systemctl disable "$u" || true
          sudo systemctl mask "$u" || true
          echo "Stopped/disabled/masked unit $u"
        fi
      done

      # As a last resort, try to remove unit files left in /lib/systemd/system or /etc/systemd/system
      for dir in /etc/systemd/system /lib/systemd/system /usr/lib/systemd/system; do
        if [ -d "$dir" ]; then
          # match files containing the package name; skip non-existent matches
          for f in "$dir"/*"$pkg"*; do
            # If the glob didn't match anything, the pattern may remain; skip non-existing entries
            if [ ! -e "$f" ]; then
              continue
            fi
            if [ -f "$f" ]; then
              sudo cp -a "$f" "${f}.bak.${ts}" || true
              sudo rm -f "$f" || true
              echo "Removed leftover unit file $f"
            fi
          done
        fi
      done
    fi
  fi

  # Clean up apt caches for neatness
  sudo apt-get -y -qq autoremove >/dev/null 2>&1 || true
  sudo apt-get -y -qq clean >/dev/null 2>&1 || true

  return 0
}
