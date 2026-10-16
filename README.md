# DevOps Intern Final Assessment

[![CI/CD](https://github.com/Harshal-112/devops-intern-final/actions/workflows/ci.yml/badge.svg)](https://github.com/Harshal-112/devops-intern-final/actions/workflows/ci.yml)

**Candidate:** Harshal Nerkar  
**Assessment date:** 16 October 2026  
**Repository:** [devops-intern-final](https://github.com/Harshal-112/devops-intern-final)  
**Release tag:** `v1.0.0`

## 1. Project Overview

This project demonstrates an end-to-end DevOps pipeline for a containerised NGINX web application. It covers source control, Linux shell scripting, Docker containerisation, automated CI/CD using GitHub Actions, image publishing to GitHub Container Registry (GHCR), orchestration with HashiCorp Nomad, service health checks through Consul, and log aggregation using Grafana Loki and Promtail.

The application serves a static webpage on port `8080`, runs NGINX as a non-root user, exposes a `/healthz` endpoint, and displays a build identifier injected during the Docker image build.

## 2. Architecture

```text
Developer
   |
   v
GitHub Repository
   |
   v
GitHub Actions
   |-- Lint (ShellCheck + Hadolint)
   |-- Build Docker Image
   |-- Test Container and Health Endpoint
   |-- Publish on Push to main
   |
   v
GitHub Container Registry (GHCR)
   |
   v
HashiCorp Nomad
   |
   v
NGINX Application (Port 8080)
   |
   |-- Consul HTTP Health Check
   |
   v
Promtail --> Loki --> Grafana Explore
```

## 3. Repository Structure

```text
devops-intern-final/
├── README.md
├── .gitignore
├── app/
│   ├── Dockerfile
│   ├── index.html
│   └── nginx.conf
├── scripts/
│   ├── sysinfo.sh
│   └── healthcheck.sh
├── .github/
│   └── workflows/
│       └── ci.yml
├── nomad/
│   └── nginx-app.nomad.hcl
├── monitoring/
│   ├── loki-config.yaml
│   ├── promtail-config.yaml
│   ├── docker-compose.yaml
│   └── loki_setup.md
└── docs/
    └── screenshots/
```

## 4. Prerequisites

Install the following tools before reproducing the project:

- Git
- Docker Engine or Docker Desktop
- Bash
- ShellCheck
- Hadolint
- HashiCorp Nomad
- HashiCorp Consul
- Docker Compose

Check the installed versions:

```bash
git --version
docker --version
docker compose version
nomad version
consul version
shellcheck --version
```

Use the same versions recorded in your working environment when reproducing the assessment. The application uses the pinned base image `nginx:1.27-alpine`.

## 5. Quick Start

Run the following commands from the repository root.

### Clone the repository

```bash
git clone https://github.com/Harshal-112/devops-intern-final.git
cd devops-intern-final
```

### Build the image

```bash
docker build --build-arg BUILD_SHA=local-test -t devops-intern-final:local ./app
```

### Run the application

```bash
docker run -d --name devops-nginx -p 8080:8080 devops-intern-final:local
```

### Test the homepage and health endpoint

```bash
curl -i http://localhost:8080/
curl -i http://localhost:8080/healthz
./scripts/healthcheck.sh http://localhost:8080/healthz
```

The homepage should return HTTP 200 and display the application information and build identifier. The health endpoint should return HTTP 200 with the response body `healthy`.

### Inspect the container

```bash
docker inspect devops-nginx --format '{{.State.Health.Status}}'
docker exec devops-nginx id
docker images devops-intern-final:local
```

The container should report a healthy status after its health check succeeds. The NGINX process runs as a non-root user.

Remove the test container when finished:

```bash
docker rm -f devops-nginx
```

## 6. Task 1: Source Control

The project is maintained in a public GitHub repository with incremental commits and a feature-branch workflow.

Repository: [Harshal-112/devops-intern-final](https://github.com/Harshal-112/devops-intern-final)

The project uses conventional commit message prefixes such as `feat:`, `fix:`, `docs:`, and `ci:`. A feature branch was merged into `main` through a pull request, and the repository contains the `v1.0.0` tag.

Useful commands for inspecting the history:

```bash
git log --oneline --decorate --graph -15
git branch -a
git tag --list
```

## 7. Task 2: Linux Scripting

Two executable shell scripts are provided under `scripts/`.

### `scripts/sysinfo.sh`

Reports host and system information, including the current user, effective UID, hostname, kernel release, system date, disk usage, memory usage, and Docker daemon status.

Run it with:

```bash
./scripts/sysinfo.sh
```

### `scripts/healthcheck.sh`

Accepts a target URL as its first argument and checks whether the endpoint returns HTTP 200.

Run it with:

```bash
./scripts/healthcheck.sh http://localhost:8080/healthz
```

The script exits with status `0` on success and a non-zero status on failure, with a diagnostic message.

Check script permissions and linting:

```bash
git ls-files --stage scripts/sysinfo.sh scripts/healthcheck.sh
shellcheck scripts/sysinfo.sh scripts/healthcheck.sh
```

Both scripts were checked with ShellCheck during development.

## 8. Task 3: Docker Containerisation

The Docker configuration is located in `app/`.

### Implementation

- Base image: `nginx:1.27-alpine`
- Custom NGINX configuration: `app/nginx.conf`
- Application port: `8080`
- Health endpoint: `/healthz`
- Non-root NGINX runtime
- Docker `HEALTHCHECK` instruction
- Build argument: `BUILD_SHA`
- Static homepage: `app/index.html`

### Build and run

```bash
docker build --build-arg BUILD_SHA=local-test -t devops-intern-final:local ./app
docker run -d --name devops-nginx -p 8080:8080 devops-intern-final:local
```

### Verify HTTP responses

```bash
curl -i http://localhost:8080/
curl -i http://localhost:8080/healthz
```

Expected results:

- `/` returns HTTP 200 and the application webpage.
- `/healthz` returns HTTP 200 and `healthy`.

### Verify image size and health

```bash
docker images devops-intern-final:local
docker inspect devops-nginx --format '{{.State.Health.Status}}'
docker exec devops-nginx id
```

Record the actual `docker images` output and confirm the image is under the assessment's 60 MB limit in your environment.

## 9. Task 4: Continuous Integration and Delivery

The workflow is defined in `.github/workflows/ci.yml`.

It runs on pushes to `main` and `feature/**`, and on pull requests targeting `main`.

The workflow includes the following stages:

1. **Lint:** ShellCheck for shell scripts and Hadolint for the Dockerfile.
2. **Build:** Builds the Docker image with the commit SHA supplied as `BUILD_SHA`.
3. **Test:** Starts the application container, checks readiness, runs the health-check script, and verifies the build identifier.
4. **Publish:** On pushes to `main`, publishes the image to GHCR with the commit SHA and `latest` tags.

The workflow uses GitHub Actions with major-version tags and `GITHUB_TOKEN` permissions for registry publishing. No long-lived registry credentials should be committed to the repository.

### Verify the workflow

Open the [GitHub Actions page](https://github.com/Harshal-112/devops-intern-final/actions) and confirm that the latest workflow on `main` completed successfully.

### Published container image

The image is published to:

`ghcr.io/harshal-112/devops-intern-final`

The workflow publishes tags for the commit SHA and `latest`.

To pull and run the image:

```bash
docker pull ghcr.io/harshal-112/devops-intern-final:latest
docker run -d --name devops-nginx-ghcr -p 8080:8080 ghcr.io/harshal-112/devops-intern-final:latest
curl -i http://localhost:8080/healthz
```

If port `8080` is already occupied, stop the previous test container or use another host port, such as `8081:8080`.

## 10. Task 5: Orchestration with Nomad

The Nomad job specification is located at:

`nomad/nginx-app.nomad.hcl`

It defines a service job with one group and one Docker task. The job uses dynamic host port allocation, mapping the named `http` port to container port `8080`.

The configuration includes:

- CPU allocation: 100 MHz
- Memory allocation: 64 MB
- Consul service registration
- HTTP health check against `/healthz`
- Health check interval: 10 seconds
- Health check timeout: 2 seconds
- Rolling update configuration
- Restart and reschedule policies

### Validate the job

```bash
nomad job validate nomad/nginx-app.nomad.hcl
```

### Plan the deployment

```bash
nomad job plan nomad/nginx-app.nomad.hcl
```

### Deploy the GHCR image

The image tag is configurable through the `image` variable. The following command explicitly selects the published image:

```bash
nomad job run -var="image=ghcr.io/harshal-112/devops-intern-final:latest" nomad/nginx-app.nomad.hcl
```

### Verify deployment health

```bash
nomad job status nginx-app
nomad alloc status <ALLOCATION_ID>
```

Replace `<ALLOCATION_ID>` with the allocation ID returned by Nomad. Confirm that the allocation is running and healthy and that the Consul health check passes.

The job was validated and deployed in a local Nomad development environment during testing. A local development environment is intended for assessment and does not provide production-grade availability or security.

## 11. Task 6: Log Aggregation with Grafana Loki

The monitoring configuration is located in `monitoring/`:

- `docker-compose.yaml`: Starts Loki, Promtail, and Grafana.
- `loki-config.yaml`: Configures Loki storage and schema.
- `promtail-config.yaml`: Configures log collection and labels.
- `loki_setup.md`: Documents monitoring setup, queries, troubleshooting, and verification.

### Start the monitoring stack

```bash
docker compose -f monitoring/docker-compose.yaml up -d
docker compose -f monitoring/docker-compose.yaml ps
```

Check Loki readiness:

```bash
curl -i http://localhost:3100/ready
```

Open Grafana at [http://localhost:3000](http://localhost:3000). Use the local credentials configured for the assessment environment, and change default credentials before using any non-disposable environment.

### Generate an NGINX access log

Make a successful request and a deliberately missing-path request:

```bash
curl -i http://localhost:8080/
curl -i http://localhost:8080/this-path-does-not-exist
```

The second request should produce a non-200 access-log entry.

### Query logs in Grafana Explore

Select Loki as the data source and use the following LogQL query to isolate NGINX container logs:

```logql
{container=~".*nginx.*"}
```

To filter for non-200 responses, use:

```logql
{container=~".*nginx.*"} |~ "\" (4[0-9][0-9]|5[0-9][0-9]) "
```

Verify that the returned log lines include the missing-path request and its HTTP status code.

Promtail attaches labels including `job`, `container`, and `service`. Its current positions file is configured at `/tmp/positions.yaml`.

### Screenshot evidence

The repository includes a Grafana Explore screenshot at:

`docs/screenshots/grafana-loki-logs.png`

Open `monitoring/loki_setup.md` for the complete monitoring setup, label configuration, LogQL queries, observed results, and troubleshooting notes.

## 12. Troubleshooting

### Docker daemon is unavailable

**Symptom:** Docker commands cannot connect to the daemon.

**Resolution:** Start Docker Desktop or the Docker Engine service, then run:

```bash
docker version
docker info
```

Confirm that both client and server information are available.

### Port 8080 is already occupied

**Symptom:** Docker cannot bind the requested host port.

**Resolution:** Identify the process or container using the port. Stop the conflicting container if appropriate, or use another host port:

```bash
docker run -d --name devops-nginx -p 8081:8080 devops-intern-final:local
```

### Container health check fails

**Symptom:** The container reports `unhealthy` or the health endpoint does not return HTTP 200.

**Resolution:** Inspect the health-check details and container logs:

```bash
docker inspect devops-nginx --format '{{json .State.Health}}'
docker logs devops-nginx
curl -i http://localhost:8080/healthz
```

Check that NGINX is listening on port `8080` and that the custom configuration is copied into the image.

### Nomad deployment fails

**Symptom:** The job cannot be deployed or its allocation fails.

**Resolution:** Validate and plan the job, then inspect its status:

```bash
nomad job validate nomad/nginx-app.nomad.hcl
nomad job plan nomad/nginx-app.nomad.hcl
nomad job status nginx-app
```

Check that Nomad and Consul are running, that the GHCR image is accessible, and that the task has sufficient resources.

### Loki does not show application logs

**Symptom:** Grafana Explore returns no NGINX logs.

**Resolution:** Check the monitoring containers and Loki readiness:

```bash
docker compose -f monitoring/docker-compose.yaml ps
curl -i http://localhost:3100/ready
docker compose -f monitoring/docker-compose.yaml logs promtail
docker compose -f monitoring/docker-compose.yaml logs loki
```

Confirm that Promtail can access the Docker socket and container logs, then generate a new HTTP request and retry the LogQL query.

## 13. Known Limitations

- The Nomad and Consul deployment uses a local development environment; production security, high availability, and persistent infrastructure are not configured.
- Promtail stores its positions file under `/tmp`. Recreating the Promtail container can lose the saved position and may cause previously read logs to be reread.
- The CI workflow builds separate images for testing and publishing rather than promoting the exact same tested image artifact.
- The monitoring stack uses local configuration intended for an assessment environment. Authentication, retention, resource limits, and production operational controls need further hardening.
- The published `latest` tag is convenient for demonstrations but is mutable. A commit-SHA tag is preferable when reproducing a specific deployment.

## 14. Assessment Status

- [x] Public repository created with incremental Git history.
- [x] Feature branch and merged pull request completed.
- [x] `v1.0.0` tag created.
- [x] Linux scripts created and checked with ShellCheck.
- [x] NGINX Docker image built and locally tested.
- [x] GitHub Actions workflow executed successfully on `main`.
- [x] GHCR image published.
- [x] Nomad job validated and deployed in a local development environment.
- [x] Basic Loki log ingestion verified in Grafana Explore.
- [x] README evidence and screenshot references checked against a fresh clone.
- [x] Final assessment submission verified.


