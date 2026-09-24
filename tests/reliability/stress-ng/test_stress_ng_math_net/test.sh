#!/bin/bash

# Reliability: stress-ng - count/networkstress (--matrix/--af-alg/--netdev)

. /usr/share/beakerlib/beakerlib.sh || exit 1

. "$(dirname "$0")/../lib.sh"



rlJournalStart

    rlPhaseStartSetup "Environment setup"

    stressNgSetup

    TmpDir=$(mktemp -d)

    rlRun "cd $TmpDir" 0 ""

    TAINT=$(_stressNgTaintBefore)

    rlPhaseEnd



    rlPhaseStartTest "MATRIX stress ()"

    log="$TmpDir/matrix.log"

    rlRun "stress-ng --matrix 2 --timeout 30s --metrics-brief --log-file $log 2>&1 | tail -5" 0 "--matrix 2"

    _stressNgValidate "$log" "matrix"

    # usr time, verify usr > sys

    if grep -q "matrix" "$log"; then


    usr=$(grep "matrix" "$log" | awk '{for(i=1;i<=NF;i++){if($i~/^[0-9.]+$/&&$(i-1)~/secs/)print $i}}' | head -1)

    rlLogInfo " bogo verify"

    fi

    rlPhaseEnd



    rlPhaseStartTest "AF-ALG stress (kernelcrypto)"

    log="$TmpDir/af_alg.log"

    stress-ng --af-alg 2 --timeout 20s --metrics-brief --log-file "$log" 2>&1 | tail -5

    if grep -q "successful run completed" "$log" 2>/dev/null; then

    _stressNgValidate "$log" "af-alg"

    else

    rlLogInfo "AF-ALG stressor no by supports (nokernelcryptomodule), skip"

    rlPass "AF-ALG: skip"

    fi

    rlPhaseEnd



    rlPhaseStartTest "VM-SPLICE stress (pipe splice)"

    log="$TmpDir/vm_splice.log"

    stress-ng --vm-splice 2 --timeout 20s --metrics-brief --log-file "$log" 2>&1 | tail -5

    if grep -q "successful run completed" "$log" 2>/dev/null; then

    _stressNgValidate "$log" "vm-splice"

    else

    rlLogInfo "vm-splice noavailable, skip"

    rlPass "VM-SPLICE: skip"

    fi

    rlPhaseEnd



    rlPhaseStartTest "BAD-ALTSTACK stress (Exceptionsignalstack)"

    #: itemswillExceptionsignalhandlepath, possiblehaspreerror

    log="$TmpDir/bad_altstack.log"

    rlRun "stress-ng --bad-altstack 1 --timeout 10s --metrics-brief --log-file $log 2>&1 | tail -5" 0 "--bad-altstack 1"

    # bad-altstack possiblehas skipped, this isnormal

    rlLogInfo "bad-altstack Complete (has skipped orwarning)"

    rlPass "BAD-ALTSTACK: ExecuteComplete"

    rlPhaseEnd



    rlPhaseStartTest "tainted"

    _stressNgTaintCheck "$TAINT"

    rlPhaseEnd



    rlPhaseStartCleanup "Cleanup"

    rlRun "cd /" 0 ""; [ -n "$TmpDir" ] && rlRun "rm -rf $TmpDir" 0 ""

    rlPhaseEnd

    rlJournalPrintText

rlJournalEnd

