#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../infrastructure/terraform_apply_wrapper.sh"

setup() {
  # Stub terraform on PATH: log each call; fail 'apply' when TF_STUB_FAIL_APPLY=1
  STUB_DIR="$(mktemp -d)"
  export TF_CALLS="$STUB_DIR/calls.log"
  cat > "$STUB_DIR/terraform" <<'STUB'
#!/usr/bin/env bash
echo "$*" >> "$TF_CALLS"
if [[ "$1" == "apply" && "${TF_STUB_FAIL_APPLY:-0}" == "1" ]]; then
  exit 1
fi
exit 0
STUB
  chmod +x "$STUB_DIR/terraform"
  export PATH="$STUB_DIR:$PATH"
}

teardown() {
  rm -rf "$STUB_DIR"
}

@test "terraform_apply_wrapper.sh help output" {
  run "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"terraform_apply_wrapper.sh"* ]]
}

@test "successful apply runs init, plan and apply" {
  run "$SCRIPT" --dir "$STUB_DIR" --auto-approve
  [ "$status" -eq 0 ]
  [[ "$output" == *"[SUCCESS]"* ]]
  run cat "$TF_CALLS"
  [ "${lines[0]}" = "init" ]
  [ "${lines[1]}" = "plan" ]
  [ "${lines[2]}" = "apply -auto-approve" ]
}

@test "failed apply exits non-zero and never runs terraform destroy" {
  TF_STUB_FAIL_APPLY=1 run "$SCRIPT" --dir "$STUB_DIR" --auto-approve
  [ "$status" -eq 1 ]
  [[ "$output" == *"Terraform apply failed"* ]]
  run grep -c destroy "$TF_CALLS"
  [ "$output" = "0" ]
}

@test "--rollback is rejected and runs no terraform command" {
  run "$SCRIPT" --dir "$STUB_DIR" --rollback
  [ "$status" -eq 2 ]
  [[ "$output" == *"--rollback was removed"* ]]
  [ ! -f "$TF_CALLS" ]
}
