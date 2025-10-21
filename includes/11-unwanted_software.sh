#!/usr/bin/env bash
set -euo pipefail

# Color support check (Mint sometimes lacks tput colors by default)
if command -v tput &>/dev/null; then
  CYAN=$(tput setaf 6)
  NC=$(tput sgr0)
else
  CYAN=""
  NC=""
fi

invoke_unwanted_software () {
  echo -e "${CYAN}[Unwanted Software] Start${NC}"
  us_purge_unwanted_software
  echo -e "${CYAN}[Unwanted Software] Done${NC}"
}

# -------------------------------------------------------------------
# Purge unwanted software listed in $UNWANTED_SOFTWARE, then autoremove
# -------------------------------------------------------------------
us_purge_unwanted_software () {
  if [ -z "${UNWANTED_SOFTWARE:-}" ]; then
    echo "No unwanted software configured."
    return 0
  fi

  # Iterate over entries; support space-separated string or array-like input
  for name in $UNWANTED_SOFTWARE; do
    echo "Purging unwanted package: $name..."

    # Avoid matching Mint meta packages (like mint-meta-core)
    mapfile -t matches < <(
      dpkg-query -W -f='${Package}\n' 2>/dev/null |
        grep -E "^${name}([:-].*)?$" |
        grep -vE '^mint-meta-' || true
    )

    if [ ${#matches[@]} -eq 0 ]; then
      echo "No installed packages matching $name found; skipping."
      continue
    fi

    # Purge each matched package name
    for pkg in "${matches[@]}"; do
      if sudo DEBIAN_FRONTEND=noninteractive apt -y -qq purge "$pkg" >/dev/null 2>&1; then
        echo "Purged $pkg"
      else
        echo "Warning: purge of $pkg failed; attempting dpkg --configure -a and retry" >&2
        if sudo dpkg --configure -a >/dev/null 2>&1; then
          if sudo DEBIAN_FRONTEND=noninteractive apt -y -qq purge "$pkg" >/dev/null 2>&1; then
            echo "Purged $pkg on retry"
          else
            echo "Final failure: could not purge $pkg" >&2
          fi
        else
          echo "Warning: dpkg --configure -a failed; cannot retry purge for $pkg" >&2
        fi
      fi
    done
  done

  # Autoremove unneeded packages
  if sudo apt -y -qq autoremove >/dev/null 2>&1; then
    echo "Autoremove complete."
  else
    echo "Warning: apt autoremove failed; continuing." >&2
  fi
}
