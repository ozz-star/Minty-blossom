#!/usr/bin/env bash
set -euo pipefail

invoke_prohibited_files () {
  echo -e "${CYAN}[Prohibited Files] Start${NC}"

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
  # Iterate over extensions (whitespace-separated)
  for ext in $FILE_EXTENSIONS; do
    echo "Searching and removing files with .$ext extension..."
    # find from /, suppress permission errors, only regular files
    # Use -iname to be case-insensitive for extensions
    while IFS= read -r -d '' file; do
      if sudo rm -f -- "$file" >/dev/null 2>&1; then
        total=$((total+1))
      else
        echo "Warning: failed to remove $file" >&2
        # continue on errors
      fi
    done < <(find / -xdev -type f -iname "*.${ext}" -print0 2>/dev/null)
  done

  echo "Removed $total files matching prohibited extensions."
}
