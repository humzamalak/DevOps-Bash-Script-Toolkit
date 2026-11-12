#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../monitoring/monitor_resources.sh"

setup() {
  # Fake /proc: memory 75% used; one static stat line, so CPU reads 0%
  FAKE_PROC="$(mktemp -d)"
  printf 'MemTotal:       1000000 kB\nMemFree:         100000 kB\nMemAvailable:    250000 kB\n' > "$FAKE_PROC/meminfo"
  echo "cpu  100 0 100 800 0 0 0 0 0 0" > "$FAKE_PROC/stat"
}

teardown() {
  rm -rf "$FAKE_PROC"
}

@test "monitor_resources.sh help output" {
  run "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"monitor_resources.sh"* ]]
}

@test "Linux: reports memory as a percentage and alerts at the threshold" {
  MONITOR_OS=Linux PROC_DIR="$FAKE_PROC" CPU_SAMPLE_SECONDS=0 run "$SCRIPT" --cpu 50 --mem 70 --disk 101
  [ "$status" -eq 1 ]
  [[ "$output" == *"CPU 0%, memory 75%"* ]]
  [[ "$output" == *"[ALERT] Memory usage is at 75%"* ]]
  [[ "$output" != *"[ALERT] CPU"* ]]
}

@test "Linux: exits 0 when no threshold is reached" {
  MONITOR_OS=Linux PROC_DIR="$FAKE_PROC" CPU_SAMPLE_SECONDS=0 run "$SCRIPT" --mem 80 --disk 101
  [ "$status" -eq 0 ]
  [[ "$output" != *"[ALERT]"* ]]
}

@test "runs on this host and prints all three values" {
  run "$SCRIPT" --cpu 101 --mem 101 --disk 101
  [ "$status" -eq 0 ]
  [[ "$output" =~ CPU\ [0-9]+%,\ memory\ [0-9]+%,\ disk\ [0-9]+% ]]
}

@test "rejects an unsupported OS" {
  MONITOR_OS=Plan9 run "$SCRIPT"
  [ "$status" -eq 2 ]
}

@test "rejects a non-numeric threshold" {
  run "$SCRIPT" --cpu high
  [ "$status" -eq 1 ]
}
