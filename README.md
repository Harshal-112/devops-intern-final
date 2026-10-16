# DevOps Intern Final Assessment

[![CI/CD](https://github.com/Harshal-112/devops-intern-final/actions/workflows/ci.yml/badge.svg)](https://github.com/Harshal-112/devops-intern-final/actions/workflows/ci.yml)

## Project Overview

This project demonstrates a reproducible DevOps pipeline for a containerized NGINX application using Docker, GitHub Actions, GitHub Container Registry (GHCR), HashiCorp Nomad, Consul, and Grafana Loki.

## Architecture

```text
Developer
   |
   v
GitHub Repository
   |
   v
GitHub Actions
(Lint -> Build -> Test)
   |
   v
GitHub Container Registry
   |
   v
Nomad Deployment
   |
   v
Consul Health Checks
   |
   v
Promtail -> Loki -> Grafana
```

## Prerequisites

- Git
- Docker Engine or Docker Desktop
- Bash and ShellCheck
- Hadolint
- HashiCorp Nomad and Consul
- Docker Compose

## Quick Start

Run these commands from the repository root:

```bash
docker build --build-arg BUILD_SHA=local-test -t devops-intern-final:local ./app

docker run -d --name devops-nginx -p 8080:8080 devops-intern-final:local

curl -i http://localhost:8080/
curl -i http://localhost:8080/healthz

./scripts/healthcheck.sh http://localhost:8080/healthz

docker inspect devops-nginx --format '{{.State.Health.Status}}'
docker exec devops-nginx id
docker images devops-intern-final:local
```

The homepage displays the candidate name and build identifier. The `/healthz` endpoint returns HTTP 200 when NGINX is responding.

To remove the test container:

```bash
docker rm -f devops-nginx
```

## Repository Structure

| Path | Description |
|---|---|
| `app/` | NGINX Dockerfile, configuration, and static webpage |
| `scripts/sysinfo.sh` | Displays system information and Docker status |
| `scripts/healthcheck.sh` | Checks an HTTP endpoint and reports failure using its exit code |
| `.github/workflows/ci.yml` | GitHub Actions lint, build, test, and image publishing workflow |
| `nomad/` | Nomad deployment configuration |
| `monitoring/` | Loki, Promtail, and Grafana configuration |
| `docs/screenshots/` | Screenshots and assessment evidence |

## CI/CD Workflow

The GitHub Actions workflow runs on pushes to `main` and `feature/**`, and on pull requests targeting `main`.

It performs:

1. ShellCheck validation of the Bash scripts.
2. Hadolint validation of the Dockerfile.
3. Docker image build with the Git commit SHA.
4. Container startup and health-check testing.
5. Verification that the served page contains the build identifier.
6. Image publishing to GHCR on pushes to `main`, using commit SHA and `latest` tags.

## Troubleshooting

- **Docker daemon unavailable:** Ensure Docker Desktop is running and `docker version` displays both client and server information.
- **Port 8080 is occupied:** Identify the process or container using the port before stopping the conflicting service.
- **Container health is still starting:** Wait a few seconds, then inspect `docker inspect devops-nginx --format '{{json .State.Health}}'` and `docker logs devops-nginx`.
- **Health check fails:** Verify that the container is running and `/healthz` returns HTTP 200.

## Known Limitations

- The local image is intended for assessment and demonstration.
- Nomad deployment and log aggregation require separate configuration and verification.
- The current workflow builds separate images for testing and publishing rather than promoting a single tested image artifact.

## Assessment Status

- [x] Linux scripting
- [x] NGINX container created and locally tested
- [x] GitHub Actions workflow created and locally validated
- [ ] GitHub CI run verified
- [ ] Nomad deployment verified
- [ ] Loki log aggregation verified
- [ ] Final documentation and screenshots completed
