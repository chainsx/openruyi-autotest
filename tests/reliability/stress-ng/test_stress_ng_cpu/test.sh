#!/bin/bash

# Reliability: stress-ng - CPU stress (rampthread 1→2→4)

. /usr/share/beakerlib/beakerlib.sh || exit 1

. "$(dirname "$0")/../lib.sh"



rlJournalStart

    rlPhaseStartSetup "Environment setup"

    stressNgSetup

    TmpDir=$(mktemp -d)

    rlRun "cd $TmpDir" 0 ""

    TAINT=$(_stressNgTaintBefore)

    rlLogInfo "CPU corecount: $(nproc)"

    rlPhaseEnd



    rlPhaseStartTest "CPU stress rampthread"

    bogo_vals=()

    for t in 1 2 4; do

    log="$TmpDir/cpu_${t}.log"

    rlRun "stress-ng --cpu $t --timeout 30s --metrics-brief --log-file $log 2>&1 | tail -5" 0 "CPU $t thread"

    tail -15 "$log"

    _stressNgValidate "$log" "cpu"

    # extract bogo ops/s


    bogo=$(_stressNgBogoOps "$log" "cpu")

    bogo_vals+=("$bogo")

    rlLogInfo "CPU ${t}thread bogo ops/s: $bogo"

    done

    # verifymultithreadshouldhasmore (nodesc)

    if [ "${#bogo_vals[@]}" -ge 2 ]; then

    rlLogInfo "CPU bogo: 1t=${bogo_vals[0]} 2t=${bogo_vals[1]} 4t=${bogo_vals[2]}"

    rlPass "CPU ramptestComplete"

    fi

    rlPhaseEnd



    rlPhaseStartTest "tainted"

    _stressNgTaintCheck "$TAINT"

    rlPhaseEnd



    rlPhaseStartCleanup "Cleanup"

    rlRun "cd /" 0 ""; [ -n "$TmpDir" ] && rlRun "rm -rf $TmpDir" 0 ""

    rlPhaseEnd

    rlJournalPrintText

rlJournalEnd
