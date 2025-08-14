#!/usr/bin/env bash

# File contains functions for storing metrics from the buildpack in bash.
#
# The format of the report file is line separated key-value pairs.
#
# Example:
#   ruby_version: "3.3.3"
#   ruby_install_duration: 1.234
#
# All keys get `ruby.` prepended to them in the backend automatically.

set -euo pipefail

# Variables shared by this whole module
BASH_REPORT_FILE=""

# Must be called before you can use any other methods
metrics::init() {
	local cache_dir="${1}"
	BASH_REPORT_FILE="${cache_dir}/.heroku/ruby/bash_build_report.yml"
}

# This should be called after metrics::init in bin/compile
metrics::clear() {
	mkdir -p "$(dirname "${BASH_REPORT_FILE}")"
	echo "" > "${BASH_REPORT_FILE}"
}

# Adds a key-value pair to the report file without any attempt to quote or escape the value.
metrics::kv_raw() {
	local key="${1}"
	local value="${2}"
	if [[ -n "${value}" ]]; then
		echo "${key}: ${value}" >> "${BASH_REPORT_FILE}"
	fi
}

# Adds a key-value pair to the report file, quoting the value.
metrics::kv_string() {
	local key="${1}"
	local value="${2}"
	if [[ -n "${value}" ]]; then
		metrics::kv_raw "$key" "'${value//\'/\'\'}'"
	fi
}

# Returns the current time, in milliseconds.
# E.g. metrics::nowms => 1755207400269 # 2025-08-14 21:36 UTC
metrics::nowms() {
	# Try Linux format first (date +%s%3N)
	local timestamp=$(date +%s%3N 2>/dev/null)

	# Check if it worked (should be numeric and longer than 10 digits)
	if [[ "$timestamp" =~ ^[0-9]{13,}$ ]]; then
		echo "$timestamp"
		return 0
	fi

	# Fallback for BSD systems: use date +%s and add milliseconds
	local seconds=$(date +%s)
	local nanoseconds=$(date +%N 2>/dev/null || echo "000000000")
	# Convert nanoseconds to milliseconds (first 3 digits)
	local milliseconds=${nanoseconds:0:3}
	echo "${seconds}${milliseconds}"
}

metrics::start_timer() {
	metrics::nowms
}

# Adds a key=duration to the report file
#
# Example:
#   start_time=$(metrics::start_timer)
#   sleep 1
#   metrics::kv_duration_since "ruby_install" "${start_time}"
#
#   metrics::print
#   # => ruby_install: 1.234
metrics::kv_duration_since() {
	local key="${1}"
	local start="${2}"
	local end="${3:-$(metrics::start_timer)}"
	local time
	time="$(echo "${start}" "${end}" | awk '{ printf "%.3f", ($2 - $1)/1000 }')"
	metrics::kv_raw "$key" "${time}"
}

# Does what it says on the tin.
metrics::print() {
	cat "${BASH_REPORT_FILE}"
}
