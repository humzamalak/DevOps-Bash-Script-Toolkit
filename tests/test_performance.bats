#!/usr/bin/env bats

@test "performance: monitor_resources.sh runs under 2s" {
  start=$(date +%s)
  run "$BATS_TEST_DIRNAME/../monitoring/monitor_resources.sh" --help
  end=$(date +%s)
  duration=$((end - start))
  [ "$status" -eq 0 ]
  [ "$duration" -lt 2 ]
}
