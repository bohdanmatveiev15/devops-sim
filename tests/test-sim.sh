#!/usr/bin/env bash
# Checks of bin/sim in a temporary SIM_HOME under /tmp. Run from anywhere: tests/test-sim.sh
# or make test. Exits 0 when every check passes, and 1 otherwise.
#
# The real SIM_HOME is never used. The copy of sim has no chaos next to it, so the heartbeat
# never runs a chaos tick. Terminal input comes from fake devices (SIM_TEST_PTS_DIR), real
# dates from SIM_TEST_TODAY, and gh is replaced by a stub that fails, so standup reads
# tickets/ and needs no network. The run takes about 30 seconds.
set -u
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
T=$(mktemp -d /tmp/sim-test.XXXXXX) || exit 1
mkdir -p "$T/bin" "$T/pts" "$T/stubs"
cp "$REPO/bin/sim" "$T/bin/sim"
SIM="$T/bin/sim"
printf '#!/bin/sh\nexit 1\n' >"$T/stubs/gh"
chmod +x "$T/stubs/gh"
export PATH="$T/stubs:$PATH"
export SIM_HOME="$T/home" SIM_TEST_PTS_DIR="$T/pts"
unset SIM_TEST_TODAY SIM_TEST_IDLE_CLOSE_SECONDS SIM_TEST_HEARTBEAT_SECONDS
mkdir -p "$SIM_HOME"
touch "$T/pts/0"
touch -a -d '@1' "$T/pts/0"
# standup reads the commits and tickets of the current repository.
cd "$REPO" || exit 1

pass=0 fail=0
check() { # <name> <condition...>
    local name=$1; shift
    if "$@"; then echo "OK   $name"; pass=$((pass + 1)); else echo "FAIL $name"; fail=$((fail + 1)); fi
}
has() { grep -q -- "$2" <<<"$1"; }
not() { ! "$@"; }
sim() { "$SIM" "$@"; }
cleanup() { pkill -f "$T/bin/sim __heartbeat" 2>/dev/null; rm -rf "$T"; }
trap cleanup EXIT

echo "== A. Migration from old data =="
cat >"$SIM_HOME/config" <<EOF
START_DATE=2026-11-02
EOF
cat >"$SIM_HOME/worklog.csv" <<EOF
date,start,end,minutes,note
2026-11-02,09:00,10:00,60,
2026-11-03,09:00,09:40,40,"one, task"
2026-11-03,14:00,15:00,60,
2026-11-05,09:00,11:00,120,
2026-11-10,10:00,10:30,30,
EOF
printf '2026-11-04\n2026-11-30\n' >"$SIM_HOME/dayoffs"
echo 1763000000 >"$SIM_HOME/last_standup"
before=$(cd "$SIM_HOME" && md5sum config worklog.csv dayoffs last_standup)
out=$(SIM_TEST_TODAY=2026-11-11 sim status)
check "status works after migration" has "$out" "Session: none"
check "simdays built from worklog and past days off" \
    [ "$(cat "$SIM_HOME/simdays")" = "$(printf '2026-11-02 work\n2026-11-03 work\n2026-11-04 off\n2026-11-05 work\n2026-11-10 work')" ]
after=$(cd "$SIM_HOME" && md5sum config worklog.csv dayoffs last_standup)
check "old files unchanged" [ "$before" = "$after" ]

out=$(SIM_TEST_TODAY=2026-11-11 sim standup)
echo "$out" | sed 's/^/     | /'
check "standup before work shows last day" has "$out" "Simulation day: 5"
check "sim date of day 5 is Friday" has "$out" "Date: 2026-11-06 (Friday)"
check "sprint format" has "$out" "Sprint 1, day 5"
check "work not started hint" has "$out" "Work day not started. Run: sim work"
check "real date line" has "$out" "Real date: 2026-11-11"

echo "== B. Clock moves on a new real date only =="
SIM_TEST_TODAY=2026-11-11 sim start >/dev/null
SIM_TEST_TODAY=2026-11-11 sim stop "first" >/dev/null
SIM_TEST_TODAY=2026-11-11 sim start >/dev/null
SIM_TEST_TODAY=2026-11-11 sim stop "second" >/dev/null
out=$(SIM_TEST_TODAY=2026-11-11 sim standup)
check "two sessions in one real day = one sim day (6)" has "$out" "Simulation day: 6"
check "day 6 is Monday of week 2" has "$out" "Date: 2026-11-09 (Monday)"
check "sprint 2 day 1" has "$out" "Sprint 2, day 1"
check "no hint once started" not has "$out" "Work day not started"

SIM_TEST_TODAY=2026-11-16 sim start >/dev/null  # five real days later
SIM_TEST_TODAY=2026-11-16 sim stop >/dev/null
out=$(SIM_TEST_TODAY=2026-11-16 sim standup)
check "days away do not move the clock (7)" has "$out" "Simulation day: 7"
check "day 7 is Tuesday" has "$out" "Date: 2026-11-10 (Tuesday)"

echo "== C. Day off takes a sim day =="
out=$(SIM_TEST_TODAY=2026-11-16 sim dayoff 2026-11-17)
check "future day off accepted" has "$out" "Day off marked: 2026-11-17"
check "future day off not counted yet" [ "$(grep -c . "$SIM_HOME/simdays")" -eq 7 ]
out=$(SIM_TEST_TODAY=2026-11-17 sim standup)
check "day off counted when it arrives (8)" has "$out" "Simulation day: 8"
check "day off label" has "$out" "Date: 2026-11-11 (Wednesday) (day off)"
SIM_TEST_TODAY=2026-11-18 sim start >/dev/null
SIM_TEST_TODAY=2026-11-18 sim stop >/dev/null
out=$(SIM_TEST_TODAY=2026-11-18 sim standup)
check "work after day off is the next sim day (9, Thu)" has "$out" "Date: 2026-11-12 (Thursday)"
out=$(SIM_TEST_TODAY=2026-11-19 sim dayoff)
check "day off today" [ "$(tail -n 1 "$SIM_HOME/simdays")" = "2026-11-19 off" ]
out=$(SIM_TEST_TODAY=2026-11-19 sim dayoff)
check "repeated day off" has "$out" "Day off already marked"
check "repeated day off adds nothing" [ "$(grep -c . "$SIM_HOME/simdays")" -eq 10 ]
SIM_TEST_TODAY=2026-11-20 sim start >/dev/null
SIM_TEST_TODAY=2026-11-20 sim stop >/dev/null
out=$(SIM_TEST_TODAY=2026-11-20 sim standup)
check "day 11 crosses the weekend to Monday" has "$out" "Date: 2026-11-16 (Monday)"
check "sprint 3 day 1" has "$out" "Sprint 3, day 1"

echo "== D. sim work =="
rm -rf "$SIM_HOME"/inbox
mkdir -p "$SIM_HOME/inbox"
echo "Lead: hello from the inbox" >"$SIM_HOME/inbox/$(($(date +%s) - 10))-lead.msg"
out=$(echo n | SIM_TEST_TODAY=2026-11-23 sim work)
check "answer n does not start" has "$out" "Work day not started"
check "no session after n" [ ! -f "$SIM_HOME/session" ]
out=$(SIM_TEST_TODAY=2026-11-23 sim work </dev/null)
check "EOF does not start" [ ! -f "$SIM_HOME/session" ]
out=$(echo | SIM_TEST_TODAY=2026-11-23 sim work)
echo "$out" | sed 's/^/     | /'
check "Enter starts session" has "$out" "Session started at"
check "work prints standup" has "$out" "=== STANDUP ==="
check "standup shows new day 12" has "$out" "Simulation day: 12"
check "work prints inbox" has "$out" "Lead: hello from the inbox"
check "message marked read" [ -z "$(ls "$SIM_HOME/inbox"/*.msg 2>/dev/null)" ]
echo "Lead: second" >"$SIM_HOME/inbox/$(($(date +%s) - 5))-lead2.msg"
out=$(SIM_TEST_TODAY=2026-11-23 sim work)
echo "$out" | sed 's/^/     | /'
check "open session shows progress" has "$out" "Work day in progress since"
check "open session shows worked today" has "$out" "Worked today:"
check "open session inbox reminder" has "$out" "Inbox: 1 new messages (sim inbox)"
check "no duplicate generic reminder" not has "$out" "You have 1 new messages"
check "message not consumed" [ -n "$(ls "$SIM_HOME/inbox"/*.msg 2>/dev/null)" ]
SIM_TEST_TODAY=2026-11-23 sim pause >/dev/null
out=$(SIM_TEST_TODAY=2026-11-23 sim work)
check "paused session shown" has "$out" "paused since"
SIM_TEST_TODAY=2026-11-23 sim resume >/dev/null
SIM_TEST_TODAY=2026-11-23 sim inbox >/dev/null
SIM_TEST_TODAY=2026-11-23 sim stop >/dev/null
check "heartbeat stopped after stop" not pgrep -f "$T/bin/sim __heartbeat" >/dev/null

echo "== E. Auto-close after idle (heartbeat loop) =="
export SIM_TEST_IDLE_CLOSE_SECONDS=4 SIM_TEST_HEARTBEAT_SECONDS=1
lines=$(grep -c . "$SIM_HOME/worklog.csv")
sim start >/dev/null
for i in 1 2 3 4 5 6; do touch -a "$T/pts/0"; sleep 1; done
check "terminal input keeps session open" [ -f "$SIM_HOME/session" ]
last_input=$(stat -c %X "$T/pts/0")
sleep 8
check "idle session closed by the loop" [ ! -f "$SIM_HOME/session" ]
check "loop exited" not pgrep -f "$T/bin/sim __heartbeat" >/dev/null
check "closed session saved to worklog" [ "$(grep -c . "$SIM_HOME/worklog.csv")" -eq $((lines + 1)) ]
check "saved until last terminal input" \
    [ "$(tail -n 1 "$SIM_HOME/worklog.csv" | cut -d, -f3)" = "$(date -d "@$last_input" +%H:%M)" ]
check "heartbeat files removed" [ ! -e "$SIM_HOME/heartbeat" ] && [ ! -e "$SIM_HOME/heartbeat.pid" ]

echo "== F. Auto-close on the next command when the heartbeat died long ago =="
export SIM_TEST_IDLE_CLOSE_SECONDS=1800 SIM_TEST_HEARTBEAT_SECONDS=60
sim start >/dev/null
pkill -f "$T/bin/sim __heartbeat"; sleep 0.3
echo $(($(date +%s) - 3600)) >"$SIM_HOME/heartbeat"
out=$(sim status)
check "stale session closed with message" has "$out" "Session closed after 30 min without activity"
check "status then shows no session" has "$out" "Session: none"

echo "== G. Old interrupted-session behaviour (heartbeat died recently) =="
sim start >/dev/null
pkill -f "$T/bin/sim __heartbeat"; sleep 0.3
beat=$(($(date +%s) - 120))
echo "$beat" >"$SIM_HOME/heartbeat"
out=$(sim status)
check "status reports interrupted" has "$out" "Session interrupted"
check "sim command does not move a dead heartbeat" [ "$(cat "$SIM_HOME/heartbeat")" = "$beat" ]
out=$(sim stop)
check "stop closes at last heartbeat" has "$out" "Saved until $(date -d "@$beat" +%H:%M)"
sim start >/dev/null
pkill -f "$T/bin/sim __heartbeat"; sleep 0.3
echo $(($(date +%s) - 60)) >"$SIM_HOME/heartbeat"
out=$(echo n | sim work)
check "work closes an interrupted session first" has "$out" "Session was interrupted"

echo "== H. Other old commands =="
check "start twice fails with exit 2" bash -c "'$SIM' start >/dev/null; '$SIM' start >/dev/null 2>&1; [ \$? -eq 2 ]"
sim stop >/dev/null
check "stop without session exits 2" bash -c "'$SIM' stop >/dev/null 2>&1; [ \$? -eq 2 ]"
check "pause without session exits 2" bash -c "'$SIM' pause >/dev/null 2>&1; [ \$? -eq 2 ]"
check "report today" has "$(sim report)" "Report for"
check "report week" has "$(sim report week)" "Total:"
check "report bad arg exits 1" bash -c "'$SIM' report month >/dev/null 2>&1; [ \$? -eq 1 ]"
check "help lists work" has "$(sim help)" "work                  Start the work day"
check "unknown command exits 1" bash -c "'$SIM' nope >/dev/null 2>&1; [ \$? -eq 1 ]"
check "work with args exits 1" bash -c "'$SIM' work x >/dev/null 2>&1; [ \$? -eq 1 ]"
check "inbox empty" has "$(sim inbox)" "No new messages"
cp "$SIM_HOME/simdays" "$T/simdays.before"
echo 2026-12-07 | SIM_TEST_TODAY=2026-12-07 sim init >/dev/null
# The day off of 2026-11-30 arrives before init runs, unless the real date already passed it.
grep -qx "2026-11-30 off" "$T/simdays.before" || echo "2026-11-30 off" >>"$T/simdays.before"
check "init keeps old clock as simdays.bak" cmp -s "$T/simdays.before" "$SIM_HOME/simdays.bak"
out=$(SIM_TEST_TODAY=2026-12-07 sim standup)
check "init restarts the clock" has "$out" "Simulation day: 0"

echo "== I. No config: sim works without the clock =="
rm -rf "$SIM_HOME"; mkdir -p "$SIM_HOME"
out=$(echo | sim work)
check "work without init starts session" has "$out" "Session started"
check "work without init explains" has "$out" "Simulation is not initialized"
check "no simdays without init" [ ! -e "$SIM_HOME/simdays" ]
sim stop >/dev/null

echo
echo "Passed: $pass, failed: $fail"
[ "$fail" -eq 0 ]
