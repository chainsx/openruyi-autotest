#!/bin/bash

# Functional test: acl - getfacl basic

# Beakerlib-based test with lifecycle management

# Shared suite setup/cleanup via../lib.sh (install once, uninstall once)



. /usr/share/beakerlib/beakerlib.sh || exit 1

. "$(dirname "$0")/../lib.sh"



rlJournalStart

    rlPhaseStartSetup "Environment setup"

    aclSetup

    TmpDir=$(mktemp -d)

    rlRun "cd $TmpDir" 0 "Enter temporary test directory"

    rlRun "touch testfile" 0 "Create test file"

    rlRun "mkdir testdir" 0 "Create test directory"

    rlPhaseEnd



    rlPhaseStartTest "getfacl basic functionality"

    # test 1.1: viewfiledefault ACL

    rlRun "getfacl testfile 2>&1 | grep -qE \"user::|group::|other::\"" 0 "viewfiledefault ACL contains permissionentries"



    # test 1.2: viewdirectorydefault ACL

    rlRun "getfacl testdir 2>&1 | grep -qE \"user::|group::|other::\"" 0 "viewdirectorydefault ACL contains permissionentries"



    # test 1.3: use -a parameter only display access ACL

    rlRun "getfacl -a testfile > out_getfacl_a.txt 2>&1" 0 "use -a parameter view access ACL"

    rlAssertGrep "user::" out_getfacl_a.txt



    # test 1.4: set default ACL on directory and verify it

    rlRun "setfacl -m d:u::rwx,d:g::r-x,d:o::--- testdir" 0 "set default ACL on testdir"

    rlRun "getfacl testdir > out_getfacl_default.txt 2>&1" 0 "getfacl testdir with default ACL"

    rlAssertGrep "default:user::rwx" out_getfacl_default.txt



    # test 1.5: use -c parameternodisplayheader

    rlRun "getfacl -c testfile > out_getfacl_c.txt 2>&1" 0 "use -c parameter no display header"

    rlAssertNotGrep "^# file:" out_getfacl_c.txt



    # test 1.6: use -n parameterdisplaynumberuser/group ID

    rlRun "getfacl -n testfile 2>&1 | grep -qE \"[0-9]+\"" 0 "use -n parameterdisplaynumber ID"



    # test 1.7: use -t parameteruseoutputformat

    rlRun "getfacl -t testfile 2>&1 | grep -qE \"[r-][w-][x-]\"" 0 "use -t parameteroutputcontains permission"

    rlPhaseEnd



    rlPhaseStartCleanup "Clean up test environment"

    rlRun "cd /" 0 "Leave test directory"

    if [ -n "$TmpDir" ] && [ -d "$TmpDir" ]; then

    rlRun "rm -rf $TmpDir" 0 "Clean up temporary test directory"

    fi

    # acl Package managed by lib.sh's reference counting auto-uninstall

    rlPhaseEnd



    rlJournalPrintText

rlJournalEnd
