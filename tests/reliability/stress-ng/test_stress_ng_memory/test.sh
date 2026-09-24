#!/bin/bash

# Reliability: stress-ng - memorystress (--vm/--mmap/--madvise)

. /usr/share/beakerlib/beakerlib.sh || exit 1

. "$(dirname "$0")/../lib.sh"



rlJournalStart

    rlPhaseStartSetup "Environment setup"

    stressNgSetup

    TmpDir=$(mktemp -d)

    rlRun "cd $TmpDir" 0 ""

    TAINT=$(_stressNgTaintBefore)

    rlPhaseEnd



    rlPhaseStartTest "VM stress (memory)"

    log="$TmpDir/vm.log"

    rlRun "stress-ng --vm 2 --vm-bytes 128M --timeout 30s --metrics-brief --log-file $log 2>&1 | tail -5" 0 "--vm 2x128M"

    _stressNgValidate "$log" "vm"

    rlPhaseEnd



    rlPhaseStartTest "MMAP stress"

    log="$TmpDir/mmap.log"

    rlRun "stress-ng --mmap 2 --timeout 30s --metrics-brief --log-file $log 2>&1 | tail -5" 0 "--mmap 2"

    _stressNgValidate "$log" "mmap"

    rlPhaseEnd



    rlPhaseStartTest "MADVISE stress"

    log="$TmpDir/madvise.log"

    rlRun "stress-ng --madvise 2 --timeout 30s --metrics-brief --log-file $log 2>&1 | tail -5" 0 "--madvise 2"

    _stressNgValidate "$log" "madvise"

    rlPhaseEnd



    rlPhaseStartTest "Memory combined stress"

    log="$TmpDir/mem_combo.log"

    # simultaneously VM + MMAP

    rlRun "stress-ng --vm 1 --vm-bytes 64M --mmap 1 --timeout 30s --metrics-brief --log-file $log 2>&1 | tail -10" 0 "memorycombined stress"

    _stressNgValidate "$log" "vm"

    _stressNgValidate "$log" "mmap"

    rlPhaseEnd



    rlPhaseStartTest "tainted"

    _stressNgTaintCheck "$TAINT"

    rlPhaseEnd



    rlPhaseStartCleanup "Cleanup"

    rlRun "cd /" 0 ""; [ -n "$TmpDir" ] && rlRun "rm -rf $TmpDir" 0 ""

    rlPhaseEnd

    rlJournalPrintText

rlJournalEnd

