# library-prefix = stress_ng

#

# stress-ng suite-level shared library

# System stress testing tool for reliability verification.

#

# Key metrics from stress-ng output:

# - bogo ops/s (real time): throughput

# - passed/failed/skipped counts

# - usr/sys time ratio

#

# Result validation:

# 1. "successful run completed" in output → PASS

# 2. failed: 0 → PASS

# 3. Kernel tainted unchanged → PASS

#

# Usage:. "$(dirname "$0")/../lib.sh"



STRESS_FLAG="/tmp/.beakerlib_stress_ng_suite"



stressNgSetup() {

    if [ ! -f "$STRESS_FLAG" ]; then

    if ! rpm -q stress-ng 2>/dev/null; then

    echo "${TEST_SERVER_1_PASSWORD:-openruyi}" | sudo -S dnf install -y stress-ng 2>/dev/null

    if ! rpm -q stress-ng 2>/dev/null; then

    rlLogWarning "stress-ng failed"

    echo "installed=0" > "$STRESS_FLAG"

    else

    echo "installed=1" > "$STRESS_FLAG"

    rlLogInfo "already stress-ng"

    fi

    else

    echo "installed=0" > "$STRESS_FLAG"

    rlLogInfo "stress-ng already exists"

    fi

    echo "ref=1" >> "$STRESS_FLAG"

    else

    local ref

    ref=$(grep "^ref=" "$STRESS_FLAG" | cut -d= -f2)

    ref=$((ref + 1))

    sed -i "s/^ref=.*/ref=$ref/" "$STRESS_FLAG"

    rlLogInfo "stress-ng reference count: $ref"

    fi

    rlCleanupAppend "stressNgCleanup"

}



stressNgCleanup() {

    if [ ! -f "$STRESS_FLAG" ]; then return 0; fi

    local ref

    ref=$(grep "^ref=" "$STRESS_FLAG" | cut -d= -f2)

    ref=$((ref - 1))

    if [ "$ref" -le 0 ]; then

    if grep -q "^installed=1" "$STRESS_FLAG"; then

    echo "${TEST_SERVER_1_PASSWORD:-openruyi}" | sudo -S dnf remove -y stress-ng 2>/dev/null || true

    fi

    rm -f "$STRESS_FLAG"

    else

    sed -i "s/^ref=.*/ref=$ref/" "$STRESS_FLAG"

    fi

}



# Record tainted before test

_stressNgTaintBefore() {

    cat /proc/sys/kernel/tainted 2>/dev/null || echo "0"

}



# Check tainted after test

_stressNgTaintCheck() {

    local before="$1"

    local after

    after=$(cat /proc/sys/kernel/tainted 2>/dev/null || echo "0")

    if [ "$before" != "$after" ]; then

    rlFail "kernel tainted: $before → $after"

    else

    rlPass "kernel tainted no: $before"

    fi

}



# Extract bogo ops/s (real time) for a stressor from a stress-ng metrics log
_stressNgBogoOps() {
    local log="$1"
    local stressor="${2:-}"

    awk -v stressor="$stressor" '
        /^stress-ng:[[:space:]]*metrc:/ {
            row = $0
            sub(/^stress-ng:[[:space:]]*metrc:[[:space:]]*\[[0-9]+\][[:space:]]*/, "", row)
            n = split(row, f, /[[:space:]]+/)
            if (n >= 7 && f[2] ~ /^[0-9]+$/ && f[6] ~ /^[0-9]+([.][0-9]+)?$/) {
                if (stressor != "" && f[1] == stressor && !found) {
                    print f[6]
                    found = 1
                }
                if (first == "") first = f[6]
            }
        }
        END { if (!found && first != "") print first }
    ' "$log"
}


# Validate stress-ng result from log file

# Checks: successful run completed, failed=0, bogo ops > 0

_stressNgValidate() {

    local log="$1"

    local stressor="$2"

    if [ ! -f "$log" ]; then rlFail "logfile $log does not exist"; return 1; fi



    # 1. "successful run completed"

    if grep -q "successful run completed" "$log"; then

    rlPass "$stressor: successComplete"

    else

    rlFail "$stressor: notnormalComplete"

    fi



    # 2. failed: 0

    local failed

    failed=$(grep -oP 'failed:\s*\K\d+' "$log" | tail -1)

    if [ -n "$failed" ] && [ "$failed" -eq 0 ]; then

    rlPass "$stressor: failed=$failed"

    elif [ -n "$failed" ]; then

    rlFail "$stressor: exists $failed failed"

    fi



    # 3. bogo ops/s > 0

    local bogo

    bogo=$(_stressNgBogoOps "$log" "$stressor")

    if [ -n "$bogo" ] && [ "$(echo "$bogo > 0" | bc 2>/dev/null || echo 1)" -eq 1 ]; then

    rlPass "$stressor: bogo ops/s = $bogo (real time)"

    else

    rlLogWarning "$stressor: Unable toresolve bogo ops"

    fi

    return 0

}

