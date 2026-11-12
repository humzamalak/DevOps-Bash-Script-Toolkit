# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
- Phase 3: Documentation expansion, 5 new scripts, and test coverage
- terraform_apply_wrapper.sh: removed `--rollback`. It ran `terraform destroy` after a failed apply, which deleted the whole stack, including resources that existed before the apply. The option now exits with an error. Added tests that check a failed apply never runs destroy.

## [Phase 2] - 2025-06-25
- Added 5 core scripts with in-script docs and Bats-core tests
- Initial repo scaffold, CI/CD, and ShellCheck workflow
