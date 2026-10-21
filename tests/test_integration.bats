#!/usr/bin/env bats

@test "integration: terraform, k8s, docker, monitor, backup" {
  run "$BATS_TEST_DIRNAME/../infrastructure/terraform_apply_wrapper.sh" --help
  [ "$status" -eq 0 ]
  run "$BATS_TEST_DIRNAME/../kubernetes/k8s_cleanup.sh" --help
  [ "$status" -eq 0 ]
  run "$BATS_TEST_DIRNAME/../containers/docker_cleanup.sh" --help
  [ "$status" -eq 0 ]
  run "$BATS_TEST_DIRNAME/../monitoring/monitor_resources.sh" --help
  [ "$status" -eq 0 ]
  run "$BATS_TEST_DIRNAME/../backups/backup_to_s3.sh" --help
  [ "$status" -eq 0 ]
}
