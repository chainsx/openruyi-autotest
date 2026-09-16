#!/bin/bash
# Security test: openscap cis - eval and report
# Self-contained: runs full oscap eval, checks ARF/HTML and result counts

. /usr/share/beakerlib/beakerlib.sh || exit 1
. "$(dirname $0)/../lib.sh"

rlJournalStart
    rlPhaseStartSetup "Environment Setup"
        cisSetup
        TmpDir=$(mktemp -d)
        rlRun "cd $TmpDir" 0 "Enter tmp dir"
    rlPhaseEnd

    rlPhaseStartTest "CIS Eval and Report"
        if [ ! -f "$CIS_DS" ]; then
            rlFail "Data stream not found"
        else
            out=/tmp/cis_eval_$$
            xml=/tmp/cis_result_$$.xml
            html=/tmp/cis_report_$$.html
            oscap xccdf eval --profile "$CIS_PROFILE" --results-arf "$xml" --report "$html" "$CIS_DS" 2>&1 | tee $out
            rc=${PIPESTATUS[0]}
            if [ $rc -ne 0 ] && [ $rc -ne 2 ]; then
                rlFail "oscap eval failed (exit=$rc)"
            elif [ ! -f "$xml" ]; then
                rlFail "ARF result file not generated"
            elif [ ! -f "$html" ]; then
                rlFail "HTML report not generated"
            else
                pass=$(grep -c '<result>pass</result>' "$xml" 2>/dev/null || echo 0)
                fail=$(grep -c '<result>fail</result>' "$xml" 2>/dev/null || echo 0)
                na=$(grep -c '<result>notapplicable</result>' "$xml" 2>/dev/null || echo 0)
                rlPass "CIS eval complete: pass=$pass fail=$fail notapplicable=$na"
            fi
            rm -f $out $xml $html
        fi
    rlPhaseEnd

    rlPhaseStartCleanup "Cleanup"
        rlRun "cd /" 0 "Leave tmp dir"
        [ -n "$TmpDir" ] && [ -d "$TmpDir" ] && rlRun "rm -rf $TmpDir" 0 "Clean tmp"
    rlPhaseEnd

    rlJournalPrintText
rlJournalEnd