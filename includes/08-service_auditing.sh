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
          if sudo DEBIAN_FRONTEND=noninteractive apt-get -y -qq purge "$pkg" >/dev/null 2>&1; then
            echo "Purged $pkg"
          else
            echo "Error: purge of $pkg failed; attempting to recover and retry" >&2
            # Try to fix dpkg state, then retry once
            if sudo dpkg --configure -a >/dev/null 2>&1; then
              if sudo DEBIAN_FRONTEND=noninteractive apt-get -y -qq purge "$pkg" >/dev/null 2>&1; then
                echo "Purged $pkg on retry"
              else
                echo "Final failure: could not purge $pkg" >&2
              fi
            else
              echo "Warning: dpkg --configure -a failed; cannot retry purge for $pkg" >&2
            fi
          fi
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
