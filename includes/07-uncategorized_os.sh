#!/usr/bin/env bash
set -euo pipefail

invoke_uncategorized_os () {
  echo -e "${CYAN}[Uncategorized OS] Start${NC}"

  uos_home_dir_permissions
  uos_login_defs_permissions
  uos_shadow_gshadow_permissions
  uos_passwd_group_permissions
  uos_grub_permissions
  uos_system_map_permissions
  uos_ssh_host_keys_permissions
  uos_audit_rules_permissions
  uos_remove_world_writable_files
  uos_report_unowned_files
  uos_var_log_permissions
  uos_tmp_permissions

  # (Any additional one-offs can be added above)
  echo -e "${CYAN}[Uncategorized OS] Done${NC}"
}

# -------------------------------------------------------------------
# Home directories: 0700 perms
# -------------------------------------------------------------------
uos_home_dir_permissions () {
  # Find first-level directories under /home and chmod them to 0700
  if [ ! -d /home ]; then
    echo "/home does not exist; skipping" >&2
    return 0
  fi

  # Use find to list directories at depth 1
  while IFS= read -r -d '' dir; do
    if sudo chmod 700 "$dir" >/dev/null 2>&1; then
      echo "Set 0700 on $dir"
    else
      echo "Warning: failed to set 0700 on $dir" >&2
      # continue on errors
    fi
  done < <(find /home -maxdepth 1 -mindepth 1 -type d -print0)
}

# -------------------------------------------------------------------
# /etc/login.defs: 0600 root:root
# -------------------------------------------------------------------
uos_login_defs_permissions () {
  target=/etc/login.defs
  if [ ! -e "$target" ]; then
    echo "$target not found; skipping" >&2
    return 0
  fi

  if sudo chown root:root "$target" >/dev/null 2>&1; then
    echo "Set owner root:root on $target"
  else
    echo "Warning: failed to chown $target" >&2
  fi

  if sudo chmod 0600 "$target" >/dev/null 2>&1; then
    echo "Set permissions 0600 on $target"
  else
    echo "Warning: failed to chmod $target" >&2
  fi
}

# -------------------------------------------------------------------
# shadow/gshadow and backups: 0640 root:shadow
# -------------------------------------------------------------------
uos_shadow_gshadow_permissions () {
  files=(/etc/shadow /etc/shadow- /etc/gshadow /etc/gshadow-)
  for f in "${files[@]}"; do
    if [ ! -e "$f" ]; then
      echo "Skipping missing $f"
      continue
    fi
    if sudo chown root:shadow "$f" >/dev/null 2>&1; then
      echo "Set owner root:shadow on $f"
    else
      echo "Warning: failed to chown $f" >&2
    fi
    if sudo chmod 0640 "$f" >/dev/null 2>&1; then
      echo "Set permissions 0640 on $f"
    else
      echo "Warning: failed to chmod $f" >&2
    fi
  done
}

# -------------------------------------------------------------------
# passwd/group and backups: 0644 root:root
# -------------------------------------------------------------------
uos_passwd_group_permissions () {
  files=(/etc/passwd /etc/passwd- /etc/group /etc/group-)
  for f in "${files[@]}"; do
    if [ ! -e "$f" ]; then
      echo "Skipping missing $f"
      continue
    fi
    if sudo chown root:root "$f" >/dev/null 2>&1; then
      echo "Set owner root:root on $f"
    else
      echo "Warning: failed to chown $f" >&2
    fi
    if sudo chmod 0644 "$f" >/dev/null 2>&1; then
      echo "Set permissions 0644 on $f"
    else
      echo "Warning: failed to chmod $f" >&2
    fi
  done
}

# -------------------------------------------------------------------
# GRUB config: 0600 root:root
# -------------------------------------------------------------------
uos_grub_permissions () {
  target=/boot/grub/grub.cfg
  if [ ! -e "$target" ]; then
    echo "$target not found; skipping" >&2
    return 0
  fi

  if sudo chown root:root "$target" >/dev/null 2>&1; then
    echo "Set owner root:root on $target"
  else
    echo "Warning: failed to chown $target" >&2
  fi

  if sudo chmod 0600 "$target" >/dev/null 2>&1; then
    echo "Set permissions 0600 on $target"
  else
    echo "Warning: failed to chmod $target" >&2
  fi
}

# -------------------------------------------------------------------
# System.map (if present): 0600 root:root
# -------------------------------------------------------------------
uos_system_map_permissions () {
  # For each /boot/System.map-* that is a regular file: chown root:root and chmod 0600
  shopt -s nullglob
  for f in /boot/System.map-*; do
    if [ -f "$f" ]; then
      if sudo chown root:root "$f" >/dev/null 2>&1; then
        echo "Set owner root:root on $f"
      else
        echo "Warning: failed to chown $f" >&2
        # continue on error
      fi

      if sudo chmod 0600 "$f" >/dev/null 2>&1; then
        echo "Set permissions 0600 on $f"
      else
        echo "Warning: failed to chmod $f" >&2
        # continue on error
      fi
    fi
  done
  shopt -u nullglob
}

# -------------------------------------------------------------------
# SSH host keys: 0600 (at least RSA & ECDSA)
# -------------------------------------------------------------------
uos_ssh_host_keys_permissions () {
  # Ensure SSH host private keys have strict permissions (0600).
  files=(
    /etc/ssh/ssh_host_rsa_key
    /etc/ssh/ssh_host_ecdsa_key
    /etc/ssh/ssh_host_ed25519_key
    /etc/ssh/ssh_host_dsa_key
  )

  for f in "${files[@]}"; do
    if [ ! -e "$f" ]; then
      # Skip missing files silently (but note via message to stdout)
      echo "Skipping missing $f"
      continue
    fi

    if sudo chmod 0600 "$f" >/dev/null 2>&1; then
      echo "Set permissions 0600 on $f"
    else
      echo "Warning: failed to chmod 0600 on $f" >&2
      # continue on errors
    fi
  done
}

# -------------------------------------------------------------------
# Audit rules: remove dangerous bits on /etc/audit/rules.d/*.rules
# -------------------------------------------------------------------
uos_audit_rules_permissions () {
  # Find regular .rules files in /etc/audit/rules.d at maxdepth 1 and normalize perms.
  dir=/etc/audit/rules.d
  if [ ! -d "$dir" ]; then
    echo "$dir does not exist; skipping"
    return 0
  fi

  # Use find to restrict to regular files at depth 1
  while IFS= read -r -d '' file; do
    # Attempt to remove setuid, setgid, sticky, group write/execute, and all 'other' perms
    if sudo chmod u-s,g-s,g-wx,o-rwx "$file" >/dev/null 2>&1; then
      echo "Normalized permissions on $file"
    else
      echo "Warning: failed to normalize permissions on $file" >&2
      # continue on errors
    fi
  done < <(find "$dir" -maxdepth 1 -type f -name '*.rules' -print0)
}

# -------------------------------------------------------------------
# Remove world-writable files (clear o+w) on local filesystems
# -------------------------------------------------------------------
uos_remove_world_writable_files () {
  # Enumerate local mounts and remove world-writable bit from regular files.
  # df --local -P prints lines like: /dev/sda1  ... /
  df --local -P | awk 'NR>1 {print $6}' | while IFS= read -r mount; do
    # ensure mount exists and is a directory
    [ -d "$mount" ] || continue

    # find regular files that are world-writable on this mount, do not traverse into other filesystems
    while IFS= read -r -d '' file; do
      if sudo chmod o-w "$file" >/dev/null 2>&1; then
        echo "Removed world-write on $file"
      else
        echo "Warning: failed to remove world-write on $file" >&2
        # continue on errors
      fi
    done < <(find "$mount" -xdev -type f -perm -0002 -print0 2>/dev/null)
  done
}

# -------------------------------------------------------------------
# Report files without user/group ownership (no destructive fix)
# -------------------------------------------------------------------
uos_report_unowned_files () {
  # Ensure $DOCS is set; default to /var/log if not
  : "${DOCS:=/var/log}" >/dev/null
  mkdir -p "$DOCS" >/dev/null 2>&1 || {
    echo "Warning: failed to create $DOCS" >&2
    return 1
  }

  out="$DOCS/unowned_files.txt"
  : >"$out"

  # For each local mount, collect -nouser and -nogroup files (do not cross fs)
  df --local -P | awk 'NR>1 {print $6}' | while IFS= read -r mount; do
    [ -d "$mount" ] || continue
    # find files without a user or group on this mount
    find "$mount" -xdev \( -nouser -o -nogroup \) -print >>"$out" 2>/dev/null || true
  done

  # Count findings
  if [ -f "$out" ]; then
    count=$(wc -l <"$out" 2>/dev/null || echo 0)
  else
    count=0
  fi

  echo "Found $count unowned/un-grouped paths; report written to $out"
}

# -------------------------------------------------------------------
# Normalize /var/log permissions to 0640 for files
# -------------------------------------------------------------------
uos_var_log_permissions () {
  dir=/var/log
  if [ ! -d "$dir" ]; then
    echo "$dir does not exist; skipping"
    return 0
  fi

  count=0
  failed=0
  # Find regular files under /var/log
  while IFS= read -r -d '' f; do
    if sudo chmod 0640 "$f" >/dev/null 2>&1; then
      echo "Set permissions 0640 on $f"
      count=$((count+1))
    else
      echo "Warning: failed to chmod 0640 on $f" >&2
      failed=$((failed+1))
      # continue on errors
    fi
  done < <(find "$dir" -type f -print0 2>/dev/null)

  echo "Normalized permissions on $count files under $dir; $failed failures"
}

# -------------------------------------------------------------------
# /tmp and /var/tmp: 1777 root:root
# -------------------------------------------------------------------
uos_tmp_permissions () {
  dirs=(/tmp /var/tmp)
  for d in "${dirs[@]}"; do
    if [ ! -d "$d" ]; then
      echo "$d does not exist; skipping"
      continue
    fi

    if sudo chown root:root "$d" >/dev/null 2>&1; then
      echo "Set owner root:root on $d"
    else
      echo "Warning: failed to chown $d" >&2
    fi

    if sudo chmod 1777 "$d" >/dev/null 2>&1; then
      echo "Set permissions 1777 on $d"
    else
      echo "Warning: failed to chmod $d" >&2
    fi
  done
}
