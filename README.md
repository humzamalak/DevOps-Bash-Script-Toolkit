# DevOps Bash Script Toolkit

[![ShellCheck Lint & Test Matrix](https://github.com/humzamalak/DevOps-Bash-Script-Toolkit/actions/workflows/shellcheck.yml/badge.svg?branch=main)](https://github.com/humzamalak/DevOps-Bash-Script-Toolkit/actions/workflows/shellcheck.yml)

A modular, POSIX-compliant toolkit of Bash scripts for infrastructure automation, CI/CD, Kubernetes, containers, monitoring, security, backups, and utilities. Designed for cross-platform use (Ubuntu, macOS, CentOS, Alpine) with robust testing and documentation.

---

## Why Use This Toolkit?

- **Standardization:** Enforces best practices and consistency across environments.
- **Security Hardening:** Automates security tasks (secrets, cleanup, log rotation) to reduce human error and attack surface.
- **Auditability:** All scripts are version-controlled and self-documented.
- **Portability:** Works on all major Linux distros and macOS.
- **Modularity:** Use only what you need; scripts are decoupled and composable.
- **DevOps Enablement:** Accelerates onboarding, reduces toil, and supports CI/CD, monitoring, and backup out-of-the-box.

---

## When and Where to Use These Scripts

This toolkit is designed for a variety of DevOps, SRE, and platform engineering scenarios. Below are practical examples of where and when to use each script category:

- **Infrastructure Automation**
  - Use in CI/CD pipelines to automate Terraform deployments and ensure safe, repeatable infrastructure changes.
  - Run on developer machines or build servers to standardize infrastructure provisioning.
  - Employ rollback features in production to minimize downtime during failed infrastructure changes.

- **Kubernetes Management**
  - Schedule cleanup scripts as CronJobs in your cluster to keep namespaces tidy and avoid resource leaks.
  - Use during incident response to quickly remove failed jobs or pods.
  - Integrate into GitOps workflows for automated cluster hygiene.

- **Container Management**
  - Run on CI/CD runners or build agents to keep Docker environments clean and prevent disk exhaustion.
  - Use in developer environments to automate cleanup of unused images and volumes.
  - Schedule as a cron job on production hosts to maintain healthy container infrastructure.

- **Monitoring**
  - Deploy as part of server bootstrapping to provide lightweight, scriptable monitoring and alerting.
  - Integrate with external alerting systems (e.g., Slack, email) for custom notifications.
  - Use in test environments to validate resource usage and service health.

- **Security**
  - Automate the creation and rotation of Kubernetes secrets from .env files during deployments.
  - Use in CI/CD to inject secrets securely into clusters without manual handling.
  - Employ as part of compliance and audit workflows to ensure secrets are managed as code.

- **Backups**
  - Schedule regular backups to S3 for disaster recovery and business continuity.
  - Use before major deployments or migrations to ensure data safety.
  - Integrate with monitoring scripts to alert on backup failures.

- **Utilities**
  - Automate log rotation on servers to prevent disk space issues and maintain compliance.
  - Use in combination with monitoring scripts for proactive maintenance.

- **CI/CD**
  - Automate build, tagging, and deployment steps in your CI/CD pipelines for consistent, repeatable releases.
  - Use autotagging to enforce semantic versioning based on commit messages.

These scripts are suitable for:
- Production and staging environments
- Developer workstations
- CI/CD runners (GitHub Actions, GitLab CI, Jenkins, etc.)
- Kubernetes clusters (as CronJobs or part of GitOps flows)
- Any environment where automation, reliability, and security are priorities

---

## Folder Structure

| Folder           | Purpose                                      |
|------------------|----------------------------------------------|
| `infrastructure/`| Infrastructure automation (e.g., Terraform)  |
| `ci-cd/`         | CI/CD and version control scripts            |
| `kubernetes/`    | Kubernetes management and cleanup            |
| `containers/`    | Docker/container lifecycle management        |
| `monitoring/`    | System and service monitoring scripts        |
| `security/`      | Security automation and secrets management   |
| `backups/`       | Backup and data protection scripts           |
| `utilities/`     | General system utility scripts               |
| `tests/`         | Bats-core tests for all scripts              |
| `docs/`          | Documentation and templates                  |
| `docs/planning/` | Original planning notes (scope, scenarios, task list) |

---

## Script Overview & Usage

### Infrastructure Automation

#### `infrastructure/terraform_apply_wrapper.sh`
Automates `terraform apply` with safety checks and optional rollback.
```sh
./infrastructure/terraform_apply_wrapper.sh --dir my-tf-dir --auto-approve --rollback
```
- **Options:**  
  `--dir` (directory), `--auto-approve`, `--rollback`, `--help`

---

### Kubernetes Management

#### `kubernetes/k8s_cleanup.sh`
Cleans up completed/failed jobs and old pods in a namespace.
```sh
./kubernetes/k8s_cleanup.sh --namespace dev --age 12
```
- **Options:**  
  `--namespace` (default: default), `--age` (hours, default: 24), `--help`

---

### Container Management

#### `containers/docker_cleanup.sh`
Safely prunes Docker resources and dangling volumes.
```sh
./containers/docker_cleanup.sh --prune --volumes
```
- **Options:**  
  `--prune`, `--volumes`, `--help`

---

### Monitoring

#### `monitoring/monitor_resources.sh`
Monitors CPU, memory, and disk usage, alerting if thresholds are exceeded.
```sh
./monitoring/monitor_resources.sh --cpu 90 --mem 85 --disk 80
```
- **Options:**  
  `--cpu`, `--mem`, `--disk` (all default: 80), `--help`

#### `monitoring/check_service_health.sh`
Checks if a service/process is running and if a port is open.
```sh
./monitoring/check_service_health.sh --service nginx --port 80
```
- **Options:**  
  `--service` (required), `--port`, `--help`

---

### Security

#### `security/env_to_k8s_secrets.sh`
Converts a `.env` file to a Kubernetes secret.
```sh
./security/env_to_k8s_secrets.sh --file .env --namespace dev --secret my-app-secret
```
- **Options:**  
  `--file` (required), `--namespace` (required), `--secret` (required), `--help`

---

### Backups

#### `backups/backup_to_s3.sh`
Backs up files/directories to AWS S3.
```sh
./backups/backup_to_s3.sh --source ./data --bucket my-bucket --key-prefix backups
```
- **Options:**  
  `--source` (required), `--bucket` (required), `--key-prefix`, `--help`

---

### Utilities

#### `utilities/log_rotate.sh`
Rotates and compresses logs by size or age.
```sh
./utilities/log_rotate.sh --file /var/log/app.log --size 100 --age 7
```
- **Options:**  
  `--file` (required), `--size` (MB), `--age` (days), `--help`

---

### CI/CD

#### `ci-cd/build_deploy.sh`
Builds a Docker image and updates a Kubernetes deployment.
```sh
./ci-cd/build_deploy.sh --image myrepo/app:latest --deployment my-app --namespace dev
```
- **Options:**  
  `--image` (required), `--deployment` (required), `--namespace` (default: default), `--help`

#### `ci-cd/autotag.sh`
Auto-increments semantic version tags based on commit messages.
```sh
./ci-cd/autotag.sh --dry-run
```
- **Options:**  
  `--dry-run`, `--help`

---

## Implementation in DevOps Hardening

1. **Integrate scripts into CI/CD pipelines** for automated infrastructure, deployment, and cleanup.
2. **Schedule monitoring and cleanup scripts** via cron or systemd timers to ensure continuous hygiene.
3. **Automate log rotation and backups** to prevent disk exhaustion and ensure data durability.
4. **Use security scripts** to manage secrets and reduce manual handling of sensitive data.
5. **Leverage modularity**: Compose scripts in custom workflows for your environment.
6. **Test scripts** using the provided Bats-core tests in the `tests/` directory before production use.

---

## Getting Started

1. **Clone the repository:**
   ```sh
   git clone https://github.com/your-org/devops-bash-script-toolkit.git
   cd devops-bash-script-toolkit
   ```
2. **Review the folder structure and scripts.**
3. **Run ShellCheck and Bats tests** (see workflows or `tests/`).

---

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for guidelines.

## Security

See [`SECURITY.md`](SECURITY.md) for reporting and best practices.

## Changelog

See [`CHANGELOG.md`](CHANGELOG.md) for release history.

---

## Scalability & Maintainability Analysis

This toolkit is highly scalable due to its modular design—scripts can be used independently or composed into larger workflows. Each script is self-contained, POSIX-compliant, and cross-platform, making it easy to maintain and extend. Adding new scripts or updating existing ones is straightforward, and the use of Bats-core for testing ensures reliability. The structure supports team collaboration, version control, and integration into any DevOps pipeline.

**Next Steps / Improvements:**
- Add more real-world usage examples and advanced workflows to the documentation.
- Expand test coverage and add CI for automated linting and testing.
- Consider packaging scripts for easier distribution (e.g., as a Homebrew tap or Docker image).
- Add more integrations (e.g., Slack/Teams notifications, advanced monitoring hooks).

---

**This README provides a comprehensive overview and practical guidance for using and extending the DevOps Bash Script Toolkit in your infrastructure and DevOps hardening efforts.**
