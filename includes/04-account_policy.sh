#!/usr/bin/env bash
set -euo pipefail

invoke_account_policy () {
  # Interactive submenu for account policy sections
  declare -A AP_COMPLETED=()
  while true; do
    echo -e "${CYAN}\n[Account Policy] Menu${NC}"
    if [ "${AP_COMPLETED[1]:-0}" = "1" ]; then printf "%b1) /etc/login.defs hardening%b\n" "$GREEN" "$NC"; else printf "1) /etc/login.defs hardening\n"; fi
    if [ "${AP_COMPLETED[2]:-0}" = "1" ]; then printf "%b2) Insert pam_pwquality into common-password%b\n" "$GREEN" "$NC"; else printf "2) Insert pam_pwquality into common-password\n"; fi
    if [ "${AP_COMPLETED[3]:-0}" = "1" ]; then printf "%b3) Configure /etc/security/pwquality.conf%b\n" "$GREEN" "$NC"; else printf "3) Configure /etc/security/pwquality.conf\n"; fi
    if [ "${AP_COMPLETED[4]:-0}" = "1" ]; then printf "%b4) Configure pam_faillock (lockout)%b\n" "$GREEN" "$NC"; else printf "4) Configure pam_faillock (lockout)\n"; fi
    if [ "${AP_COMPLETED[5]:-0}" = "1" ]; then printf "%b5) Disallow blank passwords (PAM/SSH)%b\n" "$GREEN" "$NC"; else printf "5) Disallow blank passwords (PAM/SSH)\n"; fi
    printf "a) Run ALL of the above in sequence\n"
    printf "b) Back to main menu\n"

    read -rp $'Enter choice: ' choice
    case "$choice" in
      1)
        echo -e "${GREEN}[Account Policy] Running: /etc/login.defs hardening${NC}"
        ap_secure_login_defs; AP_COMPLETED[1]=1
        ;;
      2)
        echo -e "${GREEN}[Account Policy] Running: Insert pam_pwquality into common-password${NC}"
        ap_pam_pwquality_inline; AP_COMPLETED[2]=1
        ;;
      3)
        echo -e "${GREEN}[Account Policy] Running: Configure /etc/security/pwquality.conf${NC}"
        ap_pwquality_conf_file; AP_COMPLETED[3]=1
        ;;
      4)
        echo -e "${GREEN}[Account Policy] Running: Configure pam_faillock (lockout)${NC}"
        ap_lockout_faillock; AP_COMPLETED[4]=1
        ;;
      5)
        echo -e "${GREEN}[Account Policy] Running: Disallow blank passwords (PAM/SSH)${NC}"
        ap_disallow_blank_passwords; AP_COMPLETED[5]=1
        ;;
      a|A)
        echo -e "${GREEN}[Account Policy] Running all sections...${NC}"
        ap_secure_login_defs; AP_COMPLETED[1]=1
        ap_pam_pwquality_inline; AP_COMPLETED[2]=1
        ap_pwquality_conf_file; AP_COMPLETED[3]=1
        ap_lockout_faillock; AP_COMPLETED[4]=1
        ap_disallow_blank_passwords; AP_COMPLETED[5]=1
        echo -e "${GREEN}[Account Policy] Completed all sections.${NC}"
        ;;
      b|B|q|Q)
        echo -e "${CYAN}[Account Policy] Returning to main menu.${NC}"
        break
        ;;
      *)
        echo -e "${C_RED}Invalid option${C_RESET}"
        ;;
    esac
  done
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
  # Ensure a secure password hashing algorithm is configured
  # ENCRYPT_METHOD controls the hash used for new passwords (SHA512 is recommended)
  set_directive ENCRYPT_METHOD SHA512
  # Optionally set SHA rounds (if supported) for additional work factor
  set_directive SHA_CRYPT_MIN_ROUNDS 1000

  # Ensure PAM configuration uses sha512 for pam_unix.so (common-password/system-auth)
  ap_ensure_password_hashing
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

<<<<<<< HEAD
  # Idempotent: remove any existing lines referencing pam_pwquality or pam_cracklib
  sudo sed -i '/pam_pwquality.so/d;/pam_cracklib.so/d' "$target"
  # Insert the desired line before the first occurrence of pam_unix.so in the password stack
  # Use awk to reliably insert the line before the first pam_unix.so occurrence and be portable
  tmp_new="${target}.new.$$"
  sudo awk -v ins="$line_to_add" 'BEGIN{inserted=0} {
      print $0
      if (!inserted && $0 ~ /pam_unix.so/) {
        # insert the pwquality/cracklib line right before pam_unix.so
        print ins
        inserted=1
      }
    }
    END{ if (!inserted) print ins }' "$target" > "$tmp_new"
  sudo mv "$tmp_new" "$target"

  echo "Inserted password quality line into $target"
=======
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

>>>>>>> 6478be63185535fab35579c6a735eda24440c54c
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
  # Idempotent insertion of lockout lines into PAM config files
  set -u

  auth_file=/etc/pam.d/common-auth
  acct_file=/etc/pam.d/common-account
  ts=$(date +%Y%m%d%H%M%S)

  # detect available module: prefer pam_faillock, else pam_tally2
  use_faillock=0
  use_tally2=0
  faillock_paths=(/lib/security/pam_faillock.so /lib64/security/pam_faillock.so /usr/lib/security/pam_faillock.so /lib/x86_64-linux-gnu/security/pam_faillock.so)
  tally_paths=(/lib/security/pam_tally2.so /lib64/security/pam_tally2.so /usr/lib/security/pam_tally2.so /lib/x86_64-linux-gnu/security/pam_tally2.so)

  for p in "${faillock_paths[@]}"; do
    if [ -e "$p" ]; then use_faillock=1; break; fi
  done
  if [ "$use_faillock" -eq 0 ]; then
    for p in "${tally_paths[@]}"; do
      if [ -e "$p" ]; then use_tally2=1; break; fi
    done
  fi

  if [ "$use_faillock" -eq 0 ] && [ "$use_tally2" -eq 0 ]; then
    echo "Warning: neither pam_faillock nor pam_tally2 found on this system; skipping lockout configuration." >&2
    return 1
  fi

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

  # helper to count exact lines
  count_line() {
    local line="$1" file="$2"
    sudo grep -xF -- "$line" "$file" 2>/dev/null | wc -l || echo 0
  }

  if [ "$use_faillock" -eq 1 ]; then
    # Desired exact lines for faillock
    preauth_line='auth        required      pam_faillock.so preauth'
    authfail_line='auth        [default=die] pam_faillock.so authfail'
    authsucc_line='auth        sufficient    pam_faillock.so authsucc'
    account_line='account     required      pam_faillock.so'

    # Remove any existing faillock lines and rebuild auth_file with proper insertions
    sudo grep -v 'pam_faillock.so' "$auth_file" > "${auth_file}.tmp.$$" || sudo cp -a "$auth_file" "${auth_file}.tmp.$$"

    awk -v pre="$preauth_line" -v fail="$authfail_line" -v succ="$authsucc_line" 'BEGIN{pre_inserted=0; fail_inserted=0} { print $0; if (!pre_inserted && $0 ~ /pam_unix.so/) { print pre; pre_inserted=1 } if (pre_inserted && $0 ~ /pam_unix.so/ && !fail_inserted) { print fail; fail_inserted=1 }} END{ if (!pre_inserted) print pre; if (!fail_inserted) print fail; print succ }' "${auth_file}.tmp.$$" > "${auth_file}.new.$$"

    sudo mv "${auth_file}.new.$$" "$auth_file"
    rm -f "${auth_file}.tmp.$$"

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
    sudo awk '!/pam_faillock.so/ {print $0}' "$acct_file" > "${acct_file}.tmp.$$"
    echo "$account_line" | sudo tee -a "${acct_file}.tmp.$$" > /dev/null
    sudo mv "${acct_file}.tmp.$$" "$acct_file"
    c_acc=$(count_line "$account_line" "$acct_file")
    if [ "$c_acc" -eq 1 ]; then
      echo "Present: account line in $acct_file"
    else
      echo "Warning: account lines count=$c_acc in $acct_file"
    fi

  elif [ "$use_tally2" -eq 1 ]; then
    # Fallback to pam_tally2: insert compatible lines
    preauth_line='auth required pam_tally2.so onerr=fail deny=5 even_deny_root unlock_time=900'
    account_line='account required pam_tally2.so'

    # Remove existing pam_tally2 lines from auth_file and insert before pam_unix.so
    sudo grep -v 'pam_tally2.so' "$auth_file" > "${auth_file}.tmp.$$" || sudo cp -a "$auth_file" "${auth_file}.tmp.$$"

    awk -v pre="$preauth_line" 'BEGIN{inserted=0} { print $0; if (!inserted && $0 ~ /pam_unix.so/) { print pre; inserted=1 } } END{ if (!inserted) print pre }' "${auth_file}.tmp.$$" > "${auth_file}.new.$$"

    sudo mv "${auth_file}.new.$$" "$auth_file"
    rm -f "${auth_file}.tmp.$$"

    c_pre=$(count_line "$preauth_line" "$auth_file")
    if [ "$c_pre" -eq 1 ]; then
      echo "Present: auth line in $auth_file for pam_tally2"
    else
      echo "Warning: auth lines count=$c_pre in $auth_file for pam_tally2"
    fi

    # Ensure account line in acct_file exactly once
    sudo awk '!/pam_tally2.so/ {print $0}' "$acct_file" > "${acct_file}.tmp.$$"
    echo "$account_line" | sudo tee -a "${acct_file}.tmp.$$" > /dev/null
    sudo mv "${acct_file}.tmp.$$" "$acct_file"
    c_acc=$(count_line "$account_line" "$acct_file")
    if [ "$c_acc" -eq 1 ]; then
      echo "Present: account line in $acct_file for pam_tally2"
    else
      echo "Warning: account lines count=$c_acc in $acct_file for pam_tally2"
    fi

  fi

  return 0
}


# -------------------------------------------------------------------
# Ensure blank (empty) passwords are not allowed via PAM/SSH
# -------------------------------------------------------------------
ap_disallow_blank_passwords () {
  ts=$(date +%Y%m%d%H%M%S)

  # PAM files to sanitize
  pam_files=(/etc/pam.d/common-auth /etc/pam.d/common-password /etc/pam.d/sshd)
  for f in "${pam_files[@]}"; do
    if [ -f "$f" ]; then
      sudo cp -a "$f" "${f}.bak.${ts}"
      echo "Backup created: ${f}.bak.${ts}"
      # Remove the 'nullok' token which allows empty passwords
      sudo sed -ri 's/\bnullok\b//g' "$f"
      # Collapse multiple spaces/tabs to single space for cleanliness
      sudo sed -ri 's/[[:space:]]+/ /g' "$f"
      echo "Sanitized $f (removed nullok tokens)"
    fi
  done

  # SSH: ensure PermitEmptyPasswords no
  sshf=/etc/ssh/sshd_config
  if [ -f "$sshf" ]; then
    sudo cp -a "$sshf" "${sshf}.bak.${ts}"
    echo "Backup created: ${sshf}.bak.${ts}"
    if sudo grep -q -E '^\s*PermitEmptyPasswords\b' "$sshf"; then
      sudo sed -ri 's/^\s*PermitEmptyPasswords\b.*$/PermitEmptyPasswords no/' "$sshf"
      echo "Set PermitEmptyPasswords no in $sshf"
    else
      echo "\nPermitEmptyPasswords no" | sudo tee -a "$sshf" > /dev/null
      echo "Appended PermitEmptyPasswords no to $sshf"
    fi
  else
    echo "Warning: $sshf not found; cannot enforce PermitEmptyPasswords." >&2
  fi

  return 0
}


# -------------------------------------------------------------------
# Ensure PAM uses a secure hashing algorithm (sha512) for pam_unix.so
# -------------------------------------------------------------------
ap_ensure_password_hashing () {
  ts=$(date +%Y%m%d%H%M%S)
  files=(/etc/pam.d/common-password /etc/pam.d/system-auth /etc/pam.d/password-auth)

  for f in "${files[@]}"; do
    if [ ! -f "$f" ]; then
      # skip missing PAM files silently
      continue
    fi
    sudo cp -a "$f" "${f}.bak.${ts}"
    echo "Backup created: ${f}.bak.${ts}"

    # For lines that contain pam_unix.so, ensure the token sha512 is present
    # Preserve existing options and only add sha512 if missing
    sudo awk 'BEGIN{OFS=FS=""} /pam_unix.so/ {
        line=$0
        if (line !~ /sha512/) {
          # append sha512 to the end of the line
          sub(/[[:space:]]*$/, " sha512", line)
        }
        print line
        next
      } { print $0 }' "$f" > "${f}.tmp.$$" || sudo cp -a "$f" "${f}.tmp.$$"

    sudo mv "${f}.tmp.$$" "$f"
    echo "Ensured sha512 token on pam_unix.so lines in $f"
  done

  return 0
}
