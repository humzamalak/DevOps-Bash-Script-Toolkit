#!/usr/bin/env bats

@test "backup_to_s3.sh help output" {
  run "$BATS_TEST_DIRNAME/../backups/backup_to_s3.sh" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"backup_to_s3.sh"* ]]
}
