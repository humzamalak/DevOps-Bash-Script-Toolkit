# DevOps Bash Script Toolkit

[![ShellCheck Lint & Test Matrix](https://github.com/humzamalak/DevOps-Bash-Script-Toolkit/actions/workflows/shellcheck.yml/badge.svg?branch=main)](https://github.com/humzamalak/DevOps-Bash-Script-Toolkit/actions/workflows/shellcheck.yml)

Ten small Bash scripts for routine DevOps tasks: running Terraform, cleaning up Kubernetes and Docker, checking hosts and services, loading secrets into Kubernetes, backing up to S3, rotating logs, and building, deploying and tagging releases.

Each script is standalone. It takes command-line flags, prints `[INFO]`, `[ERROR]` or `[SUCCESS]` lines, runs with `set -euo pipefail`, and prints its own help with `--help`. You can run a script by hand, from cron, or as a step in a CI pipeline.

## Scripts

| Script | What it does | Needs |
|--------|--------------|-------|
| [`infrastructure/terraform_apply_wrapper.sh`](infrastructure/terraform_apply_wrapper.sh) | Runs `terraform init`, `plan` and `apply` in a directory. Stops with an error if apply fails. Never runs `terraform destroy`. | `terraform` |
| [`kubernetes/k8s_cleanup.sh`](kubernetes/k8s_cleanup.sh) | Deletes completed jobs, and finished pods older than a given number of hours, in one namespace. | `kubectl` |
| [`containers/docker_cleanup.sh`](containers/docker_cleanup.sh) | Runs `docker system prune -f` and/or `docker volume prune -f`. | `docker` |
| [`monitoring/monitor_resources.sh`](monitoring/monitor_resources.sh) | Compares CPU, memory and root disk usage with thresholds and prints an alert line for each one exceeded. | macOS (`top -l`, `vm_stat`) |
| [`monitoring/check_service_health.sh`](monitoring/check_service_health.sh) | Checks that a process is running and, optionally, that a port is open on `127.0.0.1`. | `pgrep`, `nc` |
| [`security/env_to_k8s_secrets.sh`](security/env_to_k8s_secrets.sh) | Creates or updates a Kubernetes generic secret from a `.env` file. | `kubectl` |
| [`backups/backup_to_s3.sh`](backups/backup_to_s3.sh) | Syncs a local directory to an S3 bucket with `aws s3 sync`. | AWS CLI with credentials |
| [`utilities/log_rotate.sh`](utilities/log_rotate.sh) | Compresses a log file to a timestamped `.gz` copy and empties the original, when it passes a size or age limit. | `gzip` |
| [`ci-cd/build_deploy.sh`](ci-cd/build_deploy.sh) | Builds and pushes a Docker image from the current directory, then sets it on a Kubernetes deployment. | `docker`, `kubectl` |
| [`ci-cd/autotag.sh`](ci-cd/autotag.sh) | Reads commit messages since the last tag and creates the next semantic version tag. | `git` |

## Quick start

```sh
git clone https://github.com/humzamalak/DevOps-Bash-Script-Toolkit.git
cd DevOps-Bash-Script-Toolkit

# Every script prints its options
./kubernetes/k8s_cleanup.sh --help

# Example: preview the next release tag without creating it
./ci-cd/autotag.sh --dry-run
```

Each script calls external tools (see the Needs column), so install those first. The scripts use `#!/usr/bin/env bash`.

## Usage

### Terraform apply

```sh
./infrastructure/terraform_apply_wrapper.sh --dir ./envs/dev --auto-approve
```

| Option | Meaning |
|--------|---------|
| `-d`, `--dir` | Directory with the Terraform configuration (default: current directory) |
| `--auto-approve` | Pass `-auto-approve` to `terraform apply` |

If `apply` fails, the script exits with code 1. Terraform keeps any resources it created or changed before the error, so run `terraform plan`, fix the cause and run the script again. The old `--rollback` option ran `terraform destroy` on the whole stack; it now exits with code 2.

### Kubernetes clean-up

```sh
./kubernetes/k8s_cleanup.sh --namespace dev --age 12 --dry-run   # preview
./kubernetes/k8s_cleanup.sh --namespace dev --age 12
```

| Option | Meaning |
|--------|---------|
| `-n`, `--namespace` | Namespace (default: `default`) |
| `--age` | Delete finished pods at least this many hours old (default: 24) |
| `--dry-run` | Print what would be deleted, but delete nothing |

The script deletes pods only in phase `Succeeded` or `Failed`. It never deletes `Running`, `Pending` or `Unknown` pods. Age is measured from each pod's creation time. Only jobs with a successful completion are deleted; failed jobs stay.

### Docker clean-up

```sh
./containers/docker_cleanup.sh --prune --volumes
```

| Option | Meaning |
|--------|---------|
| `--prune` | Run `docker system prune -f` (stopped containers, unused networks, dangling images, build cache) |
| `--volumes` | Run `docker volume prune -f` (unused volumes) |

With no option, the script does nothing.

### Resource monitoring

```sh
./monitoring/monitor_resources.sh --cpu 90 --mem 85 --disk 80
```

| Option | Meaning |
|--------|---------|
| `--cpu`, `--mem`, `--disk` | Alert thresholds in per cent (default: 80 each) |

The CPU and memory checks use macOS commands, so the script runs on macOS only. The memory value is the `vm_stat` "Pages active" count, not a percentage. Alerts are printed lines; the exit code is 0 either way.

### Service health

```sh
./monitoring/check_service_health.sh --service nginx --port 80
```

| Option | Meaning |
|--------|---------|
| `-s`, `--service` | Exact process name for `pgrep -x` (required) |
| `-p`, `--port` | Port to test on `127.0.0.1` (optional) |

The script prints `[OK]` or `[FAIL]` for each check. It exits with code 0 even when a check fails, so read the output rather than the exit code.

### `.env` to Kubernetes secret

```sh
./security/env_to_k8s_secrets.sh --file .env --namespace dev --secret my-app-secret
```

| Option | Meaning |
|--------|---------|
| `-f`, `--file` | Path to the `.env` file (required) |
| `-n`, `--namespace` | Namespace (required) |
| `-s`, `--secret` | Secret name (required) |

The script generates the secret with `kubectl create secret generic --from-env-file --dry-run=client` and pipes it to `kubectl apply`, so running it again updates the secret. The values are not printed.

### Back up to S3

```sh
./backups/backup_to_s3.sh --source ./data --bucket my-bucket --key-prefix backups/app
```

| Option | Meaning |
|--------|---------|
| `-s`, `--source` | Local directory to sync (required) |
| `-b`, `--bucket` | Bucket name (required) |
| `-k`, `--key-prefix` | Key prefix inside the bucket (optional) |

`aws s3 sync` copies new and changed files only and does not delete objects in the bucket. The source must be a directory.

### Log rotation

```sh
./utilities/log_rotate.sh --file /var/log/app.log --size 100 --age 7
```

| Option | Meaning |
|--------|---------|
| `-f`, `--file` | Log file (required) |
| `-s`, `--size` | Rotate when the file is at least this many MB (optional) |
| `-a`, `--age` | Rotate when the file was last changed at least this many days ago (optional) |

The script writes `app.log.YYYYMMDDHHMMSS.gz` next to the file, then empties `app.log`. It does not delete old archives. `--age` uses the BSD form of `stat` and works on macOS only; `--size` works on Linux and macOS.

### Build and deploy

```sh
./ci-cd/build_deploy.sh --image registry.example.com/app:1.4.0 --deployment app --namespace dev
```

| Option | Meaning |
|--------|---------|
| `-i`, `--image` | Image name and tag (required) |
| `-d`, `--deployment` | Deployment name (required) |
| `-n`, `--namespace` | Namespace (default: `default`) |

Run it from the directory that holds the `Dockerfile`. The script assumes the container inside the deployment has the same name as the deployment.

### Release tagging

```sh
./ci-cd/autotag.sh --dry-run   # show the next tag
./ci-cd/autotag.sh             # create it
git push --tags                # the script does not push
```

The script reads commit messages since the latest tag and bumps the version from them:

| Commit message | Bump |
|----------------|------|
| Contains `BREAKING CHANGE`, or starts with `type!:` | major |
| Starts with `feat:` or `feat(scope):` | minor |
| Starts with `fix:` or `fix(scope):` | patch |

The largest bump wins. If there is no tag yet, it starts from `0.0.0`. A leading `v` on the existing tag is kept. If no commit matches, it creates no tag.

## Tests and CI

The [ShellCheck Lint & Test Matrix](.github/workflows/shellcheck.yml) workflow runs on every push and pull request to `main`, on Ubuntu, macOS, Alpine and Rocky Linux:

1. ShellCheck on every `.sh` file.
2. The [Bats](https://github.com/bats-core/bats-core) tests in `tests/`.

Run the same checks locally:

```sh
find . -type f -name '*.sh' -exec shellcheck --shell=bash {} +
bats tests/
```

Test coverage is limited. Every script has a test that `--help` works. `terraform_apply_wrapper.sh` also has behaviour tests that use a stub `terraform` to check that a failed apply exits with an error and never calls `destroy`. The other scripts have no behaviour tests yet.

Pushing a tag runs the [release workflow](.github/workflows/release.yml), which creates a GitHub release with notes taken from `CHANGELOG.md`.

## Repository layout

```text
infrastructure/   Terraform wrapper
kubernetes/       Kubernetes clean-up
containers/       Docker clean-up
monitoring/       Resource and service checks
security/         .env to Kubernetes secret
backups/          S3 backup
utilities/        Log rotation
ci-cd/            Build, deploy and release tagging
tests/            Bats tests
docs/             Script documentation template and planning notes
```

## Contributing, security and licence

- [CONTRIBUTING.md](CONTRIBUTING.md): how to add or change a script.
- [SECURITY.md](SECURITY.md): how to report a vulnerability.
- [CHANGELOG.md](CHANGELOG.md): release history.
- Licence: [MIT](LICENSE).
