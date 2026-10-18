#!/bin/zsh
# usage: run.sh <avant|apres> <test> <dir>  (A/B via R15_A/R15_B)
R=/private/tmp/claude-501/-Users-malik-Documents-Boites-a-livres-BoitesALivresNative/fb5c06c5-c77d-4db2-9fc7-e5ee1e152aa8/scratchpad/r015
U=8A8B24AD-8F18-4EBF-AD60-0642803B7855
V=${1:?}; T=${2:?}; D=${3:?}
mkdir -p $R/out/$D; xcrun simctl location $U set 45.9075,6.1240
START=$(date '+%Y-%m-%d %H:%M:%S')
TEST_RUNNER_R15_A=${R15_A:-14183} TEST_RUNNER_R15_B=${R15_B:-227} TEST_RUNNER_R15_OUT=$R/out TEST_RUNNER_R15_DIR=$D \
  timeout 400 xcodebuild test-without-building -project $R/proj-$V/R15$V.xcodeproj -scheme R15 \
  -destination "platform=iOS Simulator,id=$U" -derivedDataPath $R/dd-$V -only-testing:R15UITests/R15Tests/$T \
  > $R/out/$D/xcodebuild.log 2>&1
RC=$?
xcrun simctl spawn $U log show --start "$START" --style compact --predicate 'subsystem == "R015"' > $R/out/$D/r15.log 2>&1
echo "rc=$RC"; grep -E "error:|TEST (EXECUTE )?(SUCCEEDED|FAILED)|passed|failed" $R/out/$D/xcodebuild.log | tail -6
ls $R/out/$D | wc -l
