#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../utilities/log_rotate.sh"

setup() {
  WORK_DIR="$(mktemp -d)"
  LOG="$WORK_DIR/app.log"
}

teardown() {
  rm -rf "$WORK_DIR"
}

@test "log_rotate.sh help output" {
  run "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"log_rotate.sh"* ]]
}

@test "rotates a file over the size limit" {
  head -c 2097152 /dev/zero > "$LOG"
  run "$SCRIPT" --file "$LOG" --size 1
  [ "$status" -eq 0 ]
  [[ "$output" == *"Rotated and compressed"* ]]
  [ ! -s "$LOG" ]
  ls "$WORK_DIR"/app.log.*.gz
}

@test "rotates a file older than the age limit" {
  echo "old line" > "$LOG"
  touch -t 202001010000 "$LOG"
  run "$SCRIPT" --file "$LOG" --age 7
  [ "$status" -eq 0 ]
  [[ "$output" == *"Rotated and compressed"* ]]
  [ ! -s "$LOG" ]
}

@test "leaves a new, small file alone" {
  echo "new line" > "$LOG"
  run "$SCRIPT" --file "$LOG" --size 100 --age 7
  [ "$status" -eq 0 ]
  [[ "$output" == *"No rotation needed"* ]]
  [ -s "$LOG" ]
}

@test "fails when the file does not exist" {
  run "$SCRIPT" --file "$WORK_DIR/missing.log" --age 1
  [ "$status" -eq 1 ]
}
