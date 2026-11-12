# Script Usage Scenarios and Implementation Steps

This document outlines when and why you would use each script in this toolkit, and provides step-by-step instructions for implementing each script to resolve common DevOps issues.



## 1. `utilities/log_rotate.sh`
**Scenario:**
- Your log files are growing too large or too old, risking disk exhaustion or compliance issues.
- You need to automate log rotation and compression on a server.

**Steps to Use:**
1. Identify the log file you want to rotate (e.g., `/var/log/app.log`).
2. Run the script with the required file and optional size/age thresholds:
   ```bash
   ./utilities/log_rotate.sh -f /path/to/logfile.log -s 100 -a 7
   ```
   - `-s 100` rotates if file >100MB.
   - `-a 7` rotates if file >7 days old.
3. Schedule via cron for regular rotation.

---

## 2. `security/env_to_k8s_secrets.sh`
**Scenario:**
- You need to securely inject environment variables into a Kubernetes cluster as secrets.
- You are rotating secrets or deploying to a new environment.

**Steps to Use:**
1. Prepare a `.env` file with your secrets.
2. Run the script with the namespace and secret name:
   ```bash
   ./security/env_to_k8s_secrets.sh -f .env -n my-namespace -s my-secret
   ```
3. The script will create or update the Kubernetes secret.

---

## 3. `monitoring/check_service_health.sh`
**Scenario:**
- You need to verify if a service/process is running and/or if a port is open (e.g., after deployment or during incident response).

**Steps to Use:**
1. Identify the service/process name (e.g., `nginx`) and optional port (e.g., `80`).
2. Run the script:
   ```bash
   ./monitoring/check_service_health.sh -s nginx -p 80
   ```
3. Review the output for service and port status.

---

## 4. `monitoring/monitor_resources.sh`
**Scenario:**
- You want to monitor system CPU, memory, and disk usage and get alerts if thresholds are exceeded.

**Steps to Use:**
1. Optionally set custom thresholds (default is 80% for all):
   ```bash
   ./monitoring/monitor_resources.sh --cpu 90 --mem 85 --disk 95
   ```
2. Schedule via cron for regular monitoring.
3. Review alerts in the output or logs.

---

## 5. `ci-cd/autotag.sh`
**Scenario:**
- You want to automate semantic version tagging in your Git repository based on commit messages (for CI/CD or release automation).

**Steps to Use:**
1. Ensure your repo uses semantic commit messages (`feat:`, `fix:`, `BREAKING CHANGE`).
2. Run the script in your repo:
   ```bash
   ./ci-cd/autotag.sh
   ```
   - Use `--dry-run` to preview the next tag.
3. The script will create a new tag if needed.

---

## 6. `ci-cd/build_deploy.sh`
**Scenario:**
- You need to build a Docker image and deploy it to a Kubernetes cluster (manual or CI/CD pipeline).

**Steps to Use:**
1. Set the image name, deployment, and (optionally) namespace.
2. Run the script:
   ```bash
   ./ci-cd/build_deploy.sh -i myrepo/myimage:tag -d my-deployment -n my-namespace
   ```
3. The script builds, pushes, and updates the deployment.

---

## 7. `backups/backup_to_s3.sh`
**Scenario:**
- You need to back up files or directories to AWS S3 (scheduled backup, pre-deployment, or disaster recovery).

**Steps to Use:**
1. Set the source path and S3 bucket (and optional key prefix).
2. Run the script:
   ```bash
   ./backups/backup_to_s3.sh -s /data -b my-bucket -k backups/2024-06-01
   ```
3. Verify backup completion in the output and on S3.

---

## 8. `containers/docker_cleanup.sh`
**Scenario:**
- Your Docker host is running out of space due to unused images, containers, or volumes.

**Steps to Use:**
1. Decide if you want to prune unused data, volumes, or both.
2. Run the script:
   ```bash
   ./containers/docker_cleanup.sh --prune --volumes
   ```
3. Review the output for cleanup results.

---

## 9. `kubernetes/k8s_cleanup.sh`
**Scenario:**
- Your Kubernetes namespace has many completed jobs or old pods, cluttering the environment.

**Steps to Use:**
1. Set the namespace and age threshold (in hours).
2. Run the script:
   ```bash
   ./kubernetes/k8s_cleanup.sh -n my-namespace --age 48
   ```
3. The script deletes completed jobs and old pods.

---

## 10. `infrastructure/terraform_apply_wrapper.sh`
**Scenario:**
- You want to safely apply Terraform changes with optional auto-approve and rollback on failure.

**Steps to Use:**
1. Set the Terraform config directory (if not current), and decide on auto-approve/rollback.
2. Run the script:
   ```bash
   ./infrastructure/terraform_apply_wrapper.sh -d ./infra --auto-approve --rollback
   ```
3. The script will init, plan, apply, and optionally rollback on failure.

---

# General Notes
- Always review script options with `--help` before running.
- Test scripts in a staging environment before production use.
- Schedule scripts via cron or CI/CD as appropriate for automation.

---

**If you want this file in a specific subdirectory, let me know!** Otherwise, you can now add this file to your repo for easy reference.