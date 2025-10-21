#!/usr/bin/env bash
set -euo pipefail

invoke_user_auditing () {
  # Interactive submenu for user auditing sections
  # Track completed submenu items locally
  declare -A UA_COMPLETED=()

  while true; do
    echo -e "${CYAN}\n[User Auditing] Menu${NC}"
  # Show items green if completed
    if [ "${UA_COMPLETED[1]:-0}" = "1" ]; then printf "%b1) Interactive audit of local users with valid login shells%b\n" "$GREEN" "$NC"; else printf "1) Interactive audit of local users with valid login shells\n"; fi
    if [ "${UA_COMPLETED[2]:-0}" = "1" ]; then printf "%b2) Interactive audit of sudoers; remove unauthorized admins%b\n" "$GREEN" "$NC"; else printf "2) Interactive audit of sudoers; remove unauthorized admins\n"; fi
    if [ "${UA_COMPLETED[3]:-0}" = "1" ]; then printf "%b3) Set passwords for all users%b\n" "$GREEN" "$NC"; else printf "3) Set passwords for all users\n"; fi
    if [ "${UA_COMPLETED[4]:-0}" = "1" ]; then printf "%b4) Remove any UID 0 accounts that are not 'root'%b\n" "$GREEN" "$NC"; else printf "4) Remove any UID 0 accounts that are not 'root'\n"; fi
    if [ "${UA_COMPLETED[5]:-0}" = "1" ]; then printf "%b5) Set password aging policy for all users%b\n" "$GREEN" "$NC"; else printf "5) Set password aging policy for all users\n"; fi
    if [ "${UA_COMPLETED[6]:-0}" = "1" ]; then printf "%b6) Set shells for standard users and root to /bin/bash%b\n" "$GREEN" "$NC"; else printf "6) Set shells for standard users and root to /bin/bash\n"; fi
    if [ "${UA_COMPLETED[7]:-0}" = "1" ]; then printf "%b7) Set shells for system accounts to /usr/sbin/nologin%b\n" "$GREEN" "$NC"; else printf "7) Set shells for system accounts to /usr/sbin/nologin\n"; fi
  if [ "${UA_COMPLETED[8]:-0}" = "1" ]; then printf "%b8) Create a new user%b\n" "$GREEN" "$NC"; else printf "8) Create a new user\n"; fi
  if [ "${UA_COMPLETED[9]:-0}" = "1" ]; then printf "%b9) Add a user to groups%b\n" "$GREEN" "$NC"; else printf "9) Add a user to groups\n"; fi
    printf "a) Run ALL of the above in sequence\n"
    printf "b) Back to main menu\n"

    read -rp $'Enter choice: ' choice
  case "$choice" in
      1)
        echo -e "${GREEN}[User Auditing] Running: Interactive audit of local users${NC}"
        ua_audit_interactive_remove_unauthorized_users
        UA_COMPLETED[1]=1
        ;;
      2)
        echo -e "${GREEN}[User Auditing] Running: Interactive audit of sudoers${NC}"
        ua_audit_interactive_remove_unauthorized_sudoers
        UA_COMPLETED[2]=1
        ;;
      
      3)
        echo -e "${GREEN}[User Auditing] Running: Set passwords for all users${NC}"
        ua_set_passwords_for_all
        UA_COMPLETED[3]=1
        ;;
      4)
        echo -e "${GREEN}[User Auditing] Running: Remove any UID 0 accounts that are not 'root'${NC}"
        ua_remove_non_root_uid0
        UA_COMPLETED[4]=1
        ;;
      5)
        echo -e "${GREEN}[User Auditing] Running: Set password aging policy for all users${NC}"
        ua_set_password_aging_policy
        UA_COMPLETED[5]=1
        ;;
      6)
        echo -e "${GREEN}[User Auditing] Running: Set shells for standard users and root to /bin/bash${NC}"
        ua_set_shells_standard_and_root_bash
        UA_COMPLETED[6]=1
        ;;
      7)
        echo -e "${GREEN}[User Auditing] Running: Set shells for system accounts to /usr/sbin/nologin${NC}"
        ua_set_shells_system_accounts_nologin
        UA_COMPLETED[7]=1
        ;;
      8)
        echo -e "${GREEN}[User Auditing] Running: Create a new user${NC}"
        ua_create_user
        UA_COMPLETED[8]=1
        ;;
      9)
        echo -e "${GREEN}[User Auditing] Running: Add a user to groups${NC}"
        ua_add_user_to_groups
        UA_COMPLETED[9]=1
        ;;
      a|A)
        echo -e "${GREEN}[User Auditing] Running all sections...${NC}"
        ua_audit_interactive_remove_unauthorized_users; UA_COMPLETED[1]=1
        ua_audit_interactive_remove_unauthorized_sudoers; UA_COMPLETED[2]=1
    ua_set_passwords_for_all; UA_COMPLETED[3]=1
  ua_audit_interactive_remove_unauthorized_users; UA_COMPLETED[1]=1
  ua_audit_interactive_remove_unauthorized_sudoers; UA_COMPLETED[2]=1
        ua_remove_non_root_uid0; UA_COMPLETED[4]=1
        ua_set_password_aging_policy; UA_COMPLETED[5]=1
        ua_set_shells_standard_and_root_bash; UA_COMPLETED[6]=1
        ua_set_shells_system_accounts_nologin; UA_COMPLETED[7]=1


# -------------------------------------------------------------------
# 3) Set a consistent password for all users
# 3) Set a full password for all users
# -------------------------------------------------------------------
ua_set_passwords_for_all () {
  # Allow override via PASSWORD env var; default to requested value
  password="${PASSWORD:-1CyberPatriot!}"

  # Gather all local usernames
  mapfile -t users < <(getent passwd | cut -d: -f1)
  for user in "${users[@]}"; do
    # Skip system users (UID < 1000)
    if [ "$(id -u "$user")" -lt 1000 ]; then
      echo "Skipping system user: $user"
      continue
    fi

    # Attempt to set the password using the preferred method (hashed)
    if printf '%s:%s\n' "$user" "$password" | sudo chpasswd -e 2>/dev/null; then
      echo "Set password for: $user"
      continue
    else
      echo "Warning: failed to set hashed password for: $user; will try plaintext fallback" >&2
      echo "Warning: failed to set hashed password for: $user; will try plaintext method" >&2
      fi
    fi

    # Fallback: set the plain password via chpasswd (less preferred)
    # Fallback: set the plain password via chpasswd
    if printf '%s:%s\n' "$user" "$password" | sudo chpasswd 2>/dev/null; then
      echo "Set plaintext password for: $user (fallback)"
      echo "Set password for: $user"
    else
      echo "Warning: failed to set password for: $user" >&2
    fi
@@ -259,8 +259,8 @@ ua_create_user () {
    read -rp $'Set password now? [Y/n] ' setpw
    if [ -z "${setpw}" ] || [[ "${setpw}" =~ ^[Yy] ]]; then
      if command -v openssl >/dev/null 2>&1; then
        # default to configured password variable if present, else prompt
        default_pw="${TEMP_PASSWORD:-${PASSWORD:-}}"
  # default to configured password variable if present, else prompt
  default_pw="${PASSWORD:-}"
        if [ -z "${default_pw}" ]; then
          read -srp $'Enter password for new user: ' p1; echo; read -srp $'Confirm password: ' p2; echo
          if [ "$p1" != "$p2" ]; then echo "Passwords do not match."; return 1; fi
          pw="$p1"
        else
          pw="$default_pw"
        fi
        hashed=$(openssl passwd -6 "$pw" 2>/dev/null || true)
        if [ -n "$hashed" ]; then
          printf '%s:%s\n' "$newuser" "$hashed" | sudo chpasswd -e >/dev/null 2>&1 && echo -e "${GREEN}Password set for $newuser${NC}" || echo "Warning: failed to set hashed password" >&2
        else
          printf '%s:%s\n' "$newuser" "$pw" | sudo chpasswd >/dev/null 2>&1 && echo -e "${GREEN}Password set for $newuser (plaintext fallback)${NC}" || echo "Warning: failed to set password" >&2
        fi
      else
        echo "Warning: openssl not available; skipping password set." >&2
      fi
    fi
    return 0
  else
    echo "Warning: failed to create user: $newuser" >&2
    return 1
  fi
}


# -------------------------------------------------------------------
# 3.2) Add an existing user to groups interactively
# -------------------------------------------------------------------
ua_add_user_to_groups () {
  read -rp $'Enter username to modify: ' tgt_user
  [ -z "${tgt_user}" ] && { echo "No username entered."; return 1; }
  if ! getent passwd "$tgt_user" >/dev/null 2>&1; then
    echo "User '$tgt_user' does not exist."; return 1
  fi

  # Show all groups
  echo -e "${CYAN}Available groups:${NC}"
  getent group | cut -d: -f1 | column

  # Prompt for comma-separated groups to add
  read -rp $'Enter comma-separated group names to add the user to: ' groups
  [ -z "${groups}" ] && { echo "No groups entered."; return 1; }

  # Iterate groups, trim whitespace, and attempt to add
  IFS=',' read -r -a garr <<< "$groups"
  for g in "${garr[@]}"; do
    g=$(printf '%s' "$g" | xargs)
    [ -z "$g" ] && continue
    if getent group "$g" >/dev/null 2>&1; then
      if sudo usermod -a -G "$g" "$tgt_user" >/dev/null 2>&1; then
        echo -e "${GREEN}Added $tgt_user to group $g${NC}"
      else
        echo "Warning: failed to add $tgt_user to $g" >&2
      fi
    else
      echo "Warning: group '$g' does not exist." >&2
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
