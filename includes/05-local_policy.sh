#!/usr/bin/env bash
set -euo pipefail

# 05-local_policy.sh
# Applies a small set of sysctl settings used for local policies.
# This file is safe to be sourced (it will not execute); call
# invoke_local_policy to apply the settings. The invocation will
# only apply on Linux Mint by default.

apply_sysctl() {
	local sudo_cmd=""
	if [ "${EUID:-$(id -u)}" -ne 0 ]; then
		if command -v sudo >/dev/null 2>&1; then
			sudo_cmd=sudo
		else
			echo "Error: root privileges required to apply sysctl settings." >&2
			return 1
		fi
	fi

	# Use exactly the lines provided by the user.
	local -a settings=(
		"kernel.randomize_va_space=2"
		"kernel.sysrq=0"
		"net.ipv4.conf.all.accept_redirects=0"
		"net.ipv4.conf.default.accept_redirects=0"
		"net.ipv4.conf.all.log_martians=1"
		"net.ipv4.conf.default.log_martians=1"
		"net.ipv4.conf.all.rp_filter=1"
		"net.ipv4.conf.default.rp_filter=1"
		"net.ipv6.conf.all.accept_ra=0"
		"net.ipv6.conf.default.accept_ra=0"
		"net.ipv6.conf.all.accept_redirects=0"
		"net.ipv6.conf.default.accept_redirects=0"
	)

	for setting in "${settings[@]}"; do
		${sudo_cmd:+$sudo_cmd }sysctl -w "$setting"
	done

	# Persist the exact lines to the sysctl.d file
	{
		printf "%s\n" "${settings[@]}"
	} | ${sudo_cmd:+$sudo_cmd }tee /etc/sysctl.d/99-secure.conf >/dev/null

	${sudo_cmd:+$sudo_cmd }sysctl --system
}

invoke_local_policy() {
	# Prefer ID from config.sh if set; otherwise parse /etc/os-release
	local this_id=""
	if [ -n "${ID:-}" ]; then
		this_id="${ID,,}"
	else
		if [ -r /etc/os-release ]; then
			this_id="$(awk -F= '/^ID=/{print tolower($2)}' /etc/os-release | tr -d '"')"
		fi
	fi

	case "${this_id}" in
		linuxmint|mint|*mint*) : ;;
		*)
			echo "[i] Skipping local policy: not running on Linux Mint (detected: ${this_id:-unknown})."
			return 0
			;;
	esac

	echo "[+] Applying local security policy (Mint-only)..."
	apply_sysctl
	echo "[+] Done."
}

# If executed directly, run the entrypoint. If sourced, do nothing; the
# top-level orchestrator (`harden.sh`) will call invoke_local_policy when the
# user picks the menu item.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	invoke_local_policy "$@"
fi

