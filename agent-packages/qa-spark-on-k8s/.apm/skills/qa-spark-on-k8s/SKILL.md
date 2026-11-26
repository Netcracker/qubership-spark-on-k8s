---
name: qa-spark-on-k8s
description: Plan and verify testing of a Qubership Spark on Kubernetes change — run the Robot test-app suite with the right tags, enable the Hive and Volcano integration paths correctly, set the UID 185 and webhook preconditions that silently break Spark apps, and validate sample apps, history server and thrift server behaviour. Triggers when the user asks how to test a Spark operator, chart or image change, which tags to run, or why a SparkApplication never starts. Do NOT run automatically.
---

## What this deployment is

`chart/helm/spark-on-k8s` deploys the Kubeflow **spark-operator** (declared `2.6.0`) plus
optional history server, thrift server and test runner. Spark images are built from
`apache/spark:4.3.0-scala2.13-java21-ubuntu` (`spark-customized`) and `spark-customized-py`.

**Chart assembly matters.** `./create_chart.sh` builds `./target/chart/spark-on-k8s/` and
downloads the upstream operator chart tarball — pinned at `v2.6.0` in the script and declared
as `2.6.0` in `Chart.yaml`. After assembly, verify the rendered dependency version rather than
trusting either number.

---

## Test suites that exist

| Suite | Path | Covers |
| --- | --- | --- |
| Test apps | `spark-service-integration-tests/robot/tests/test-app/testapp.robot` | SparkApplication lifecycle, Hive, Volcano |
| Alerts | `spark-service-integration-tests/robot/tests/alerts/alerts.robot` | Prometheus rules |
| Image integrity | `spark-service-integration-tests/robot/tests/image_tests/image_tests.robot` | `dd_images` ConfigMap |

**No CI job runs any of these.** CI only lints and builds the five sample-app images
(`test-images.yml`) — it never executes them.

### Test app mechanics you must know

- CR: group `sparkoperator.k8s.io`, version `v1beta2`, plural `sparkapplications`.
- Polling is **160 retries × 5 s ≈ 13 min 20 s** per status transition. A slow cluster looks
  like a hang, not a failure.
- Status assertion is a substring check for `RUNNING` then `COMPLETED`.
- The `hive-connection` test sleeps **100 seconds** before creating the CR — a known flakiness
  source.

### Tags

```
test_app  java  py  long-pi  hive-connection  hive-seaweedfs
history-server  volcano  dual_test
spark_container_hardening  spark_container_hardening_test
spark_images  alerts
```

### Required values, not defaults

`spark-integration-tests/templates/deployment.yaml` renders `.Values.tags` and
`.Values.sparkAppsServiceAccount`, but **`values.yaml` does not define either** — with defaults
they render as `<no value>`. Documented defaults (`installation.md`) are `test_app` and
`sparkapps-sa`; set both explicitly or the runner tests nothing.

Also: `PROMETHEUS_URL` is injected **only when `status_writing_enabled: true`**. Turning it off
silently disables the alert suite.

---

## Preconditions that silently break Spark apps

These produce no obvious test failure — they produce apps that never start.

1. **UID 185.** Parent images run as UID 185. A `SparkApplication` that does not set
   `driver.securityContext.runAsUser: 185` and `executor.securityContext.runAsUser: 185` gets
   `java.nio.file.AccessDeniedException` copying the app jar. This only works because the
   mutating webhook patches pods.
2. **Webhook must be patching.** If `webhook.go: ... Serving admission request` is absent from
   operator logs, the webhook is under-resourced (needs > 1 CPU / 1 GB) and patches are not
   applied — the UID fix above then silently does nothing. Always check this first when a
   Spark app fails in a new way.
3. **App image must set `USER`.** An app image running as root cannot write its artifacts.
4. **Volcano** requires a working Volcano install, correct queue, pod groups and node pool. The
   symptom of misconfiguration is apps submitted with **no pods and no operator errors**.
5. **CRD apply** must use `--server-side=true`, otherwise annotations exceed 262144 bytes or
   `preserveUnknownFields` is rejected.

---

## Variants worth exercising

| Variant | Enable via | Notes |
| --- | --- | --- |
| Hive connection | `sparkHiveIntegrationTests.enabled` | needs `s3-secrets`; teardown deletes it |
| Hive on SeaweedFS | `sparkHiveSeaweedfsIntegrationTests.enabled` | teardown deletes `seaweedfs-secrets` |
| Volcano | `volcanoIntegrationTests.enabled` | asserts Pending/queued via `Check Volcano Pending Status` |
| History server | `spark-history-server.enabled` | S3 event logs; oauth2-proxy path fails on TLS mismatch |
| Thrift server | `spark-thrift-server.enabled` | `sparkMasterUri: local` by default → **local mode, no executor pods** |
| Hardened containers | `spark_container_hardening` | read-only FS, dropped caps, seccomp |
| arm64 | — | `spark-customized-py` is **amd64-only**; arm64 breaks the Python image and `hive-connection-test` |

---

## Image and sample-app traps

- `spark-sample-apps/spark-pi-long-run/cr/spark-pi-long-run.yaml` pins
  `ghcr.io/netcracker/qubership-spark-sample-apps-spark-pi-long-run:main`, which the
  `test-images.yml` matrix **does not build** (it builds `qubership-tests-spark-pi-long-run`).
  Deploying that manifest as-is pulls a non-existent image.
- Sample apps build with `maven:3-eclipse-temurin-17-alpine` while the app code targets Java
  1.8 — only relevant when changing a `pom.xml`.
- Old MinIO breaks S3 writes: `XAmzContentSHA256Mismatch`, plus MD5 errors from AWS SDK v2. Set
  `RequestChecksumCalculation` / `ResponseChecksumValidation` to `WHEN_REQUIRED`.

---

## Alerts

Rules render only when **both** `metrics.enable` and `prometheusRules.alert.enable` are true
(default `false`). Thresholds `cpuThreshold` / `memoryThreshold` default to 90.

`SparkOperatorControllerCPUusage`, `SparkOperatorControllerMemoryUsage`,
`SparkOperatorWebhookCPUusage`, `SparkOperatorWebhookMemoryUsage` (`warning`);
`SparkOperatorControllerIsDegraded`, `SparkOperatorWebhookIsDegraded` (`high`);
`SparkOperatorControllerIsDown`, `SparkOperatorWebhookIsDown` (`critical`).

---

## Not test failures

- Operator restarts with `leader election lost` → slow K8s API, not a product defect.
- Controller restarts with no error/OOM/probe failure → it spawns one `spark-submit` per app;
  real cause is submission-rate resource exhaustion.
- Helm **upgrade** of the operator from older releases fails on certificates — needs a clean
  install or deletion of the `*-webhook-certs` secret. Check whether the reported defect is an
  unsupported upgrade path rather than a regression.

---

## Reviewing a change

1. Classify: operator image, custom Spark image, chart values, subchart, or sample app.
2. Run `helm template` on the assembled chart and check the operator dependency version.
3. Name the tags to run and confirm `tags` and `sparkAppsServiceAccount` are set.
4. Confirm UID 185 is set on any new or changed `SparkApplication`.
5. If the change touches a subchart, state whether it was tested enabled or only disabled
   (all four subcharts default to `enabled: false`).
