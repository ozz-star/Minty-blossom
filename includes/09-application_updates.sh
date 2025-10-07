#!/usr/bin/env bash
set -euo pipefail

invoke_application_updates () {
  echo -e "${CYAN}[Application Updates] Start${NC}"

  au_apt_update_indexes
  au_apt_full_upgrade
  au_snap_refresh_all
  au_flatpak_update_all

  echo -e "${CYAN}[Application Updates] Done${NC}"
}

# ------------------------------------------------------------
# apt: update package indexes
# ------------------------------------------------------------
au_apt_update_indexes () {
  echo "Updating APT indexes..."
  if sudo apt-get update -qq >/dev/null 2>&1; then
    echo "APT index update complete."
  else
    echo "Warning: APT index update failed; continuing." >&2
  fi
}

# ------------------------------------------------------------
# apt: full upgrade (non-interactive)
# ------------------------------------------------------------
au_apt_full_upgrade () {
  echo "Running APT full upgrade..."
  if sudo DEBIAN_FRONTEND=noninteractive apt-get -y -qq full-upgrade >/dev/null 2>&1; then
    echo "APT full upgrade complete."
  else
    echo "Warning: APT full upgrade failed; continuing." >&2
  fi
}

# ------------------------------------------------------------
# snap: refresh all snaps (if snap is installed)
# ------------------------------------------------------------
au_snap_refresh_all () {
  if ! command -v snap >/dev/null 2>&1; then
    echo "Snap not installed; skipping."
    return 0
  fi

  echo "Refreshing Snap packages..."
  if sudo snap refresh >/dev/null 2>&1; then
    echo "Snap refresh complete."
  else
    echo "Warning: snap refresh failed; continuing." >&2
  fi
}

# ------------------------------------------------------------
# flatpak: update all (if flatpak is installed)
# ------------------------------------------------------------
au_flatpak_update_all () {
  if ! command -v flatpak >/dev/null 2>&1; then
    echo "Flatpak not installed; skipping."
    return 0
  fi

  echo "Updating Flatpak apps/runtimes..."
  if sudo flatpak update -y >/dev/null 2>&1; then
    echo "Flatpak update complete."
  else
    echo "Warning: Flatpak update failed; continuing." >&2
  fi
}
