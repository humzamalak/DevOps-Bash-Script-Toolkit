#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../monitoring/check_service_health.sh"

setup() {
  # Stub pgrep and nc: "up-svc" is running and port 8080 is open, nothing else
  STUB_DIR="$(mktemp -d)"
  cat > "$STUB_DIR/pgrep" <<'STUB'
#!/usr/bin/env bash
[[ "${*: -1}" == "up-svc" ]]
STUB
  cat > "$STUB_DIR/nc" <<'STUB'
#!/usr/bin/env bash
[[ "${*: -1}" == "8080" ]]
STUB
  chmod +x "$STUB_DIR/pgrep" "$STUB_DIR/nc"
  export PATH="$STUB_DIR:$PATH"
}

teardown() {
  rm -rf "$STUB_DIR"
}

@test "check_service_health.sh help output" {
  run "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"check_service_health.sh"* ]]
}

@test "exits 0 when the service runs and the port is open" {
  run "$SCRIPT" --service up-svc --port 8080
  [ "$status" -eq 0 ]
  [[ "$output" == *"[OK] Service up-svc is running."* ]]
  [[ "$output" == *"[OK] Port 8080 is open."* ]]
}

@test "exits 1 when the service is not running" {
  run "$SCRIPT" --service down-svc
  [ "$status" -eq 1 ]
  [[ "$output" == *"[FAIL] Service down-svc is not running."* ]]
}

@test "exits 1 when the port is closed" {
  run "$SCRIPT" --service up-svc --port 9999
  [ "$status" -eq 1 ]
  [[ "$output" == *"[FAIL] Port 9999 is not open."* ]]
}

@test "exits 1 when no service is given" {
  run "$SCRIPT"
  [ "$status" -eq 1 ]
}
