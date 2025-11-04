#!/usr/bin/env bash
set -euo pipefail

invoke_application_updates () {
  echo -e "${CYAN}[Application Updates] Start${NC}"

  au_apt_update_indexes
  au_apt_full_upgrade
  au_snap_refresh_all
  au_flatpak_update_all
  au_update_browsers_and_mail

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
# Update Firefox, Chrome, and Thunderbird if found
# ------------------------------------------------------------
au_update_browsers_and_mail () {
  echo "Checking for browsers and mail clients to update..."

  # Firefox
  if command -v firefox >/dev/null 2>&1; then
    echo "Updating Firefox..."
    if command -v apt-get >/dev/null 2>&1 && dpkg -l | grep -q '^ii\s\+firefox'; then
      sudo apt-get install --only-upgrade -y firefox >/dev/null 2>&1 && echo "Firefox updated via APT."
    elif command -v snap >/dev/null 2>&1 && snap list | grep -q '^firefox'; then
      sudo snap refresh firefox >/dev/null 2>&1 && echo "Firefox updated via Snap."
    elif command -v flatpak >/dev/null 2>&1 && flatpak list | grep -q 'org.mozilla.firefox'; then
      sudo flatpak update -y org.mozilla.firefox >/dev/null 2>&1 && echo "Firefox updated via Flatpak."
    else
      echo "Firefox found, but update method not detected."
    fi
  fi

  # Google Chrome
  if command -v google-chrome >/dev/null 2>&1; then
    echo "Updating Google Chrome..."
    if command -v apt-get >/dev/null 2>&1 && dpkg -l | grep -q '^ii\s\+google-chrome'; then
      sudo apt-get install --only-upgrade -y google-chrome-stable >/dev/null 2>&1 && echo "Google Chrome updated via APT."
    elif command -v flatpak >/dev/null 2>&1 && flatpak list | grep -q 'com.google.Chrome'; then
      sudo flatpak update -y com.google.Chrome >/dev/null 2>&1 && echo "Google Chrome updated via Flatpak."
    else
      echo "Google Chrome found, but update method not detected."
    fi
  fi

 #!/usr/bin/env bash
set -euo pipefail

invoke_application_updates () {
  echo -e "${CYAN}[Application Updates] Start${NC}"

  au_apt_update_indexes
  au_apt_full_upgrade
  au_snap_refresh_all
  au_flatpak_update_all
  au_update_browsers_and_mail

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
# Update Firefox, Chrome, and Thunderbird if found
# ------------------------------------------------------------
au_update_browsers_and_mail () {
  echo "Checking for browsers and mail clients to update..."

  # Firefox
  if command -v firefox >/dev/null 2>&1; then
    echo "Updating Firefox..."
    if command -v apt-get >/dev/null 2>&1 && dpkg -l | grep -q '^ii\s\+firefox'; then
      sudo apt-get install --only-upgrade -y firefox >/dev/null 2>&1 && echo "Firefox updated via APT."
    elif command -v snap >/dev/null 2>&1 && snap list | grep -q '^firefox'; then
      sudo snap refresh firefox >/dev/null 2>&1 && echo "Firefox updated via Snap."
    elif command -v flatpak >/dev/null 2>&1 && flatpak list | grep -q 'org.mozilla.firefox'; then
      sudo flatpak update -y org.mozilla.firefox >/dev/null 2>&1 && echo "Firefox updated via Flatpak."
    else
      echo "Firefox found, but update method not detected."
    fi
  fi

  # Google Chrome
  if command -v google-chrome >/dev/null 2>&1; then
    echo "Updating Google Chrome..."
    if command -v apt-get >/dev/null 2>&1 && dpkg -l | grep -q '^ii\s\+google-chrome'; then
      sudo apt-get install --only-upgrade -y google-chrome-stable >/dev/null 2>&1 && echo "Google Chrome updated via APT."
    elif command -v flatpak >/dev/null 2>&1 && flatpak list | grep -q 'com.google.Chrome'; then
      sudo flatpak update -y com.google.Chrome >/dev/null 2>&1 && echo "Google Chrome updated via Flatpak."
    else
      echo "Google Chrome found, but update method not detected."
    fi
  fi

  # Thunderbird
  if command -v thunderbird >/dev/null 2>&1; then
    echo "Updating Thunderbird..."
    if command -v apt-get >/dev/null 2>&1 && dpkg -l | grep -q '^ii\s\+thunderbird'; then
      sudo apt-get install --only-upgrade -y thunderbird >/dev/null 2>&1 && echo "Thunderbird updated via APT."
    elif command -v snap >/dev/null 2>&1 && snap list | grep -q '^thunderbird'; then
      sudo snap refresh thunderbird >/dev/null 2>&1 && echo "Thunderbird updated via Snap."
    elif command -v flatpak >/dev/null 2>&1 && flatpak list | grep -q 'org.mozilla.Thunderbird'; then
      sudo flatpak update -y org.mozilla.Thunderbird >/dev/null 2>&1 && echo "Thunderbird updated via Flatpak."
    else
      echo "Thunderbird found, but update method not detected."
    fi
  fi

  echo "Browser/mail update check complete."
}
