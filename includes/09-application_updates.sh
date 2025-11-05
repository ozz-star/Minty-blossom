#!/usr/bin/env bash
set -euo pipefail

invoke_application_updates () {
  echo -e "${CYAN:-}[Application Updates] Start${NC:-}"

  au_apt_update_indexes
  au_apt_full_upgrade
  au_snap_refresh_all
  au_flatpak_update_all
  au_browser_mail_updates

  echo -e "${CYAN:-}[Application Updates] Done${NC:-}"
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
# Update Firefox, Chrome, and Thunderbird (if found)
# ------------------------------------------------------------
au_browser_mail_updates () {
  echo "Checking for browser and mail client updates..."

  # Firefox
  if command -v firefox >/dev/null 2>&1; then
    echo "Updating Firefox..."
    if dpkg -l firefox >/dev/null 2>&1; then
      sudo apt-get install --only-upgrade -y firefox >/dev/null 2>&1 && \
      echo "Firefox (APT) updated." || echo "Warning: Failed to update Firefox (APT)." >&2
    elif snap list firefox >/dev/null 2>&1; then
      sudo snap refresh firefox >/dev/null 2>&1 && \
      echo "Firefox (Snap) updated." || echo "Warning: Failed to update Firefox (Snap)." >&2
    elif flatpak list | grep -q org.mozilla.firefox; then
      sudo flatpak update -y org.mozilla.firefox >/dev/null 2>&1 && \
      echo "Firefox (Flatpak) updated." || echo "Warning: Failed to update Firefox (Flatpak)." >&2
    fi
  else
    echo "Firefox not found; skipping."
  fi

  # Google Chrome
  if command -v google-chrome >/dev/null 2>&1; then
    echo "Updating Google Chrome..."
    if dpkg -l google-chrome-stable >/dev/null 2>&1; then
      sudo apt-get install --only-upgrade -y google-chrome-stable >/dev/null 2>&1 && \
      echo "Google Chrome updated." || echo "Warning: Failed to update Google Chrome." >&2
    elif flatpak list | grep -q com.google.Chrome; then
      sudo flatpak update -y com.google.Chrome >/dev/null 2>&1 && \
      echo "Google Chrome (Flatpak) updated." || echo "Warning: Failed to update Google Chrome (Flatpak)." >&2
    fi
  else
    echo "Google Chrome not found; skipping."
  fi

  # Thunderbird
  if command -v thunderbird >/dev/null 2>&1; then
    echo "Updating Thunderbird..."
    if dpkg -l thunderbird >/dev/null 2>&1; then
      sudo apt-get install --only-upgrade -y thunderbird >/dev/null 2>&1 && \
      echo "Thunderbird (APT) updated." || echo "Warning: Failed to update Thunderbird (APT)." >&2
    elif snap list thunderbird >/dev/null 2>&1; then
      sudo snap refresh thunderbird >/dev/null 2>&1 && \
      echo "Thunderbird (Snap) updated." || echo "Warning: Failed to update Thunderbird (Snap)." >&2
    elif flatpak list | grep -q org.mozilla.Thunderbird; then
      sudo flatpak update -y org.mozilla.Thunderbird >/dev/null 2>&1 && \
      echo "Thunderbird (Flatpak) updated." || echo "Warning: Failed to update Thunderbird (Flatpak)." >&2
    fi
  else
    echo "Thunderbird not found; skipping."
  fi

  echo "Browser and mail client update check complete."
}
