**This guide should be read after [spark-operator overview](https://www.kubeflow.org/docs/components/spark-operator/overview/), [architecture.md](/docs/public/architecture.md) and [installation.md](/docs/public/installation.md)**

## Repository structure

* `.github/workflows` - folder related to spark-on-k8s images pipeline config.
* `chart` - helm charts. It includes charts for monitoring of [spark-operator](https://github.com/kubeflow/spark-operator), spark applications and chart for [status-provisioner](https://github.com/Netcracker/qubership-deployment-status-provisioner).
* `docs` - Documentation and some examples.
* `docker-transfer` - Docker image with comlete spark-on-k8s chart. The chart in the image includes [spark-operator-chart](https://github.com/kubeflow/spark-operator/tree/master/charts/spark-operator-chart) as a subchart.
* `spark-customized` - contains files for spark image building and spark-py image building.
* `spark-history-server` - contains chart for spark history server.
* `spark-operator-image` - contains files for spark operator image building. It is based on [spark-operator](https://github.com/kubeflow/spark-operator) image with some minor tweaks.
* `spark-sample-apps` - contains files for building, deploying and running spark operator sample applications.
* `spark-service-integration-tests` contains integration tests.
* `spark-thrift-server` - contains chart for spark thrift server.

## How to start

Main components of spark-on-k8s distribution are:

* [Spark-operator](https://github.com/kubeflow/spark-operator). Consists of controller and webhook. For more information refer to https://www.kubeflow.org/docs/components/spark-operator/getting-started/.
* `Spark-history-server` - Spark tool that can be used to view logs of spark applications. For more information refer to https://spark.apache.org/docs/4.3.0/monitoring.html .
* `Spark-thrift-server` - Spark tool to execute SQL queries. For more information refer to https://spark.apache.org/docs/4.3.0/sql-distributed-sql-engine.html .

Spark-on-k8s distribution includes the following images:

* [Qubership spark image](/spark-customized/Dockerfile): image based on [official spark-java 21 image](https://github.com/apache/spark-docker/tree/master/4.3.0/scala2.13-java21-ubuntu) with patch version updates of some jars to reduce vulnerabilities. Includes some additional jars, for example, to work with S3 and [profiler Jars](https://github.com/Netcracker/qubership-profiler-agent). Additionally contains modified entrypoint to support working with certificates and with [qubership profilier](https://github.com/Netcracker/qubership-profiler-agent). Also includes custom entrypoint for spark-thrift service. The image is used in spark-history-server, spark-thrift-server and can be used to create custom spark applications(also can be used to run example spark applications).
* [Qubership spark python image](/spark-customized/py/Dockerfile): image based on spark image that adds python into the image. The image is used custom python spark applications. Can be used to run python example spark applications.
* [Qubership spark operator image](/spark-operator-image/Dockerfile): image based on the [official spark operator image](https://hub.docker.com/r/kubeflow/spark-operator/). Includes custom entrypoint based on spark image to be able to run the image under any user. Note, that official spark operator image is based on [official spark-java 21 image](https://github.com/apache/spark-docker/tree/master/4.3.0/scala2.13-java21-ubuntu) .
* [integration tests image](/spark-service-integration-tests/docker/Dockerfile): image used to run qubership spark-on-k8s integration tests. It is based on qubership [integration tests image](https://github.com/Netcracker/qubership-docker-integration-tests)
* [Oauth2 proxy image](https://github.com/oauth2-proxy/oauth2-proxy/blob/master/Dockerfile): image used to set up a proxy with authentication for spark history sever.
* [Status provisioner image](https://github.com/Netcracker/qubership-deployment-status-provisioner): Qubership status provisioner image that is used to report deploy status for application deployer.



### Build

Build pipeline is configured in [/.github/workflows](/.github/workflows). It is used to build images for qubership-spark-on-k8s.


### Deploy to k8s

See [installation.md](/docs/public/installation.md)

### How to debug and troubleshoot

#### Spark operator deploy problems
The resulting chart should be extracted from docker-transfer image. When facing problems with spark-on-k8s deploy, firstly it is necessary to check installation parameters. If there are problems with pod starting, it is necessary to check events in the namespace. Often the problems are caused by security context or incorrectly mounted volumes.

#### Problems with submitting and running spark applications

If the application can't be submitted at all, it is necessary to check application CR. If application can be submitted the following things can be checked:

* Application CR status.
* Spark operator logs.
* Namespace events.
* Application pod logs .
* Volcano pod logs if volcano integration is enabled.

**Note** It is also might be useful to check pod resources, especially spark-operator controller pod. While written in Go, spark-operator controller pod runs java process for every submitted spark application.

If it doesn't help, it is also might be useful to check application spark image dockerfile and application code.

#### Issues with spark operator pods

Check latest community commits if there were any potential problematic changes. Check if Qubership changes in docker image conflict with new changes with spark operator

#### History server TLS issues 

When unsure if the issue is related to incorrect certificates, it is possible to disable certificate validation. See [installation.md](/docs/public/installation.md) on how to disable certificate validation for postgres and s3.

#### Oauth 2 proxy issues

When troubleshooting issues related to Oauth2proxy/keycloak it is necessary to make sure that all parameters are correct(including various URLs) both on oauth2proxy side and on keycloak side. Also it is necessary to check keycloak and oauth2proxy logs.

#### Problems with image size

Spark images are pretty large and include pretty big JARs. To avoid unnecessary image size increases it is necessary to follow dockerfile best practices, for example: do not change file permissions in separate RUN steps or do not download and unpack archive in different RUN commands. If the issue is with custom application image, it is also necessary to check custom application dockerfile for the same issues or if they upload the same jars that are already present in the image.

## Evergreen strategy

This is the runbook for bringing the distribution up to a new upstream release. Both people and
automated runs follow it step by step, so keep it accurate: every step names the files to change and the
check that proves the change works.

One update is one pull request, with a commit per concern: operator chart, operator image, Spark image,
supporting images and release plumbing, documentation. Cite a step as `<section>.<step>`, for example
`Update Spark.2`, when reporting progress or resuming after an interruption.

Local edits inside files that come from upstream are mostly unmarked, so a re-sync can drop them without a
failure. Mark every new local edit, and carry the markers through a re-sync:

* `# QB change: <description>` in a shell script;
* `## Qubership custom template. <description>` at the top of a template that does not exist upstream;
* `{{- /* Qubership custom change: <description> */ -}}` inside a Helm template that is otherwise upstream.

A marker records what the local edit is and why. It does not record where upstream stopped, so the diff
against the upstream file remains the inventory, and the markers only protect edits made from now on.
Markers apply to files that come from upstream; files this repository owns, such as the history server
chart templates, need none.

The baseline table records the state this runbook was last verified against. Read the current values
from the files before changing anything; the numbers move, the locations do not.

### Baseline version pins

| What | Pinned value | Defined in |
| --- | --- | --- |
| Spark version | `4.3.0` | sample apps, docs, examples, `sparkVersion` in the CRs |
| Spark base image | `apache/spark:4.3.0-scala2.13-java21-ubuntu`, the flavor without the Python interpreter on purpose; the `-py` image adds Python 3.14 | `spark-customized/Dockerfile` (both `FROM` lines) |
| spark-operator controller image | `2.6.0` | `spark-operator-image/Dockerfile` (both `FROM` lines) |
| spark-operator chart | `2.6.0` | `docker-transfer/Dockerfile`, `create_chart.sh`, `chart/helm/spark-on-k8s/Chart.yaml` |
| Bundled JDK, amd64 only | Temurin `21.0.13.1_2-jdk-jammy` | both Dockerfiles |
| Patched JARs | Netty `4.2.18.Final`, Jackson `2.21.8`, tcnative `2.0.84.Final`, zstd-jni `1.5.7-25`, snappy-java `1.1.10.10`, lz4-java `1.11.4`, Vert.x `4.5.36`, xmlschema-core `2.3.3` | both Dockerfiles |
| S3 and extra JARs | AWS SDK bundle `2.59.1`; hadoop-aws `3.5.0` in the Spark image and `3.4.1` in the operator image; analyticsaccelerator-s3 `1.3.1` in the Spark image; seaweedfs client `4.38` | both Dockerfiles |
| Python | `3.14` | `spark-customized/py/Dockerfile` |
| oauth2-proxy | `v7.15.6` | history server `values.yaml` and `values.schema.json`, `release-images.yaml`, sample app chart |
| Integration test base image | `0.5.8` | `spark-service-integration-tests/docker/Dockerfile` |
| Status provisioner | `0.2.11` | `chart/helm/spark-on-k8s/values.yaml` and `values.schema.json` |
| Chart version | `1.0.0` | `chart/helm/spark-on-k8s/Chart.yaml`, `chart-version` in the release workflow |

### Prepare the update

The procedure has two inputs, the target Spark version and the target Spark Operator version. Both are the
newest available release, and the two are expected to name different Spark versions: the operator submits
applications with the client bundled in its controller image, while the applications themselves run the
Spark image built here. Every other number follows from those two, so identify them before editing a file.

1. Pick the Spark candidate: the newest GA release on the
   [apache/spark releases](https://github.com/apache/spark/releases) page that has an `apache/spark` image
   for the Scala 2.13, Java 21, Ubuntu flavor `spark-customized/Dockerfile` uses, for example
   `4.3.0-scala2.13-java21-ubuntu`. The operator image builds on the controller image and inherits that
   image's Spark, so this choice does not apply to it. Name the flavor: the short `apache/spark:<version>`
   alias resolves to the Python flavor, so a bare version silently changes the base image. Confirm both
   architectures with
   `docker manifest inspect apache/spark:<version>-scala2.13-java21-ubuntu`.
2. Pick the operator candidate: the newest release on the
   [kubeflow/spark-operator releases](https://github.com/kubeflow/spark-operator/releases) page. Do not filter
   it by the Spark version it bundles or tests against, and do not go looking for a supported-version range:
   upstream publishes none for current releases. The README version matrix stops at `2.3.x`, the release
   notes only name the Spark the runtime was upgraded to, and the code enforces no upper bound at all, only
   Spark `< 3.0.0` for pod templates. Operator `2.6.0` is built on Spark `4.2.1` while this distribution
   ships `4.3.0`, and that is the normal state, not a defect. Read the bundled version from `/opt/spark/jars`
   in `ghcr.io/kubeflow/spark-operator/controller:<version>`, where the `spark-core_2.13-<version>.jar` names
   it, so the mismatch can be stated in the pull request. The controller image and the chart tarball come from
   the same tag.
3. Keep the two Spark versions apart. The operator image inherits the Spark of its controller image and stays
   that way; the driver and executor images run the Spark chosen in step 1. Replacing the bundled Spark in the
   operator image would force a match that nothing requires, so it is a separate change with its own testing,
   not part of this procedure. What qualifies the pair is the verification section: the newest operator either
   runs the newest Spark applications here or it does not, and the run records which.
4. Check the operator chart surface this distribution depends on: the values under `controller.*`,
   `webhook.*`, `spark.*`, `prometheus.*` and `certManager.*` in
   `chart/helm/spark-on-k8s/values.yaml`, and the controller and webhook deployment layout that
   `docker-transfer/update_charts.py` patches. Check the CRD as well: when the release serves a different
   `SparkApplication` version, the sample CRs and
   `spark-service-integration-tests/robot/tests/test-app/testapp.robot`, which hardcodes `v1beta2`, move
   with it.
5. Check the Spark settings for renames. `chart/helm/spark-on-k8s/values.yaml`, `spark-history-server/`,
   `spark-thrift-server/` and the sample applications pass `spark.eventLog.*`, `spark.history.*`,
   `spark.kubernetes.*` and S3A keys; compare them with the migration notes of the target release.
6. Create one branch and one pull request, and record the target Spark version, the operator version, the
   Spark that operator bundles and the checks that qualified them in the description. Nothing in the
   repository records which upstream release a local chart render used.

**Blocker rule for unattended runs.** Stop, leave the work on the branch without a pull request, and report
the check that failed together with the versions considered, when any of these is true:

* the Spark candidate has no multi-arch `apache/spark` image tag;
* the operator candidate is newer than the pin but its controller image or chart tarball is missing or not
  published yet;
* the newest operator does not run the Spark candidate: an application fails to submit or finishes with
  errors because of the version difference, and no setting in this distribution closes the gap;
* the operator chart no longer exposes the values or the deployment layout this distribution depends on,
  and closing the gap needs a design decision rather than a port;
* an upstream value that this distribution documents or overrides was removed with no replacement;
* a build fails in a way that needs a decision about a new JAR family rather than a version bump.

Do not work around a blocker to make a check pass: do not replace the Spark bundled in the operator image to
force a match, do not relax `docker-transfer/update_charts.py`, do not pin an unreleased tag, and do not
delete a guardrail. In an interactive run, ask instead of stopping.

### Update spark-operator

1. Bump the controller image and the chart tarball together, from the release chosen in
   `Prepare the update.2`. They come from the same tag, so they share one version number.
2. In `spark-operator-image/Dockerfile`, change both `FROM ghcr.io/kubeflow/spark-operator/controller:<version>`
   lines: the `jdk-arm64` stage at the top and the main build stage. Changing only the main stage leaves
   arm64 builds with the old JDK. Review that image's own `rm` list and patched-JAR set the same way as
   described under Update Spark.
3. Update the chart tarball in `docker-transfer/Dockerfile` and in `create_chart.sh`, then bump
   `dependencies.spark-operator.version` in `chart/helm/spark-on-k8s/Chart.yaml`. All three must agree;
   they have drifted before (`create_chart.sh` was on `v2.1.0` while the release used `2.6.0`), so check
   each one rather than trusting one of them.
4. Build the transfer image: `docker build -f docker-transfer/Dockerfile -t spark-on-k8s-transfer:test .`.
   The build runs the schema sync, the values validation and the template patcher, which makes it the
   fastest compatibility check:

   * `docker-transfer/update_charts.py` fails when an upstream controller or webhook deployment has no
     `securityContext` block, more than one `containers:` block, or an `initContainers:` block. Port the
     patch to the new templates instead of relaxing the check.
   * `docker-transfer/validation.py` fails when a default in the new chart's `values.yaml` differs from
     the same key in `docker-transfer/values.schema.json`, which replaces the subchart schema in the
     image. It compares only keys the schema already declares, so refresh the keys as well: the upstream
     chart ships no schema, and at 2.6.0 this file lacked `publicConfigMap`, `submitter`,
     `hook.resources`/`labels`/`annotations` and the controller and webhook pacing knobs (`kubeAPIQPS`,
     `kubeAPIBurst`, `hostUsers`, `deploymentAnnotations`).
     Keep the v2.6.0 note that `jobNamespaceSelector` is an object, not a string.
     `docker-transfer/commondefs.json` changes only when the shared Kubernetes definitions do.
5. Re-sync the parts that mirror the upstream chart:

   * the restricted deploy user RBAC in `docs/public/installation.md`, including the `helm.sh/chart` and
     `app.kubernetes.io/version` labels;
   * the other rendered resource examples in the same file;
   * `AGENTS.md`, for the operator version and image description;
   * `SECURITY.md`, whose security-release example names the current operator version.
6. When the upstream chart adds, removes or renames values, update `chart/helm/spark-on-k8s/values.yaml`,
   the matching `chart/helm/spark-on-k8s/values.schema.json` and the parameter tables in
   `docs/public/installation.md`.

### Update Spark

1. Change both `FROM apache/spark:` lines in `spark-customized/Dockerfile`, the `jdk-arm64` stage and the
   main stage, to the flavor tag chosen in `Prepare the update.1`.
2. Re-sync `spark-customized/entrypoint.sh`. It is a fork of the `spark-docker` entrypoint for the same
   version, so diff it against
   `https://github.com/apache/spark-docker/blob/master/<version>/scala2.13-java21-ubuntu/entrypoint.sh`,
   port every hunk, then update the version in the header comment. The 4.3.0 update bumped the comment
   but missed the new `SPARK_EXECUTOR_LIBRARY_PATH` handling in the `executor` branch, so the diff is the
   only reliable check.
3. List the JARs in the new base image (`docker run --rm apache/spark:<version> ls /opt/spark/jars`) and
   compare them with the `rm` block and the downloads in the unpacker stage. For each overridden JAR:
   drop the override when upstream ships the same or a newer version, otherwise repoint the download at
   the newest patched version. The `rm` list and the downloads must stay consistent, or the build fails on
   a missing file or the image ends up with two versions on the classpath. Expect new families between
   Spark releases: 4.3.0 made netty-tcnative, Vert.x and xmlschema-core necessary.
4. Review the extra JARs against the new Spark version: AWS SDK bundle, hadoop-aws, analyticsaccelerator-s3
   (Spark image only), seaweedfs-hadoop3-client. `hadoop-aws` is pinned per image on purpose (`3.5.0` in
   Spark, `3.4.1` in the operator). Delta JARs are not shipped; that is a known thrift-server limitation,
   not an oversight.
5. Review the Python base in `spark-customized/py/Dockerfile`. It installs jammy debs from the deadsnakes
   PPA, so a change of the base OS or of the Python version breaks the URLs. The image is built for amd64
   only, as configured in `.github/docker-build-config.json`. The main image has no Python interpreter, and
   `dpkg -R --install` does not fetch missing dependencies, so a library the debs need but the base lacks
   fails the build with an unmet-dependency error. Add the package to the `apt-get install` line in that
   Dockerfile; do not switch the main image to the Python flavor to make the build pass.
6. Re-check the JDK override. Both images replace the bundled JDK with Temurin on amd64 and copy
   `/opt/java/openjdk` over the base image. Delete the `jdk-amd64`, `jdk-arm64` and `jdk` stages and the
   `COPY --from=jdk` line once the base images ship Temurin 21.0.13.1 or later. While the override stays,
   bump its tag for CVE fixes in both Dockerfiles and keep the `jdk-arm64` stage on the same base image as
   the main stage. arm64 keeps the JDK from the base image, so the two architectures differ on purpose.
   Record the new version in the `Bundled JDK` row of the baseline table and in `AGENTS.md`, which names
   Temurin in the operator bullet and in the Spark image layering section.
7. Run a CVE pass on the built image. Close patch-level findings with another override JAR in both
   Dockerfiles; the patched JAR set in the baseline table is the current example. When the set changes,
   update both JAR rows of the baseline table and `AGENTS.md`, which lists the JAR families in both image
   bullets and the removed and patched versions in the Spark image layering section.
   `git grep -n "<old jar version>"` finds every copy.
8. Sweep the Spark version through the fixtures and docs. The test image copies the example CRs, so a stale
   `sparkVersion` there means the tests exercise the old Spark:

   * `docs/public/examples/app-crs/*.yaml` and `docs/public/examples/app-crs/spark-streaming/cr-streaming.yaml`,
     including the `mainApplicationFile` JAR name (`spark-examples_2.13-<version>.jar`);
   * `spark-sample-apps/*/cr/*.yaml`, `spark-sample-apps/spark-pi-long-run-oauth2-proxy/chart/helm/sparkpioauth2proxy/templates/crs/*.yaml`,
     and the `<version>` of the `spark-*_2.13` dependencies in `spark-sample-apps/*/pom.xml`;
   * `docs/public/user-guide.md`, `docs/public/applications-management.md`, `docs/public/troubleshooting-guide.md`,
     `docs/internal/readme.md`, `AGENTS.md`, `spark-sample-apps/hive-connection-test/docs/README.md`.

   `docs/public/installation.md` also carries a stale Spark upgrade section that names 2.4 and 3.x; correct
   it when the version moves.

### Update supporting components

1. oauth2-proxy: pick a release from the [oauth2-proxy releases](https://github.com/oauth2-proxy/oauth2-proxy/releases),
   then update every pin: `oauth2Proxy.image.tag` in `spark-history-server/chart/helm/spark-history-server/values.yaml`
   and the matching default in that chart's `values.schema.json`, `chart/helm/spark-on-k8s/release-images.yaml`,
   and `spark-sample-apps/spark-pi-long-run-oauth2-proxy/chart/helm/sparkpioauth2proxy/values.yaml`. The
   released tag comes from the `oauth2_proxy_release` workflow input, which
   `.github/helm-charts-release-config.yaml` expands.
2. When the upstream [oauth2-proxy chart](https://github.com/oauth2-proxy/manifests/tree/main/helm/oauth2-proxy)
   changes, re-sync `spark-history-server/chart/helm/spark-history-server/templates/oauth2Proxy/`, the
   oauth2-proxy container in `templates/deployment.yaml` and the `oauth2Proxy` block of `values.yaml`.
   Nothing records which release the fork was taken from: `7.12.2` is the closest match, and parts of the
   deployment template already carry code from the `10.x` line. Diff against that base and against the
   release you are syncing from before overwriting anything, and keep the local edits:

   * values nested under `oauth2Proxy.`;
   * the `oauth2Proxy.enabled` guards on the secret and config templates;
   * `secretsAsFiles`, the `or .Values.secretsAsFiles` condition in `secret.yaml`, and the
     `--client-secret-file` and `--cookie-secret-file` arguments;
   * `proxyVarsAsSecrets: false` against an upstream `true`;
   * the `gateway` values and the `ingressEnabled` and `gatewayEnabled` helpers with their `null`
     semantics, which replace upstream `gatewayApi`;
   * the `oauth2-proxy.redis.enabled` check in `configmap-wait-for-redis.yaml`.

   `requiredSecretKeys` and the `client_id` config option are upstream, not local edits. Mark every local
   edit you carry over with the marker rule above, and drop a marker only when upstream ships the same
   change.
3. Integration test base image: bump `ghcr.io/netcracker/qubership-docker-integration-tests` in
   `spark-service-integration-tests/docker/Dockerfile` to the [latest Qubership release](https://github.com/Netcracker/qubership-docker-integration-tests).
4. Status provisioner: bump `statusProvisioner.image` in `chart/helm/spark-on-k8s/values.yaml` and the
   matching default in `chart/helm/spark-on-k8s/values.schema.json`, based on the
   [latest Qubership release](https://github.com/Netcracker/qubership-deployment-status-provisioner/releases).
   The released tag comes from the `sp_release` workflow input. Keep the `statusProvisioner.image` row of
   `docs/public/installation.md` in sync; it has lagged behind `values.yaml` before.

### Release plumbing and agent packages

1. Keep `version` in `chart/helm/spark-on-k8s/Chart.yaml` and `chart-version` in
   `.github/workflows/helm-charts-release.yaml` equal. Both are `1.0.0` and have not moved with the
   upstream versions; bump them only when the chart is deliberately re-versioned. The subchart versions
   (`spark-history-server`, `spark-thrift-server`, `spark-integration-tests`, all `0.1.0`) are separate
   and must match the parent chart's `dependencies` block if you bump them.
2. `chart/helm/spark-on-k8s/release-images.yaml` keeps `:main` tags; the release workflow replaces them
   from the `release`, `sp_release` and `oauth2_proxy_release` inputs. Do not commit release tags there.
   Every `image.repository` used by the charts needs a matching key in that file, or its tag is never
   rewritten at release time. The thrift server image is the known exception: it is the hive-connection
   sample image, has no entry, and stays on `main`.
3. Update the pinned versions in the agent packages: [qa-spark-on-k8s SKILL.md](/agent-packages/qa-spark-on-k8s/.apm/skills/qa-spark-on-k8s/SKILL.md)
   (operator version, `apache/spark` base image, the `create_chart.sh` tarball) and
   [troubleshoot-spark-on-k8s SKILL.md](/agent-packages/troubleshoot-spark-on-k8s/.apm/skills/troubleshoot-spark-on-k8s/SKILL.md)
   (the operator version the guardrails are grounded in, and the webhook log line if it moved). Edit
   `docs/public/troubleshooting-guide.md` rather than the copy under `references/`:
   `sync-troubleshooting-skill.yml` runs on every push to `main`, opens a pull request that rewrites the
   copy, and enables auto-merge.
4. When you add an agent package, register it in `apm.yml`. If the package copies files out of `docs/` the
   way the troubleshooting references do, add the copies to the jscpd ignore list
   (`.github/linters/.jscpd.json`).
5. Know where each image is registered before adding, renaming or removing one. A built image appears in:
   * `.github/docker-build-config.json`: the build components and their platforms, read by the release
     workflow;
   * `.github/workflows/basic-images.yml` and `advanced-images.yml`: the matrices that build and publish
     the stage 1 and stage 2 images;
   * `.github/workflows/test-images.yml`: the sample application images, tagged by branch or release name
     rather than through `release-images.yaml`;
   * `.github/workflows/clean.yml`: the cleanup matrix that deletes package versions when a branch or tag
     goes away;
   * `chart/helm/spark-on-k8s/release-images.yaml`: the image reference with its `:main` tag, rewritten at
     release time;
   * `.github/helm-charts-release-config.yaml`: the images the release action rewrites.

   A missing entry breaks nothing, which is why it drifts: the image still builds, but its tag is never
   rewritten or its package versions are never cleaned up. `clean.yml` was missing the entry for
   `qubership-tests-spark-hive-connection`, so that image's versions outlived deleted branches.

### Verify the update

1. Build the images: stage 1 for amd64 and arm64, stage 2 (Python) for amd64, as configured in
   `.github/docker-build-config.json`, then the five sample application images in
   `.github/workflows/test-images.yml`, which take the new Spark images as their base.
2. Render the chart from the transfer image, not from `./create_chart.sh`. The build applies patches the
   local script does not: `update_charts.py` rewrites the controller and webhook security context, and the
   schemas and image tags are synced. Rendering the local output shows unpatched upstream templates, so the
   OpenShift check below cannot pass there.

   ```sh
   docker rm -f transfer 2>/dev/null || true
   docker create --name transfer spark-on-k8s-transfer:test /none
   rm -rf ./target/chart-transfer
   mkdir -p ./target/chart-transfer
   docker cp transfer:/chart/. ./target/chart-transfer && docker rm transfer
   helm template qubership-spark-on-k8s \
     ./target/chart-transfer/helm/spark-on-k8s
   ```

   The image is the one built in `Update spark-operator.4`; for a released build, substitute
   `ghcr.io/netcracker/qubership-spark-on-k8s-transfer:<tag>`. The image is `FROM scratch` with no command,
   so `docker create` needs the `/none` argument even though the container never starts, and the chart
   lands under `helm/` because the image copies the repository's `chart/` directory to `/chart`. The
   destination is removed and recreated before the copy: `docker cp` will not create its parent directory
   on a fresh clone, and copying into an existing directory instead of its contents would nest the new tree
   one level down and silently leave the previous run's chart in the path that Helm renders.

   Render the guarded branches too, because the defaults leave most of them out:
   `--api-versions gateway.networking.k8s.io/v1` exercises the HTTPRoute paths, and
   `--api-versions security.openshift.io/v1` exercises the OpenShift security-context branch, which
   must drop `runAsUser`, `runAsGroup` and `fsGroup` from the controller and webhook pods. Enable the
   history server with `oauth2Proxy`, the thrift server, the integration tests and the status
   provisioner in the values used for the render.
3. Run the Robot suites with the tags `test_app` (plus `java`, `py`, `long-pi`), `history-server`,
   `volcano`, `hive-connection`, `hive-seaweedfs` and `alerts`, plus `spark_images` from
   `image_tests.robot` and `spark_container_hardening` from `testapp.robot`, which matter most after an
   image bump. CI does not run these suites, so this check is manual. This is also the check that qualifies
   the operator against the Spark version it does not bundle: an application submitted by the operator and
   running on the new image is the evidence, and a failure here is the blocker listed in the blocker rule
   under `Prepare the update`.
4. Check the functional paths by hand: submit a `SparkApplication`, open the history server, run a query
   on the thrift server, log in through oauth2-proxy and Keycloak, and confirm that the status provisioner
   reports the deployment as complete.
5. All pipeline checks pass: super-linter on the pull request, the basic image build (stage 1, amd64 and
   arm64), the advanced build (the Python image) and the manually dispatched test image build. Nothing
   else runs the Robot suites.
6. Sweep the old values one last time and decide on every hit:
   `git grep -n "<old spark version>"` and `git grep -n "<old operator version>"`, plus the JAR versions
   swept in `Update Spark.7`. The only acceptable leftovers are historical notes, such as the drift
   example in `Update spark-operator.3`.
7. Refresh the baseline table at the top of this section. It records what was verified, and a stale row
   turns the next run into guesswork.

## Useful links

* https://github.com/kubeflow/spark-operator kubeflow spark operator github repository
* https://github.com/kubeflow/spark-operator/tree/master/charts/spark-operator-chart spark operator community chart
* https://www.kubeflow.org/docs/components/spark-operator/ spark operator kubeflow docs
* https://hub.docker.com/r/kubeflow/spark-operator/tags spark operator docker image
* https://github.com/apache/spark spark repository
* https://github.com/apache/spark-docker spark docker repository
* https://hub.docker.com/r/apache/spark spark docker image
* https://spark.apache.org/documentation.html spark documentation
* https://spark.apache.org/docs/4.3.0/monitoring.html#spark-history-server-configuration-options spark history documentation
* https://spark.apache.org/docs/4.3.0/sql-distributed-sql-engine.html spark thrift server documentation
* https://issues.apache.org/jira/projects/SPARK/issues apache spark jira
* https://github.com/oauth2-proxy/oauth2-proxy oauth2 proxy repository
* https://github.com/oauth2-proxy/manifests/tree/main/helm/oauth2-proxy oauth2 proxy chart
* https://quay.io/repository/oauth2-proxy/oauth2-proxy oauth2-proxy docker
* https://github.com/Netcracker/qubership-docker-integration-tests- integration tests repository
* https://github.com/Netcracker/qubership-deployment-status-provisioner status provisioner repository