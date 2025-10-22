#!/usr/bin/env bash
set -euo pipefail

invoke_prohibited_files () {
  echo -e "${CYAN}[Prohibited Files] Start${NC}"

  # Interactive category selector
  echo "Select prohibited file category to remove:" 
  echo "1) MP3 files (.mp3)"
  echo "2) OGG files (.ogg)"
  echo "3) BOTH MP3 and OGG"
  echo "q) Quit"
  read -rp $'Enter choice: ' choice
  case "$choice" in
    1) FILE_EXTENSIONS="mp3";;
    2) FILE_EXTENSIONS="ogg";;
    3) FILE_EXTENSIONS="mp3 ogg";;
    q|Q) echo "Skipping prohibited files removal."; return 0;;
    *) echo "Invalid choice"; return 1;;
  esac

  pf_remove_prohibited_files

  echo -e "${CYAN}[Prohibited Files] Done${NC}"
}

# -------------------------------------------------------------------
# Remove files matching extensions from $FILE_EXTENSIONS
# -------------------------------------------------------------------
pf_remove_prohibited_files () {
  # Ensure FILE_EXTENSIONS is set and is an array-like list
  if [ -z "${FILE_EXTENSIONS:-}" ]; then
    echo "No file extensions configured."
    return 0
  fi
  total=0
  removed_list=""

  # Allow DRY_RUN env var to list files without deleting
  dry_run=${DRY_RUN:-0}

  # Confirm before deletion when running interactively and not a dry run
  if [ "$dry_run" -ne 1 ]; then
    read -rp $'This will permanently remove matching files from /. Proceed? (y/N) ' confirm || confirm=N
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
      echo "Aborting removal."; return 0
    fi
  else
    echo "DRY RUN enabled: listing matching files only (no deletions)."
  fi

  # Iterate over extensions (whitespace-separated)
  for ext in $FILE_EXTENSIONS; do
    echo "Searching for .$ext files..."
    # find from /, suppress permission errors, only regular files
    # Use -iname to be case-insensitive for extensions
    while IFS= read -r -d '' file; do
      if [ "$dry_run" -eq 1 ]; then
        echo "DRY: $file"
        removed_list+="$file\n"
        total=$((total+1))
        continue
      fi

      if sudo rm -f -- "$file" >/dev/null 2>&1; then
        echo "Removed: $file"
        removed_list+="$file\n"
        total=$((total+1))
      else
        echo "Warning: failed to remove $file" >&2
        # continue on errors
      fi
    done < <(find / -xdev -type f -iname "*.${ext}" -print0 2>/dev/null)
  done

  echo "Removed $total files matching prohibited extensions."
  if [ "$total" -gt 0 ]; then
    # Print a short summary (first 20 files)
    echo "Sample removed files:"
    printf "%b" "$removed_list" | sed -n '1,20p'
  fi
}
