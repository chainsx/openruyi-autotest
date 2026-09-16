#!/bin/bash
# Functional test: ltp - kernel_misc - zram01
# Beakerlib-based test with lifecycle management
# Shared suite setup/cleanup via ../../lib.sh (install once, uninstall once)

. /usr/share/beakerlib/beakerlib.sh || exit 1
. "$(dirname "$0")/../../lib.sh"

rlJournalStart
    rlPhaseStartSetup "Environment setup"
    ltpSetup
    TmpDir=$(mktemp -d)
    rlRun "cd $TmpDir" 0 "Enter temporary test directory"
    # LTP zram01 maps ntfs3 to mkfs.ntfs but formats with mkfs.ntfs3
    if ! command -v mkfs.ntfs3 >/dev/null 2>&1 && command -v mkfs.ntfs >/dev/null 2>&1; then
        ShimDir=$(mktemp -d)
        ln -s "$(command -v mkfs.ntfs)" "$ShimDir/mkfs.ntfs3"
        PATH="$ShimDir:$PATH"
        export PATH
    fi
    rlPhaseEnd

    rlPhaseStartTest "LTP kernel_misc - zram01"
    rlRun "_ltpRunCase kernel_misc zram01" 0 "Execute LTP zram01"
    rlPhaseEnd

    rlPhaseStartCleanup "Clean up test environment"
    rlRun "cd /" 0 "Leave test directory"
    [ -n "$TmpDir" ] && [ -d "$TmpDir" ] && rlRun "rm -rf $TmpDir" 0 "Cleanup"
    [ -n "$ShimDir" ] && [ -d "$ShimDir" ] && rlRun "rm -rf $ShimDir" 0 "Remove mkfs shim"
    # LTP Package managed by lib.sh 's reference counting auto-uninstall
    rlPhaseEnd

    rlJournalPrintText
rlJournalEnd
