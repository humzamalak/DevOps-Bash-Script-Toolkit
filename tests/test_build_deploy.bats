#!/usr/bin/env bats

@test "build_deploy.sh help output" {
  run "$BATS_TEST_DIRNAME/../ci-cd/build_deploy.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"build_deploy.sh"* ]]
}
