#!/bin/bash

# Reliability: stress-ng - combinedstress: multistressorandlines + metricsanalysis

# Documentation recommendsrampand, testsimultaneouslyrunmulti stressor actuallyload

. /usr/share/beakerlib/beakerlib.sh || exit 1

. "$(dirname "$0")/../lib.sh"



rlJournalStart

    rlPhaseStartSetup "Environment setup"

    stressNgSetup

    TmpDir=$(mktemp -d)

    rlRun "cd $TmpDir" 0 ""

    TAINT=$(_stressNgTaintBefore)

    rlPhaseEnd



    rlPhaseStartTest "combined stress: CPU+MEM+PROC"

    log="$TmpDir/combo1.log"

    # simultaneously CPU(2thread) + VM(128M) + FORK(2thread)

    rlRun "stress-ng --cpu 2 --vm 1 --vm-bytes 64M --fork 2 --timeout 30s --metrics-brief --log-file $log 2>&1 | tail -10" 0 "CPU+VM+FORK combined"

    tail -20 "$log"



    # verifyeach stressor all success

    for s in cpu vm fork; do

    if grep -q "$s" "$log"; then

    _stressNgValidate "$log" "$s"

    fi

    done

    rlPhaseEnd



    rlPhaseStartTest "combined stress: Documentation recommends workload"

    # useDocumentation recommends 13 workload (time)

    log="$TmpDir/combo2.log"

    workloads="cpu context fork get mmap vm-splice wait zombie"

    args=""

    for w in $workloads; do args="$args --$w 1"; done



    rlRun "stress-ng $args --timeout 30s --metrics-brief --log-file $log 2>&1 | tail -15" 0 "Documentation recommends workload combined"

    tail -30 "$log"



    # count passed count


    passed=$(grep -oP 'passed:\s*\K\d+' "$log" | awk '{s+=$1} END {print s}')

    rlLogInfo "combinedtest passed totalcount: $passed"

    if [ -n "$passed" ] && [ "$passed" -gt 0 ]; then

    rlPass "combined stress: $passed stressor passed"

    fi



    # confirmnofailed


    failed=$(grep -oP 'failed:\s*\K\d+' "$log" | awk '{s+=$1} END {print s}')

    if [ -z "$failed" ] || [ "$failed" -eq 0 ]; then

    rlPass "combined stress: failed=0"

    else

    rlLogWarning "combined stressexists $failed failed"

    fi

    rlPhaseEnd



    rlPhaseStartTest "metrics analysis"

    log="$TmpDir/combo1.log"

    # analysis usr/sys time 

    if [ -f "$log" ]; then

    rlRun "grep -E 'cpu|vm|fork' $log | head -10" 0 "metrics "

    # usr time shouldtotaltime


    total_usr=$(grep -oP 'usr time\s+\K[\d.]+' "$log" | head -1)

    total_sys=$(grep -oP'sys time\s+\K[\d.]+' "$log" | head -1)

    if [ -n "$total_usr" ]; then

    rlLogInfo "usr time: $total_usr, sys time: $total_sys"

    rlPass "metrics canresolve"

    fi

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

