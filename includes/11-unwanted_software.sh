#!/usr/bin/env bash
set -euo pipefail

CYAN="\033[0;36m"
NC="\033[0m"

invoke_unwanted_software() {
  echo -e "${CYAN}[Unwanted Software] Start${NC}"
  us_purge_unwanted_software
  echo -e "${CYAN}[Unwanted Software] Done${NC}"
}

# -------------------------------------------------------------------
# Purge unwanted software listed in $UNWANTED_SOFTWARE, then autoremove
# -------------------------------------------------------------------
us_purge_unwanted_software() {
  if [ -z "${UNWANTED_SOFTWARE:-}" ]; then
    echo "No unwanted software configured."
    return 0
  fi

  sudo apt-get update -qq || true

  for name in $UNWANTED_SOFTWARE; do
    echo "Processing unwanted package: $name"

    # --- APT packages ---
    mapfile -t matches < <(dpkg-query -W -f='${Package}\n' 2>/dev/null | grep -E "^${name}([:-].*)?$" || true)

    if [ ${#matches[@]} -gt 0 ]; then
      for pkg in "${matches[@]}"; do
        echo "Purging APT package: $pkg"
        if ! sudo DEBIAN_FRONTEND=noninteractive apt-get -y purge "$pkg"; then
          echo "Repairing dpkg status and retrying..."
          sudo dpkg --configure -a || true
          sudo apt-get install -f -y || true
          sudo DEBIAN_FRONTEND=noninteractive apt-get -y purge "$pkg" || \
            echo "Final failure: could not purge $pkg"
        fi
      done
    else
      echo "No APT package named $name found."
    fi

    # --- Flatpak packages ---
    if command -v flatpak >/dev/null 2>&1; then
      mapfile -t flat_matches < <(flatpak list --app --columns=application 2>/dev/null | grep -i "$name" || true)
      if [ ${#flat_matches[@]} -gt 0 ]; then
        for fpkg in "${flat_matches[@]}"; do
          echo "Removing Flatpak app: $fpkg"
          flatpak uninstall -y "$fpkg" || echo "Warning: could not remove Flatpak $fpkg"
        done
      fi
    fi

    # --- Snap packages (optional, Mint rarely uses snaps) ---
    if command -v snap >/dev/null 2>&1; then
      if snap list 2>/dev/null | grep -q "^$name"; then
        echo "Removing Snap package: $name"
        sudo snap remove --purge "$name" || echo "Warning: could not remove snap $name"
      fi
    fi
  done

  echo "Running autoremove & cleanup..."
  sudo apt-get -y autoremove
  sudo apt-get -y autoclean
  echo "Cleanup complete."
}

# Example usage:
# UNWANTED_SOFTWARE="thunderbird hexchat warpinator"
# invoke_unwanted_software
