#!/usr/bin/env bash
set -euo pipefail

invoke_os_updates () {
  echo -e "${CYAN}[OS Updates] Start${NC}"

  osu_update_sources_for_distro
  osu_apt_update
  osu_fix_broken_packages
  osu_unhold_packages

  echo -e "${CYAN}[OS Updates] Done${NC}"
}

# ------------------------------------------------------------
# Update APT sources based on distro/codename (Debian family)
# ------------------------------------------------------------
osu_update_sources_for_distro () {
  # Ensure DISTRO and CODENAME are set in the environment
  if [ -z "${DISTRO:-}" ] || [ -z "${CODENAME:-}" ]; then
    echo "osu_update_sources_for_distro: DISTRO and CODENAME must be set in the environment." >&2
    return 1
  fi

  case "${DISTRO,,}" in
    ubuntu)
      SRC_FILE="/etc/apt/sources.list"
      BACKUP_FILE="${SRC_FILE}.bak"
      if [ -f "$SRC_FILE" ]; then
        sudo cp -a "$SRC_FILE" "$BACKUP_FILE"
        echo "Backed up $SRC_FILE to $BACKUP_FILE"
      fi

      # Prepare the new sources content
      NEW_SOURCES="deb http://archive.ubuntu.com/ubuntu/ ${CODENAME} main universe multiverse\n"
      NEW_SOURCES+="deb http://archive.ubuntu.com/ubuntu/ ${CODENAME}-updates main universe multiverse\n"
      NEW_SOURCES+="deb http://security.ubuntu.com/ubuntu/ ${CODENAME}-security main universe multiverse\n"
      NEW_SOURCES+="deb http://archive.ubuntu.com/ubuntu/ ${CODENAME}-backports main universe multiverse\n"

      # Write using sudo tee to ensure safe write
      printf "%b" "$NEW_SOURCES" | sudo tee "$SRC_FILE" > /dev/null
      sudo chmod 644 "$SRC_FILE" || true
      echo "Ubuntu detected; /etc/apt/sources.list overwritten for codename '${CODENAME}'."
      ;;

    "linuxmint"|mint)
      # Source os-release to get UBUNTU_CODENAME
      if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
      fi

      UB_CODENAME="${UBUNTU_CODENAME:-}"
      if [ -z "$UB_CODENAME" ]; then
        echo "Linux Mint detected but UBUNTU_CODENAME not found in /etc/os-release; aborting." >&2
        return 1
      fi

      MINT_SRC_DIR="/etc/apt/sources.list.d"
      MINT_SRC_FILE="$MINT_SRC_DIR/official-package-repositories.list"
      MINT_BACKUP="${MINT_SRC_FILE}.bak"

      if [ -f "$MINT_SRC_FILE" ]; then
        sudo cp -a "$MINT_SRC_FILE" "$MINT_BACKUP"
        echo "Backed up $MINT_SRC_FILE to $MINT_BACKUP"
      fi

      # Standard Mint repository line (uses Mint codename in CODENAME)
      MINT_LINE="deb http://packages.linuxmint.com ${CODENAME} main upstream import backport"

      # Ubuntu lines using UBUNTU_CODENAME
      UB_LINES="deb http://archive.ubuntu.com/ubuntu/ ${UB_CODENAME} main universe multiverse\n"
      UB_LINES+="deb http://archive.ubuntu.com/ubuntu/ ${UB_CODENAME}-updates main universe multiverse\n"
      UB_LINES+="deb http://security.ubuntu.com/ubuntu/ ${UB_CODENAME}-security main universe multiverse\n"
      UB_LINES+="deb http://archive.ubuntu.com/ubuntu/ ${UB_CODENAME}-backports main universe multiverse\n"

      # Combine and write
      printf "%s\n%b" "$MINT_LINE" "$UB_LINES" | sudo tee "$MINT_SRC_FILE" > /dev/null
      sudo chmod 644 "$MINT_SRC_FILE" || true
      echo "Linux Mint detected; wrote $MINT_SRC_FILE with Mint codename '${CODENAME}' and Ubuntu codename '${UB_CODENAME}'."
      ;;

    debian)
      echo "Debian detected; leaving sources as-is."
      ;;

    *)
      echo "Unrecognized DISTRO '$DISTRO'; no changes made."
      ;;
  esac
}

# ------------------------------------------------------------
# apt update
# ------------------------------------------------------------
osu_apt_update () {
  echo "Updating package lists..."
  if sudo apt-get update -qq; then
    echo "Package lists updated."
  else
    echo "Failed to update package lists." >&2
    return 1
  fi
}

# ------------------------------------------------------------
# apt --fix-broken install
# ------------------------------------------------------------
osu_fix_broken_packages () {
  # Attempt to fix broken package dependencies non-interactively.
  # Use DEBIAN_FRONTEND=noninteractive and apt-get --fix-broken install with -y.
  echo "Attempting to fix broken packages..."
  if sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold --fix-broken install -yqq; then
    echo "Broken packages fixed."
    return 0
  else
    echo "Warning: failed to fully fix broken packages." >&2
    return 1
  fi
}

# ------------------------------------------------------------
# apt-mark: unhold all currently held packages
# ------------------------------------------------------------
osu_unhold_packages () {
  # Query held packages and unhold them one-by-one.
  held_list=$(apt-mark showhold 2>/dev/null) || {
    echo "Warning: failed to query held packages." >&2
    return 1
  }

  if [ -z "${held_list}" ]; then
    echo "No held packages found."
    return 0
  fi

  # Read into an array safely to handle spaces/newlines robustly
  IFS=$'\n' read -r -d '' -a held_array <<< "${held_list}"$'\0'

  for pkg in "${held_array[@]}"; do
    # skip empty entries
    [ -z "${pkg}" ] && continue
    if sudo apt-mark unhold -- "${pkg}" >/dev/null 2>&1; then
      echo "Unheld: ${pkg}"
    else
      echo "Warning: failed to unhold: ${pkg}" >&2
      # continue with next package
    fi
  done

  return 0
}

