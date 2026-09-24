#!/bin/bash

# Reliability: stress-ng - IO stress (--hdd/--aio/--getdent)

. /usr/share/beakerlib/beakerlib.sh || exit 1

. "$(dirname "$0")/../lib.sh"



rlJournalStart

    rlPhaseStartSetup "Environment setup"

    stressNgSetup

    TmpDir=$(mktemp -d)

    rlRun "cd $TmpDir" 0 ""

    TAINT=$(_stressNgTaintBefore)

    mkdir -p "$TmpDir/io_test"

    rlPhaseEnd



    rlPhaseStartTest "HDD stress (IO)"

    log="$TmpDir/hdd.log"

    rlRun "stress-ng --hdd 2 --hdd-bytes 32M --temp-path $TmpDir/io_test --timeout 30s --metrics-brief --log-file $log 2>&1 | tail -5" 0 "--hdd 2"

    _stressNgValidate "$log" "hdd"

    rlPhaseEnd



    rlPhaseStartTest "AIO stress (IO)"

    # aio needs libaio supports, possiblesystemnot supported

    log="$TmpDir/aio.log"

    stress-ng --aio 2 --timeout 20s --metrics-brief --log-file "$log" 2>&1 | tail -5

    if grep -q "successful run completed" "$log" 2>/dev/null; then

    _stressNgValidate "$log" "aio"

    else

    rlLogInfo "AIO stressor no by supports, skip (normal)"

    rlPass "AIO: skip (not supported)"

    fi

    rlPhaseEnd



    rlPhaseStartTest "GETDENT stress (directory)"

    log="$TmpDir/getdent.log"

    rlRun "stress-ng --getdent 2 --timeout 20s --metrics-brief --log-file $log 2>&1 | tail -5" 0 "--getdent 2"

    _stressNgValidate "$log" "getdent"

    rlPhaseEnd



    rlPhaseStartTest "tainted"

    _stressNgTaintCheck "$TAINT"

    rlPhaseEnd



    rlPhaseStartCleanup "Cleanup"

    rlRun "cd /" 0 ""; [ -n "$TmpDir" ] && rlRun "rm -rf $TmpDir" 0 ""

    rlPhaseEnd

    rlJournalPrintText

rlJournalEnd

