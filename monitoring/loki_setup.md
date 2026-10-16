# Loki Log Aggregation Setup

## 1. Overview

This module implements centralized container log aggregation using Grafana Loki, Promtail, and Grafana.

- **Promtail:** Discovers Docker containers and collects their logs.
- **Loki:** Receives, stores, and indexes log streams.
- **Grafana:** Queries Loki and displays logs through Explore.

### Architecture

```text
NGINX Container (Nomad)
        |
        | Docker container logs
        v
     Promtail
        |
        | HTTP push API
        v
       Loki
        |
        | LogQL queries
        v
     Grafana Explore
```

## 2. Prerequisites

- Docker Engine or Docker Desktop with Docker Compose.
- The NGINX application deployed through Nomad.
- Ports 3000 and 3100 available on the host.
- The monitoring configuration files in this directory.

## 3. Start the Monitoring Stack

From the repository root, run:

```bash
docker compose -f monitoring/docker-compose.yaml config -q
docker compose -f monitoring/docker-compose.yaml up -d
docker compose -f monitoring/docker-compose.yaml ps
```

The stack contains:

| Component | Image | Purpose |
|---|---|---|
| Loki | grafana/loki:3.5.0 | Log storage and querying |
| Promtail | grafana/promtail:3.5.0 | Docker log collection |
| Grafana | grafana/grafana:12.0.0 | Log visualization |

## 4. Verify Loki

Check Loki's readiness endpoint:

```bash
curl -fsS http://127.0.0.1:3100/ready
```

Expected response:

```text
ready
```

## 5. Configure Grafana

1. Open http://localhost:3000.
2. Navigate to **Connections → Data sources**.
3. Add a **Loki** data source.
4. Set its URL to `http://loki:3100`.
5. Click **Save & test**.
6. Open **Explore** and select the Loki data source.

The default local Grafana credentials in the Compose configuration are `admin` / `admin`. These are for local development only and must not be used for a publicly exposed deployment.

## 6. Log Labels

Promtail assigns labels to discovered Docker log streams:

- `job`: Identifies the collection job, configured as `docker`.
- `container`: Docker container name.
- `service`: Intended service label for NGINX containers.

Docker discovery may also provide labels such as `service_name`, depending on the active relabeling configuration and discovered metadata.

## 7. LogQL Queries

### Query NGINX container logs

```logql
{container=~".*nginx.*"}
```

### Query all Docker-collected logs

```logql
{job="docker"}
```

### Filter HTTP 200 access entries

```logql
{container=~".*nginx.*"} |= "\" 200 "
```

Run these queries in Grafana Explore and select an appropriate time range, such as **Last 1 hour**.

## 8. Verification Results

The following checks were performed during local testing:

- Docker Compose configuration validation completed successfully.
- Loki's `/ready` endpoint returned `ready`.
- Promtail started and discovered Docker containers.
- The Nomad-managed NGINX endpoint `/healthz` returned HTTP 200 with the body `healthy`.
- Loki's range-query API returned an NGINX access log containing `GET / HTTP/1.1` with status `200`.
- Grafana Explore displayed NGINX container logs.

Screenshot evidence is stored in `docs/screenshots/grafana-loki-logs.png`.

## 9. Troubleshooting

### Promtail restarts because of an invalid configuration

Inspect logs:

```bash
docker compose -f monitoring/docker-compose.yaml logs --tail=80 promtail
```

Ensure Docker discovery uses `docker_sd_configs`, not an unsupported `docker` field under `scrape_configs`.

### Loki rejects old log entries

Promtail may encounter historical logs from containers that existed before the monitoring stack started. Loki can reject entries outside its accepted timestamp window. Restrict collection to the intended containers and inspect Promtail's positions and Docker log sources.

### Grafana cannot connect to Loki

Use `http://loki:3100` as the data source URL from Grafana's container. Check that both services are attached to the Compose network and that Loki reports ready.

### No NGINX logs appear

Generate requests to the current Nomad allocation's mapped host port:

```bash
curl -i http://127.0.0.1:PORT/healthz
curl -i http://127.0.0.1:PORT/
```

Replace `PORT` with the current dynamic port shown by `nomad alloc status ALLOCATION_ID`. Then rerun the NGINX LogQL query.

## 10. Stop the Monitoring Stack

From the repository root:

```bash
docker compose -f monitoring/docker-compose.yaml down
```

Persistent Loki and Grafana data volumes are retained unless explicitly removed.

## 11. Limitations

- This setup is intended for local development and assessment demonstrations.
- Promtail is deprecated upstream; Grafana Alloy is the recommended successor for new deployments.
- Docker socket access gives Promtail substantial visibility into Docker metadata and must be restricted appropriately.
- The stack does not provide production-grade authentication, TLS, high availability, or external storage configuration.
- Container discovery alone does not guarantee that every historical log entry is accepted by Loki.
