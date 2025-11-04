#!/usr/bin/env bash
set -euo pipefail

CYAN="\033[1;36m"
NC="\033[0m"

# ============================================================
# Main Application Updates
# ============================================================
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

# ------------------------------------------------------------
# firefox: update (APT, Snap, or Flatpak)
# ------------------------------------------------------------
au_update_firefox () {
  echo "Updating Firefox..."
  if command -v snap >/dev/null 2>&1 && snap list firefox >/dev/null 2>&1; then
    echo "Detected Snap Firefox; refreshing..."
    if sudo snap refresh firefox >/dev/null 2>&1; then
      echo "Firefox (Snap) updated successfully."
      return 0
    fi
  elif command -v flatpak >/dev/null 2>&1 && flatpak list | grep -q firefox; then
    echo "Detected Flatpak Firefox; updating..."
    if sudo flatpak update -y org.mozilla.firefox >/dev/null 2>&1; then
      echo "Firefox (Flatpak) updated successfully."
      return 0
    fi
  elif dpkg -l | grep -q firefox; then
    echo "Detected APT Firefox; upgrading..."
    if sudo apt-get install --only-upgrade -y firefox >/dev/null 2>&1; then
      echo "Firefox (APT) updated successfully."
      return 0
    fi
  else
    echo "Firefox not found on this system; skipping."
  fi
}

# ------------------------------------------------------------
# chrome: update (APT or Flatpak)
# ------------------------------------------------------------
au_update_chrome () {
  echo "Updating Google Chrome..."
  if command -v google-chrome >/dev/null 2>&1; then
    if dpkg -l | grep -q google-chrome-stable; then
      echo "Detected APT Google Chrome; upgrading..."
      if sudo apt-get install --only-upgrade -y google-chrome-stable >/dev/null 2>&1; then
        echo "Google Chrome (APT) updated successfully."
        return 0
      fi
    fi
  elif command -v flatpak >/dev/null 2>&1 && flatpak list | grep -q com.google.Chrome; then
    echo "Detected Flatpak Google Chrome; updating..."
    if sudo flatpak update -y com.google.Chrome >/dev/null 2>&1; then
      echo "Google Chrome (Flatpak) updated successfully."
      return 0
    fi
  else
    echo "Google Chrome not found on this system; skipping."
  fi
}

# ------------------------------------------------------------
# Interactive looping menu
# ------------------------------------------------------------
show_update_menu () {
  while true; do
    echo -e "\n${CYAN}------------------------------------------${NC}"
    echo "  Application Update Menu"
    echo -e "${CYAN}------------------------------------------${NC}"
    echo "1) Run all application updates"
    echo "2) Update Firefox only"
    echo "3) Update Google Chrome only"
    echo "4) Exit"
    echo -e "${CYAN}------------------------------------------${NC}"
    read -rp "Choose an option [1-4]: " choice
    echo

    case "$choice" in
      1)
        invoke_application_updates
        ;;
      2)
        au_update_firefox
        ;;
      3)
        au_update_chrome
        ;;
      4)
        echo "Exiting."
        break
        ;;
      *)
        echo "Invalid option. Please choose 1–4."
        ;;
    esac
  done
}

# ------------------------------------------------------------
# Entry point
# ------------------------------------------------------------
show_update_menu

