---
name: troubleshoot-spark-on-k8s
description: Diagnose and resolve failures in a Qubership Spark on Kubernetes deployment — java.nio.file.AccessDeniedException in driver/executor pod logs, Spark application pods not getting patched by the admission webhook, CRD validation errors when applying the SparkApplication/ScheduledSparkApplication CRDs, MD5 checksum errors connecting to MinIO S3, Spark Operator pod restarts from leader election issues, Spark Operator controller restarts (OOM / failed probes / no visible error), Spark applications submitted but no driver/executor pods appear with a Volcano integration, or certificate errors when installing/upgrading the Spark Operator. Falls back to a general checklist, framed for the user to check, when nothing matches.
---

## Reading the reference file

`references/troubleshooting-guide.md` is a byte-for-byte mirror of
[docs/public/troubleshooting-guide.md](/docs/public/troubleshooting-guide.md), kept in sync by the
`sync-troubleshooting-skill` CI workflow on every push to `main`. Don't hand-edit the reference file — edit the
public doc instead and let the workflow (or a manual `apm update`) propagate the change.

The file has three top-level `# ` sections: `Explore Logs`, `Spark User Interface`, and `Known Issues`. Only
`Known Issues` documents specific failures; the first two are general debugging background (where logs live, how to
enable the Spark UI) — worth mentioning if the user hasn't seen them, but not something to search for a matching
symptom in.

`Known Issues` has no per-issue headers — each issue is a top-level bullet (`^\* `) followed by an indented
`*Cause*`/`*Root cause*`/`*Solution*` block. Don't confuse the italic `*Cause*`/`*Solution*` markers (no space after
the leading `*`) with issue bullets (`* ` — asterisk plus space).

1. Grep issue bullets with line numbers: `grep -n "^\* " references/troubleshooting-guide.md` (restrict to the
   `Known Issues` section if you need to exclude the `Explore Logs` bullets).
2. Match the symptom against the jump table below to pick the right bullet.
3. Read only that bullet: offset at its line number, limit through the next `^\* ` line's line number (or EOF for the
   last issue). Never load the whole file for one lookup.

## Symptom → issue in references/troubleshooting-guide.md

| Symptom | Issue |
|---|---|
| `java.nio.file.AccessDeniedException` in driver's or executor's pod logs | Getting `java.nio.file.AccessDeniedException` in driver's or executor's pod logs |
| Spark application pods aren't mutated by the webhook; `webhook.go:247] Serving admission request` is missing from the operator log | Spark application pods are not getting patched by admission webhook |
| Applying the `sparkapplications.sparkoperator.k8s.io` / `scheduledsparkapplications` CRD fails with `metadata.annotations: Too long` or a `spec.preserveUnknownFields` error | CRD Validation Error When Applying SparkApplication CRD |
| MD5 checksum error connecting to MinIO S3 | MD 5 error when connecting to minio s3 |
| Spark Operator pod restarts; log shows `"error": "leader election lost"` | Spark operator pod restarts with leader election issues |
| Spark Operator controller restarts with no visible error, an OOM kill, or failed liveness/readiness probes | Spark operator controller restarts with no visible errors or with OOM error or with probe issues |
| Spark applications submit successfully but driver/executor pods never appear, and the operator logs show no errors/restarts (Volcano-scheduled clusters) | Spark applications are being submitted, but application pods are not appearing and there are no errors/restarts in spark-operator pods |
| Certificate errors during `helm upgrade` of the Spark Operator | Certificate errors when installing spark-operator in update mode |

Start every diagnosis by getting the exact error text or log line and which component it came from (Spark Operator
controller/webhook, driver pod, or executor pod) — several rows above match on a specific log string, not a general
description.

If the symptom plausibly matches more than one row, ask which one applies rather than guessing.

If the symptom doesn't match any row, fall back to a general checklist: check Spark Operator controller/webhook pod
logs and resource usage, check the SparkApplication CR's status/events (`kubectl describe sparkapplication ...`),
and check driver/executor pod events and logs — before concluding the issue is undocumented.
