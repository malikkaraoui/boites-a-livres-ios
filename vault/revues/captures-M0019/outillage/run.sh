#!/bin/zsh
# usage: run.sh <dir> [test]   -- lance le XCUITest avec vidéo + journal M0019
S=/private/tmp/claude-501/-Users-malik-Documents-Boites-a-livres-BoitesALivresNative/fb5c06c5-c77d-4db2-9fc7-e5ee1e152aa8/scratchpad
U=8A8B24AD-8F18-4EBF-AD60-0642803B7855
DIR=${1:?}; T=${2:-testSwitch}
mkdir -p $S/out/$DIR; xcrun simctl location $U clear; xcrun simctl location $U set 45.9075,6.1240
START=$(date '+%Y-%m-%d %H:%M:%S')
TEST_RUNNER_M19_C=${M19_C:-0} TEST_RUNNER_M19_A=${M19_A:-14183} TEST_RUNNER_M19_B=${M19_B:-227} TEST_RUNNER_M19_OUT=$S/out TEST_RUNNER_M19_DIR=$DIR xcodebuild test -project $S/uit/M19UIT.xcodeproj -scheme M19 \
  -destination "platform=iOS Simulator,id=$U" -derivedDataPath $S/dd-uit -only-testing:M19UITests/M19Tests/$T \
  > $S/out/$DIR/xcodebuild.log 2>&1
RC=$?
xcrun simctl spawn $U log show --start "$START" --style compact --predicate 'subsystem == "M0019"' > $S/out/$DIR/m19.log 2>&1
echo "rc=$RC"; grep -E "Test Case|error|TEST (SUCCEEDED|FAILED)|\*\* " $S/out/$DIR/xcodebuild.log | tail -8
ls $S/out/$DIR | wc -l
