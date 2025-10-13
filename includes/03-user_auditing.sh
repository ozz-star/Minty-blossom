#!/usr/bin/env bash
set -euo pipefail

invoke_user_auditing () {
  # Interactive submenu for user auditing sections
  while true; do
    echo -e "${CYAN}\n[User Auditing] Menu${NC}"
    printf "1) Interactive audit of local users with valid login shells\n"
    printf "2) Interactive audit of sudoers; remove unauthorized admins\n"
    printf "3) Set passwords for all users\n"
    printf "4) Remove any UID 0 accounts that are not 'root'\n"
    printf "5) Set password aging policy for all users\n"
    printf "6) Set shells for standard users and root to /bin/bash\n"
    printf "7) Set shells for system accounts to /usr/sbin/nologin\n"
    printf "a) Run ALL of the above in sequence\n"
    printf "b) Back to main menu\n"

    read -rp $'Enter choice: ' choice
    case "$choice" in
      1)
        echo -e "${GREEN}[User Auditing] Running: Interactive audit of local users${NC}"
        ua_audit_interactive_remove_unauthorized_users
        ;;
      2)
        echo -e "${GREEN}[User Auditing] Running: Interactive audit of sudoers${NC}"
        ua_audit_interactive_remove_unauthorized_sudoers
        ;;
      3)
        echo -e "${GREEN}[User Auditing] Running: Set passwords for all users${NC}"
        ua_force_temp_passwords
        ;;
      4)
        echo -e "${GREEN}[User Auditing] Running: Remove non-root UID 0 accounts${NC}"
        ua_remove_non_root_uid0
        ;;
      5)
        echo -e "${GREEN}[User Auditing] Running: Set password aging policy${NC}"
        ua_set_password_aging_policy
        ;;
      6)
        echo -e "${GREEN}[User Auditing] Running: Set shells for standard users and root${NC}"
        ua_set_shells_standard_and_root_bash
        ;;
      7)
        echo -e "${GREEN}[User Auditing] Running: Set shells for system accounts${NC}"
        ua_set_shells_system_accounts_nologin
        ;;
      a|A)
        echo -e "${GREEN}[User Auditing] Running all sections...${NC}"
        ua_audit_interactive_remove_unauthorized_users
        ua_audit_interactive_remove_unauthorized_sudoers
        ua_force_temp_passwords
        ua_remove_non_root_uid0
        ua_set_password_aging_policy
        ua_set_shells_standard_and_root_bash
        ua_set_shells_system_accounts_nologin
        echo -e "${GREEN}[User Auditing] Completed all sections.${NC}"
        ;;
      b|B|q|Q)
        # Return to main menu
        echo -e "${CYAN}[User Auditing] Returning to main menu.${NC}"
        break
        ;;
      *)
        echo -e "${C_RED}Invalid option${C_RESET}"
        ;;
    esac
  done
}

# -------------------------------------------------------------------
# 1) Interactive audit of local users with valid login shells
# -------------------------------------------------------------------
ua_audit_interactive_remove_unauthorized_users () {
  # Build list of valid shells from /etc/shells (ignore comments and blank lines)
  mapfile -t valid_shells < <(grep -E -v '^\s*#|^\s*$' /etc/shells || true)

  if [ ${#valid_shells[@]} -eq 0 ]; then
    echo "No valid shells found in /etc/shells."
    return 0
  fi

  # Create a lookup for valid shells
  declare -A shell_map
  for s in "${valid_shells[@]}"; do
    shell_map["$s"]=1
  done

  # Collect usernames whose shell is in the valid list
  mapfile -t users < <(getent passwd | while IFS=: read -r user _ uid gid gecos home shell; do
    if [ -n "${shell_map[$shell]:-}" ]; then
      printf '%s\n' "$user"
    fi
  done)

  for user in "${users[@]}"; do
    [ -z "${user}" ] && continue
    # Prompt exactly as specified
    printf "Is %s an Authorized User? [Y/n] " "$user"
    if ! read -r reply; then
      reply="Y"
    fi

    # Treat empty input as 'Y'
    if [ -z "${reply}" ]; then
      reply="Y"
    fi

    case "${reply}" in
      n|N)
        if sudo userdel -r "$user" >/dev/null 2>&1; then
          echo "Deleted user: $user"
        else
          # Try a forced removal if available
          if sudo userdel -r --force "$user" >/dev/null 2>&1; then
            echo "Deleted user: $user"
          else
            echo "Warning: failed to delete user: $user" >&2
          fi
        fi
        ;;
      *)
        echo "Authorized: $user"
        ;;
    esac
  done

  return 0
}

# -------------------------------------------------------------------
# 2) Interactive audit of sudoers; remove unauthorized admins
# -------------------------------------------------------------------
ua_audit_interactive_remove_unauthorized_sudoers () {
  # Get sudo group members (fourth field). If none, exit.
  members=$(getent group sudo | awk -F: '{print $4}' || true)

  if [ -z "${members}" ]; then
    echo "No sudo group members found."
    return 0
  fi

  # Split on commas and iterate
  IFS=',' read -r -a users <<< "${members}"
  for user in "${users[@]}"; do
    # Trim whitespace
    user=$(printf '%s' "$user" | xargs)
    [ -z "${user}" ] && continue

    printf "Is %s an Authorized Administrator? [Y/n] " "$user"
    if ! read -r reply; then
      reply="Y"
    fi

    if [ -z "${reply}" ]; then
      reply="Y"
    fi

    case "${reply}" in
      n|N)
        if sudo deluser "$user" sudo >/dev/null 2>&1; then
          echo "Removed sudo privileges from: $user"
        else
          echo "Warning: failed to remove sudo for: $user" >&2
        fi
        ;;
      *)
        echo "Authorized administrator: $user"
        ;;
    esac
  done

  return 0
}

# -------------------------------------------------------------------
# 3) Set a consistent password for all users
# -------------------------------------------------------------------
ua_force_temp_passwords () {
  # Allow override via TEMP_PASSWORD or PASSWORD env vars; default to requested value
  password=${TEMP_PASSWORD:-${PASSWORD:-1CyberPatriot!}}

  # Gather all local usernames
  mapfile -t users < <(getent passwd | cut -d: -f1)

  if [ ${#users[@]} -eq 0 ]; then
    echo "No users found to set passwords."
    return 0
  fi

  for user in "${users[@]}"; do
    [ -z "${user}" ] && continue

    # Try to generate a SHA-512 crypt hash for the password using openssl.
    hashed=""
    if command -v openssl >/dev/null 2>&1; then
      # openssl passwd -6 generates a SHA-512 based hash
      hashed=$(openssl passwd -6 "$password" 2>/dev/null || true)
    fi

    if [ -n "${hashed}" ]; then
      # chpasswd -e accepts an encrypted password hash
      if printf '%s:%s\n' "$user" "$hashed" | sudo chpasswd -e 2>/dev/null; then
        echo "Set password for: $user"
        continue
      else
        echo "Warning: failed to set hashed password for: $user; will try plaintext fallback" >&2
      fi
    fi

    # Fallback: set the plain password via chpasswd (less preferred)
    if printf '%s:%s\n' "$user" "$password" | sudo chpasswd 2>/dev/null; then
      echo "Set plaintext password for: $user (fallback)"
    else
      echo "Warning: failed to set password for: $user" >&2
    fi
  done

  return 0
}


# -------------------------------------------------------------------
# 4) Remove any UID 0 accounts that are not 'root'
# -------------------------------------------------------------------
ua_remove_non_root_uid0 () {
  mapfile -t uid0_users < <(getent passwd | awk -F: '$3 == 0 && $1 != "root" {print $1}')

  if [ ${#uid0_users[@]} -eq 0 ]; then
    echo "No non-root UID 0 accounts found."
    return 0
  fi

  for user in "${uid0_users[@]}"; do
    [ -z "${user}" ] && continue
    if sudo userdel -r --force "$user" >/dev/null 2>&1; then
      echo "Removed non-root UID 0 user: $user"
    else
      echo "Warning: failed to remove non-root UID 0 user: $user" >&2
    fi
  done

  return 0
}

# -------------------------------------------------------------------
# 5) Set password aging policy for all users (Debian family)
# -------------------------------------------------------------------
ua_set_password_aging_policy () {
  # Iterate over all local usernames and apply chage policy
  mapfile -t users < <(getent passwd | cut -d: -f1)

  if [ ${#users[@]} -eq 0 ]; then
    echo "No users found for password aging policy."
    return 0
  fi

  successes=0
  failures=0
  for user in "${users[@]}"; do
    [ -z "${user}" ] && continue
    if sudo chage -M 60 -m 10 -W 7 "$user" >/dev/null 2>&1; then
      successes=$((successes+1))
    else
      echo "Warning: failed to set aging for: $user" >&2
      failures=$((failures+1))
    fi
  done

  echo "Password aging applied: ${successes} success, ${failures} failures."
  return 0
}

# -------------------------------------------------------------------
# 6) Set shells for standard users and root to /bin/bash
# -------------------------------------------------------------------
ua_set_shells_standard_and_root_bash () {
  # Read /etc/passwd and adjust shells for UID 0 and standard users (UID >= 1000)
  while IFS=: read -r user passwd uid gid gecos home shell; do
    # Ensure uid is numeric
    case "$uid" in
      ''|*[!0-9]*) continue ;;
    esac

    if [ "$uid" -eq 0 ] || [ "$uid" -ge 1000 ]; then
      if sudo usermod -s /bin/bash "$user" >/dev/null 2>&1; then
        echo "Changed shell for $user to /bin/bash."
      else
        echo "Warning: failed to change shell for: $user" >&2
        # continue to next user
      fi
    fi
  done < /etc/passwd

  return 0
}

# -------------------------------------------------------------------
# 7) Set shells for system accounts to /usr/sbin/nologin
# -------------------------------------------------------------------
ua_set_shells_system_accounts_nologin () {
  # Read /etc/passwd and change shells for system accounts (UID 1..999)
  while IFS=: read -r user passwd uid gid gecos home shell; do
    # Ensure uid is numeric
    case "$uid" in
      ''|*[!0-9]*) continue ;;
    esac

    if [ "$uid" -ge 1 ] && [ "$uid" -le 999 ]; then
      if sudo usermod -s /usr/sbin/nologin "$user" >/dev/null 2>&1; then
        echo "Changed shell for $user to /usr/sbin/nologin."
      else
        echo "Warning: failed to change shell for: $user" >&2
      fi
    fi
  done < /etc/passwd

  return 0
}
