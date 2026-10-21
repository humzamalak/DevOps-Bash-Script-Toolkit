#!/usr/bin/env bats

@test "env_to_k8s_secrets.sh help output" {
  run "$BATS_TEST_DIRNAME/../security/env_to_k8s_secrets.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"env_to_k8s_secrets.sh"* ]]
}
