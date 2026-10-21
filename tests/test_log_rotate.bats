#!/usr/bin/env bats

@test "log_rotate.sh help output" {
  run "$BATS_TEST_DIRNAME/../utilities/log_rotate.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"log_rotate.sh"* ]]
}
