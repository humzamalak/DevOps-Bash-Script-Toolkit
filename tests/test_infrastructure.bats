#!/usr/bin/env bats

@test "terraform_apply_wrapper.sh help output" {
  run "$BATS_TEST_DIRNAME/../infrastructure/terraform_apply_wrapper.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"terraform_apply_wrapper.sh"* ]]
}
