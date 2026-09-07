---
name: troubleshoot-spark-on-k8s
description: Diagnose and resolve failures in a Qubership Spark on Kubernetes deployment — java.nio.file.AccessDeniedException in driver/executor pod logs, Spark application pods not getting patched by the admission webhook, CRD validation errors when applying the SparkApplication/ScheduledSparkApplication CRDs, MD5 checksum errors connecting to MinIO S3, Spark Operator pod restarts from leader election issues, Spark Operator controller restarts (OOM / failed probes / no visible error), Spark applications submitted but no driver/executor pods appear with a Volcano integration, certificate errors when installing/upgrading the Spark Operator, Spark History Server reachable on its Kubernetes Service but not through its oauth2-proxy ingress/HTTPRoute, or an `XAmzContentSHA256Mismatch`/hash error connecting to S3 from Spark History Server or applications. Falls back to a general checklist, framed for the user to check, when nothing matches.
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
| Spark Operator pod restarts; log shows `"error": "leader election lost"` | Spark operator pod restarts due to leader election issues |
| Spark Operator controller restarts with no visible error, an OOM kill, or failed liveness/readiness probes | Spark operator controller restarts with no visible errors, with OOM errors, or with probe issues |
| Spark applications submit successfully but driver/executor pods never appear at all, and `spark-operator` pods don't restart (Volcano-scheduled clusters) — see Guardrails below if the driver pod *does* appear but stays `Pending` | Spark applications are being submitted, but application pods do not appear and there are no errors or restarts in Spark Operator pods |
| Certificate errors during `helm upgrade` of the Spark Operator | Certificate errors when installing spark-operator in update mode |
| Spark History Server's Kubernetes Service responds fine in-cluster, but its oauth2-proxy ingress/HTTPRoute doesn't work | Spark History Server correctly serves requests inside Kubernetes on its service, but the oauth2‑proxy ingress or HTTPRoute does not work |
| `XAmzContentSHA256Mismatch` / "provided 'x-amz-content-sha256' header does not match" connecting to S3 from Spark History Server or a Spark application | Hash errors in logs when connecting to s3 in spark-history-server or in applications |

Start every diagnosis by getting the exact error text or log line and which component it came from (Spark Operator
controller/webhook, driver pod, executor pod, or Spark History Server/its oauth2-proxy sidecar) — several rows above
match on a specific log string, not a general description.

If the symptom plausibly matches more than one row, ask which one applies rather than guessing — the two MinIO rows
in particular share the same root cause family (an old MinIO version enforcing stricter checksum validation than the
AWS SDK client expects) but are distinguished by the exact checksum algorithm named in the error (`MD5` vs.
`XAmzContentSHA256Mismatch`/`x-amz-content-sha256`) and by which component hit it (Spark Operator's own S3 access vs.
Spark History Server or a Spark application's S3 access) — get the exact error text before picking one.

If the symptom doesn't match any row, fall back to a general checklist: check Spark Operator controller/webhook pod
logs and resource usage, check the SparkApplication CR's status/events (`kubectl describe sparkapplication ...`),
and check driver/executor pod events and logs — before concluding the issue is undocumented.

## Guardrails

Facts below are grounded in the actual Spark Operator source
([kubeflow/spark-operator](https://github.com/kubeflow/spark-operator), tag `v2.5.1` — the version
`docker-transfer/Dockerfile` vendors for both the chart and the controller/webhook image) and this chart's
`chart/helm/spark-on-k8s/values.yaml`, not assumptions:

- Don't recommend "just patch the `SparkApplication` spec to fix a running job." The controller's update predicate
  treats any spec change other than `spec.suspend`/`spec.timeToLiveSeconds` as a full invalidation: it force-writes
  `Status.AppState.State = Invalidating`, deletes the driver pod, driver PDB, and web-UI Service/Ingress, then does a
  **brand-new `spark-submit`** with a new `SubmissionID` — not a live patch. A `PartialRestart` feature gate exists
  at v2.5.1 that carves out `spec.executor.priorityClassName`/`nodeSelector`/`tolerations`/`affinity`/`schedulerName`
  edits from forcing invalidation (those fields only apply to newly-created pods via the mutating webhook anyway),
  but it's Alpha and defaults to **off** — don't assume it's active unless the user confirms the feature gate was
  explicitly enabled. Driver field changes always force full invalidation regardless of this gate.
- Don't recommend "delete the driver pod to force a rerun" as a generic fix. It only triggers an automatic resubmit
  if `spec.restartPolicy.type` allows retries (`OnFailure`/`Always`) with attempts remaining. With the default
  `Never`, deleting the driver pod just permanently fails the application (`Failing` → `Failed`, no resubmission).
- `SparkApplication` has no finalizer — `kubectl delete sparkapplication` removes the CR from etcd immediately.
  Cleanup of the driver pod/PDB/UI Service/Ingress is best-effort plus owner-reference garbage collection, not a
  guaranteed-synchronous teardown. Don't assume the driver pod is already gone the instant the CR delete returns.
- Webhook leader-election timing (`leaseDuration`/`renewDeadline`/`retryPeriod`) is only configurable for
  `spark-operator.controller.leaderElection` — `spark-operator.webhook.leaderElection` only exposes `enable` in the
  Helm schema. Don't suggest tuning webhook leader-election timing via a Helm value; that knob doesn't exist.
- Don't suggest disabling `controller.leaderElection.enable` (or `webhook.leaderElection.enable`) unless the
  matching `controller.replicas`/`webhook.replicas` is also `1`. With more than one replica and leader election off,
  multiple controllers reconcile the same `SparkApplication`s concurrently — duplicate `spark-submit` calls and
  driver-pod naming races.
- `signal: killed` in a `SparkApplication`'s own error message (as opposed to an operator pod `OOMKilled` event) is
  the fingerprint of the controller's `spark-submit` subprocess — a JVM, default `-Xmx128m` — being OOM-killed; up
  to `controller.workers` (default 10) can run concurrently. Point at `spark-operator.controller.resources`
  (`requests: 100m/300Mi`, `limits: 200m/600Mi` in this chart's defaults) and/or `controller.workers` /
  `workqueueRateLimiter`, not generic node capacity.
- An admission-webhook outage is narrower than "blocks all pod/CR creation cluster-wide." With the default
  `failurePolicy: Fail`, every mutating/validating webhook rule (pods, `SparkApplication`, `ScheduledSparkApplication`,
  `SparkConnect`) carries a `namespaceSelector` gated on `spark-operator.spark.jobNamespaces` (`spark-apps` in this
  chart's defaults) — an outage only blocks pod/CR creation in those namespaces, not cluster-wide. The pod webhook
  additionally has an `objectSelector` matching `sparkoperator.k8s.io/launched-by-spark-operator: "true"`, so within
  those namespaces it only touches spark-operator-launched pods, not unrelated ones; the CR webhooks have no such
  `objectSelector` narrowing, since a `SparkApplication`/`ScheduledSparkApplication`/`SparkConnect` create/update in
  a job namespace is unambiguously spark-operator's concern already.
- For "driver/executor pods never appear" with Volcano, check `kubectl describe sparkapplication <name>` and
  `kubectl get events` first, not just operator pod logs. A Volcano failure (missing PodGroup CRD, RBAC denial)
  surfaces as `FailedSubmission` with a populated `ErrorMessage` *before* `spark-submit` is ever invoked — it isn't
  silent. If the driver pod does get created but stays `Pending`, that's a different failure (Volcano queue/
  scheduler capacity or a wrong `spec.batchSchedulerOptions.queue`), not the same root cause — ask which one applies.
- Webhook TLS certs aren't regenerated on every restart or `helm upgrade`: the webhook reuses a stored cert as long
  as it's still valid, and a pair of always-running reconcilers keep the CA bundle patched into the webhook configs.
  Don't default to "certificate errors on upgrade mean a clean install is required" — at the v2.5.1 this chart
  vendors, that machinery already exists. If certificate errors do show up on an upgrade, check these two causes
  first, in this order (both are more common in practice than a `certManagerIntegration.enabled` toggle, which is
  almost always left disabled once set):
  - **Webhook Service/Secret name changed, even if the release name looks the same.** The webhook Service and
    Secret are named `<fullname>-webhook-svc` / `<fullname>-webhook-certs`, and `spark-operator.fullname` resolves
    `$name := default .Chart.Name .Values.nameOverride`, then uses `.Release.Name` directly if
    `contains $name .Release.Name`, else `<release>-<name>`. `.Chart.Name` for the spark-operator templates is
    always `spark-operator` — Helm resolves `.Chart.Name` from the currently-rendering chart's own `Chart.yaml`
    whether it's root or a subchart, so nesting depth alone doesn't change it. What actually flips the `contains`
    check, and therefore the computed name, is the **release-name convention** in use:
    1. Redeploying through ArgoCD with an Application/release name that differs from the original Helm release name
       (a common setup: Helm install directly, then adopted into ArgoCD under a different app name).
    2. This chart being installed as an upgrade on top of an environment where spark-operator was previously
       installed as its own root chart rather than as a subchart — this includes the plain upstream
       `kubeflow/spark-operator` chart installed directly (its own docs default to
       `helm install spark-operator spark-operator/spark-operator`, i.e. release name `spark-operator` itself). With
       release name `spark-operator`, `contains("spark-operator", "spark-operator")` is true, so `fullname` collapses
       to just `spark-operator`. Once the same environment is redeployed through `qubership-spark-on-k8s` (release
       name following *this* chart's convention instead, e.g. `spark-on-k8s`), that `contains` check goes false and
       `fullname` becomes `<release>-spark-operator` — a different webhook Service/Secret name, even though
       spark-operator's own chart identity and version didn't change.
    Meanwhile the `MutatingWebhookConfiguration`/`ValidatingWebhookConfiguration` objects themselves are fixed,
    cluster-scoped singletons (e.g. `webhook.sparkoperator.k8s.io`) whose `clientConfig.service.name` just gets
    re-pointed to whichever Service name was last rendered — so after either change, the cert's commonName and the
    webhook config's service reference can end up disagreeing during/after the transition. Check the actual
    rendered Service/Secret name (`helm template ... | grep webhook-svc`) against what the webhook config and cert
    commonName currently reference before assuming a code bug.
  - **Stale secret from a much older release.** The internal self-signed path stores keys under
    `CAKeyPem`/`CACertPem`/`ServerCertPem`/`ServerKeyPem`; the cert-manager path uses `ca.crt`/`tls.crt`/`tls.key`
    instead — different schemas entirely. Upgrading on top of a webhook secret created by a very old spark-operator
    release (predating the current internal cert-controller, or from a stale `certManagerIntegration` toggle) can
    leave a secret whose keys don't match what the current binary expects. The fix is to delete the stale
    `<fullname>-webhook-certs` secret so it regenerates cleanly on next reconcile — not necessarily a full clean
    reinstall of the release.
