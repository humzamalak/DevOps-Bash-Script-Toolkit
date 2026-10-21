#!/usr/bin/env bats

@test "autotag.sh help output" {
  run "$BATS_TEST_DIRNAME/../ci-cd/autotag.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"autotag.sh"* ]]
}
