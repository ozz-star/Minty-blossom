#!/usr/bin/env bash
set -euo pipefail

invoke_account_policy () {
  echo -e "${CYAN}[Account Policy] Start${NC}"

  ap_secure_login_defs
  ap_pam_pwquality_inline
  ap_pwquality_conf_file
  ap_lockout_faillock

  echo -e "${CYAN}[Account Policy] Done${NC}"
}

# -------------------------------------------------------------------
# /etc/login.defs hardening
# -------------------------------------------------------------------
ap_secure_login_defs () {
  target=/etc/login.defs
  ts=$(date +%Y%m%d%H%M%S)
  if [ -f "$target" ]; then
    sudo cp -a "$target" "${target}.bak.${ts}"
    echo "Backup created: ${target}.bak.${ts}"
  else
    sudo touch "$target"
    echo "Created empty $target"
  fi

  set_directive() {
    key="$1"
    value="$2"
    # If key exists (commented or not), replace the line; otherwise append
    if grep -Eq "^\s*#?\s*${key}\b" "$target"; then
      sudo sed -ri "s|^\s*#?\s*(${key})\b.*|${key} ${value}|g" "$target"
      echo "Set ${key} to ${value}"
    else
      echo "${key} ${value}" | sudo tee -a "$target" > /dev/null
      echo "Appended ${key} ${value}"
    fi
  }

  set_directive PASS_MAX_DAYS 60
  set_directive PASS_MIN_DAYS 10
  set_directive PASS_WARN_AGE 14
  set_directive UMASK 077

  return 0
}

# -------------------------------------------------------------------
# Insert pam_pwquality inline in common-password
# -------------------------------------------------------------------
ap_pam_pwquality_inline () {
  local target="/etc/pam.d/common-password"
  local line_to_add="password requisite pam_pwquality.so retry=3 minlen=10 difok=5 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1"

  if [ ! -f "$target" ]; then
    echo "Warning: $target not found. Skipping pwquality rule." >&2
    return 1
  fi

  # Create a timestamped backup
  local ts
  ts=$(date +%Y%m%d%H%M%S)
  sudo cp -a "$target" "${target}.bak.${ts}"

  # Check if the exact line already exists (ignoring leading/trailing whitespace)
  if sudo grep -q -x "[[:space:]]*${line_to_add}[[:space:]]*" "$target"; then
    echo "Password quality rule already in place in $target."
    return 0
  fi

  # If not, remove any other pam_pwquality.so lines to ensure idempotency
  sudo sed -i '/pam_pwquality.so/d' "$target"

  # Insert the desired line before the first occurrence of pam_unix.so
  # The `i\` command in sed inserts the text before the matched line.
  if sudo sed -i '/pam_unix.so/i '"$line_to_add" "$target"; then
    echo "Inserted password quality rule into $target."
  else
    echo "Warning: Failed to insert password quality rule into $target." >&2
    return 1
  fi

  return 0
}

# -------------------------------------------------------------------
# Configure /etc/security/pwquality.conf
# -------------------------------------------------------------------
ap_pwquality_conf_file () {
  target=/etc/security/pwquality.conf
  ts=$(date +%Y%m%d%H%M%S)

  if [ -f "$target" ]; then
    sudo cp -a "$target" "${target}.bak.${ts}"
    echo "Backup created: ${target}.bak.${ts}"
  else
    sudo touch "$target"
    echo "Created empty $target"
  fi

  declare -A wanted=(
    [minlen]=10 [minclass]=2 [maxrepeat]=2 [maxclassrepeat]=6
    [lcredit]=-1 [ucredit]=-1 [dcredit]=-1 [ocredit]=-1
    [maxsequence]=2 [difok]=5 [gecoscheck]=1
  )

  for k in "${!wanted[@]}"; do
    v=${wanted[$k]}
    if sudo grep -Eq "^[[:space:]]*#?[[:space:]]*${k}\b" "$target"; then
      sudo sed -ri "s|^[[:space:]]*#?[[:space:]]*(${k})\b.*|${k} = ${v}|g" "$target"
      echo "Set ${k} = ${v}"
    else
      echo "${k} = ${v}" | sudo tee -a "$target" > /dev/null
      echo "Appended ${k} = ${v}"
    fi
  done

  echo "pwquality configuration applied."
  return 0
}

# -------------------------------------------------------------------
# Configure pam_faillock in common-auth/common-account
# -------------------------------------------------------------------
ap_lockout_faillock () {
  # Idempotent insertion of pam_faillock lines into PAM config files
  set -u

  auth_file=/etc/pam.d/common-auth
  acct_file=/etc/pam.d/common-account
  ts=$(date +%Y%m%d%H%M%S)

  make_backup() {
    local f=$1
    if [ -f "$f" ]; then
      sudo cp -a "$f" "${f}.bak.${ts}"
      echo "Backup created: ${f}.bak.${ts}"
    else
      sudo touch "$f"
      echo "Created empty $f"
      sudo cp -a "$f" "${f}.bak.${ts}"
      echo "Backup created: ${f}.bak.${ts}"
    fi
  }

  make_backup "$auth_file"
  make_backup "$acct_file"

  # Desired exact lines (use single spaces for matching/creation)
  preauth_line='auth        required      pam_faillock.so preauth'
  authfail_line='auth        [default=die] pam_faillock.so authfail'
  authsucc_line='auth        sufficient    pam_faillock.so authsucc'
  account_line='account     required      pam_faillock.so'

  # Ensure lines exist exactly once in common-auth
  # Remove any existing pam_faillock lines to avoid duplicates, but keep a copy in the backup
  sudo awk -v pre="$preauth_line" -v fail="$authfail_line" -v succ="$authsucc_line" \
    'BEGIN{found_pre=0; found_fail=0; found_succ=0}
    {
      # normalize tabs to spaces for matching
      line=$0
      if (line ~ /pam_faillock.so/) {
        # skip existing pam_faillock lines (we will reinsert exactly once later)
        next
      }
      print $0
    }
    END{
      # We will not print here; insertion handled later by writing to temp file
    }' "$auth_file" > "${auth_file}.tmp.$$"

  # Insert preauth before first pam_unix.so, then authfail immediately after pam_unix.so
  # If pam_unix.so not found, append at end with a note
  inserted_pre=0
  inserted_fail=0
  inserted_succ=0

  # Build a new version of common-auth by reading the temp file and inserting lines
  awk -v pre="$preauth_line" -v fail="$authfail_line" -v succ="$authsucc_line" '
    BEGIN{ pre_inserted=0; fail_inserted=0 }
    {
      print $0
      if (!pre_inserted && $0 ~ /pam_unix.so/) {
        print pre
        pre_inserted=1
      }
      if (pre_inserted && $0 ~ /pam_unix.so/ && !fail_inserted) {
        print fail
        fail_inserted=1
      }
    }
    END{
      if (!pre_inserted) {
        print pre
      }
      if (!fail_inserted) {
        print fail
      }
      # Always ensure authsucc is present once
      print succ
    }' "${auth_file}.tmp.$$" > "${auth_file}.new.$$"

  # Move the new file into place
  sudo mv "${auth_file}.new.$$" "$auth_file"
  rm -f "${auth_file}.tmp.$$"

  # Provide confirmations for common-auth: check if lines present exactly once
  count_line() {
    local line="$1" file="$2"
    sudo awk -v match="$line" '
      function trim(s){ gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      { if (trim($0)==match) c++ }
      END{ print (c?c:0) }
    ' "$file"
  }

  c_pre=$(count_line "$preauth_line" "$auth_file")
  c_fail=$(count_line "$authfail_line" "$auth_file")
  c_succ=$(count_line "$authsucc_line" "$auth_file")

  if [ "$c_pre" -eq 1 ]; then
    echo "Present: preauth line in $auth_file"
  else
    echo "Warning: preauth lines count=$c_pre in $auth_file"
  fi
  if [ "$c_fail" -eq 1 ]; then
    echo "Present: authfail line in $auth_file"
  else
    echo "Warning: authfail lines count=$c_fail in $auth_file"
  fi
  if [ "$c_succ" -eq 1 ]; then
    echo "Present: authsucc line in $auth_file"
  else
    echo "Warning: authsucc lines count=$c_succ in $auth_file"
  fi

  # Ensure account line in common-account exactly once
  # Remove existing pam_faillock account lines and re-add exactly once
  sudo awk '!/pam_faillock.so/ {print $0}' "$acct_file" > "${acct_file}.tmp.$$"
  # Append the exact account line
  echo "$account_line" | sudo tee -a "${acct_file}.tmp.$$" > /dev/null
  sudo mv "${acct_file}.tmp.$$" "$acct_file"

  c_acc=$(count_line "$account_line" "$acct_file")
  if [ "$c_acc" -eq 1 ]; then
    echo "Present: account line in $acct_file"
  else
    echo "Warning: account lines count=$c_acc in $acct_file"
  fi

  return 0
}
