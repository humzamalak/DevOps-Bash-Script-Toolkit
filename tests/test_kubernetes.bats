#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../kubernetes/k8s_cleanup.sh"

setup() {
  # Stub kubectl on PATH: print fixed jobs and pods, log every delete
  STUB_DIR="$(mktemp -d)"
  export KUBECTL_LOG="$STUB_DIR/deletes.log"
  : > "$KUBECTL_LOG"
  cat > "$STUB_DIR/kubectl" <<'STUB'
#!/usr/bin/env bash
args="$*"
case "$args" in
  *"get jobs"*)
    echo "job.batch/done-job";;
  *"get pods"*)
    echo "old-running Running 2020-01-01T00:00:00Z"
    echo "old-pending Pending 2020-01-01T00:00:00Z"
    echo "old-succeeded Succeeded 2020-01-01T00:00:00Z"
    echo "old-failed Failed 2020-01-01T00:00:00Z"
    echo "new-succeeded Succeeded 2099-01-01T00:00:00Z";;
  *"delete"*)
    echo "${args##*delete }" >> "$KUBECTL_LOG";;
esac
exit 0
STUB
  chmod +x "$STUB_DIR/kubectl"
  export PATH="$STUB_DIR:$PATH"
}

teardown() {
  rm -rf "$STUB_DIR"
}

@test "k8s_cleanup.sh help output" {
  run "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"k8s_cleanup.sh"* ]]
}

@test "deletes only finished pods older than --age, and completed jobs" {
  run "$SCRIPT" --namespace dev --age 24
  [ "$status" -eq 0 ]
  run cat "$KUBECTL_LOG"
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" = "job done-job" ]
  [ "${lines[1]}" = "pod old-succeeded" ]
  [ "${lines[2]}" = "pod old-failed" ]
}

@test "never deletes running or pending pods" {
  run "$SCRIPT" --age 0
  [ "$status" -eq 0 ]
  run grep -E "old-running|old-pending" "$KUBECTL_LOG"
  [ "$status" -eq 1 ]
}

@test "--dry-run deletes nothing" {
  run "$SCRIPT" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"Would delete pod/old-succeeded"* ]]
  [ ! -s "$KUBECTL_LOG" ]
}

@test "rejects a non-numeric --age" {
  run "$SCRIPT" --age 3d
  [ "$status" -eq 1 ]
}
