# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
- log_rotate.sh: `--age` now works on Linux (it used BSD `stat` only), and a missing file gives a clear error. Added tests.
- check_service_health.sh: exit 1 when a check fails (it always exited 0), and 2 when `pgrep` or `nc` is missing. Added tests.
- k8s_cleanup.sh: delete only finished pods (Succeeded or Failed); it deleted running pods before. Age now uses the creation time, so pods older than a day are matched. Added `--dry-run` and tests.
- Phase 3: Documentation expansion, 5 new scripts, and test coverage
- terraform_apply_wrapper.sh: removed `--rollback`. It ran `terraform destroy` after a failed apply, which deleted the whole stack, including resources that existed before the apply. The option now exits with an error. Added tests that check a failed apply never runs destroy.

## [Phase 2] - 2025-06-25
- Added 5 core scripts with in-script docs and Bats-core tests
- Initial repo scaffold, CI/CD, and ShellCheck workflow
