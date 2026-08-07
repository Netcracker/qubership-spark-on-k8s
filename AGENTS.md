# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Project Overview

This repository contains Helm charts and Docker images to run Apache Spark on Kubernetes. It wraps the [Kubeflow Spark Operator](https://github.com/kubeflow/spark-operator) with custom enhancements for S3 connectivity, certificate handling, Spark History Server, and Spark Thrift Server.

The deployable artifact is a Helm chart assembled from multiple sub-charts. It is distributed via a Docker transfer image (`qubership-spark-on-k8s-transfer`) or built locally with `create_chart.sh`.

## Building

### Assemble the Helm chart locally

```bash
./create_chart.sh
# Output: ./target/chart/spark-on-k8s/
```

This copies `chart/helm/*`, downloads the upstream spark-operator v2.1.0 chart, and merges in the sub-charts from `spark-history-server/`, `spark-service-integration-tests/`, and `spark-thrift-server/`.

### Build Docker images

Images are built via GitHub Actions using `.github/docker-build-config.json`. For local builds, use the Dockerfiles directly:

- Main Spark image: `spark-customized/Dockerfile` (builds on `apache/spark:4.2.0`, adds AWS SDK, Hadoop AWS, Netty, Jackson JARs)
- Python variant: `spark-customized/py/Dockerfile` (extends the main image, adds Python 3.11)
- Spark Operator image: `spark-operator-image/Dockerfile` (builds on `ghcr.io/kubeflow/spark-operator/controller:2.5.1`, adds AWS SDK, Hadoop AWS, Netty, Jackson JARs, upgrades jersey-client, adds gosu and gnupg)
- Test runner image: `spark-service-integration-tests/docker/Dockerfile` (builds on `ghcr.io/netcracker/qubership-docker-integration-tests:0.5.8`, copies Robot Framework suites and requirements)

### Build sample apps (Maven)

Each sample app under `spark-sample-apps/` is a standalone Maven project targeting Java 1.8:

```bash
cd spark-sample-apps/<app-name>
mvn package
```

## Integration Tests

Tests use [Robot Framework](https://robotframework.org/) and run inside a Docker container (`qubership-spark-on-k8s-tests`). Test suites are in `spark-service-integration-tests/robot/tests/`:

- `alerts/alerts.robot` — Prometheus alerting rules
- `image_tests/image_tests.robot` — Image integrity checks
- `test-app/testapp.robot` — SparkApplication CR deployment and execution

The test container inherits from `ghcr.io/netcracker/qubership-docker-integration-tests` and runs Robot Framework against a live Kubernetes cluster.

## CI/CD

All workflows are in `.github/workflows/`:

- **`helm-charts-release.yaml`** — Manual release trigger. Builds Docker images in two stages (stage1: multi-arch amd64+arm64; stage2: Python image amd64 only), then packages and publishes the Helm chart.
- **`super-linter.yaml`** — Runs Checkov (IaC), ESLint, flake8, markdownlint, yamllint, and actionlint.
- **`pr-conventional-commits.yaml`** — Enforces Conventional Commits on all PRs.

Linter configs live in `.github/linters/`.

## Architecture

### Helm chart composition

The main chart `chart/helm/spark-on-k8s/` depends on four sub-charts (assembled by `create_chart.sh`):

| Sub-chart | Source | Condition |
|---|---|---|
| `spark-operator` | Downloaded from kubeflow/spark-operator v2.1.0 | always |
| `spark-history-server` | `spark-history-server/chart/helm/` | `spark-history-server.enabled` |
| `spark-thrift-server` | `spark-thrift-server/chart/helm/` | `spark-thrift-server.enabled` |
| `spark-integration-tests` | `spark-service-integration-tests/chart/helm/` | `spark-integration-tests.enabled` |

### Spark image layering

`spark-customized/Dockerfile` is a two-stage build:
1. **Unpacker stage** (Alpine) — downloads AWS SDK, Hadoop AWS, Netty, and Jackson JARs from Maven Central
2. **Main stage** (`apache/spark:4.2.0`) — removes bundled Netty 4.2.13 and Jackson 2.21.2 JARs, copies in newer Netty 4.2.16 and Jackson 2.21.4 JARs and S3 JARs, upgrades curl, adds `gosu`, copies `entrypoint.sh`

The custom `entrypoint.sh` handles:
- JCEKS credential file creation for S3 authentication at runtime
- Fake `/etc/passwd` entry injection for arbitrary UIDs (OpenShift compatibility)

### S3 credential flow

S3 credentials can be provided via:
- Kubernetes Secrets mounted as environment variables
- JCEKS keystore files (created at container startup by `entrypoint.sh`)
- AWS V4 Signature via Hadoop configuration properties

### Spark History Server authentication

OAuth2 Proxy runs as a sidecar container in the History Server pod. NGINX ingress is configured with `auth-url`/`auth-signin` annotations pointing to the proxy. Keycloak is the supported identity provider.

### Deployment modes

- **Non-HA** — single operator replica
- **HA** — multiple operator replicas with leader election
- **DR** — independent operator instances per site (Active-Active)
- **Thrift Server cluster mode** — driver + dynamic executor pods
- **Thrift Server local mode** — driver executes queries in local threads, no executor pods

## Key files

| Path | Purpose |
|---|---|
| `chart/helm/spark-on-k8s/values.yaml` | Default Helm values (security contexts, resource limits, OAuth2 config) |
| `chart/helm/spark-on-k8s/values.schema.json` | JSON Schema for values validation |
| `spark-customized/entrypoint.sh` | Container startup: JCEKS creation, fake passwd |
| `spark-customized/thrift-server-entrypoint.sh` | Thrift Server specific startup |
| `spark-operator-image/operator-entrypoint.sh` | Operator initialization |
| `docs/public/installation.md` | Full installation reference |
| `docs/public/architecture.md` | Architecture diagrams |
| `docs/public/security.md` | TLS/certificate configuration |
| `.github/docker-build-config.json` | Defines which Dockerfiles to build per release stage |
