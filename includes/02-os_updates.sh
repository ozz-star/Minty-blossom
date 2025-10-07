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
  : <<'AI_BLOCK'
EXPLANATION
Update package indexes from all configured sources.

AI_PROMPT
Return only Bash code (no markdown, no prose).
Requirements:
- Run the Debian-family command to refresh package lists (apt).
- Show a short status message before/after.
- Non-interactive is fine; do not upgrade here.
AI_BLOCK
}

# ------------------------------------------------------------
# apt --fix-broken install
# ------------------------------------------------------------
osu_fix_broken_packages () {
  : <<'AI_BLOCK'
EXPLANATION
Attempt to fix broken package dependencies.

AI_PROMPT
Return only Bash code (no markdown, no prose).
Requirements:
- Run the Debian-family command to fix broken packages.
- Use a non-interactive approach suitable for scripts.
- Print a short status line on completion.
AI_BLOCK
}

# ------------------------------------------------------------
# apt-mark: unhold all currently held packages
# ------------------------------------------------------------
osu_unhold_packages () {
  : <<'AI_BLOCK'
EXPLANATION
Unhold every package currently marked as "hold" on Debian/Ubuntu/Mint. Do not rely on a predefined list.

AI_PROMPT
Return only Bash code (no markdown, no prose).
Requirements:
- Query the list of held packages using the appropriate apt-mark command.
- If none are held, print: "No held packages found." and return.
- Iterate over each held package name safely (handle spaces/newlines robustly).
- For each package:
  - Unhold it via the apt-mark command (use sudo where appropriate).
  - Print a confirmation line: "Unheld: <package>".
- Use non-interactive behavior; if unholding one package fails, continue with the rest and print a short warning.
AI_BLOCK
}

