#!/usr/bin/env bats

@test "monitor_resources.sh help output" {
  run "$BATS_TEST_DIRNAME/../monitoring/monitor_resources.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"monitor_resources.sh"* ]]
}
