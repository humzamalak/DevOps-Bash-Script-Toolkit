#!/usr/bin/env bats

@test "docker_cleanup.sh help output" {
  run "$BATS_TEST_DIRNAME/../containers/docker_cleanup.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"docker_cleanup.sh"* ]]
}
