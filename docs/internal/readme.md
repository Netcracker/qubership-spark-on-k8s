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

This is the runbook for bringing the distribution up to a new upstream release. It also feeds the
update skill, so keep it accurate: every step names the files to change and the check that proves the
change works.

One update is one pull request, with a commit per concern: operator chart, operator image, Spark image,
supporting images and release plumbing, documentation. Cite a step as `<section>.<step>`, for example
`Update Spark.2`, when reporting progress or resuming after an interruption.

The baseline table records the state this runbook was last verified against. Read the current values
from the files before changing anything; the numbers move, the locations do not.

### Baseline version pins

| What | Pinned value | Defined in |
| --- | --- | --- |
| Spark | `4.3.0` | `spark-customized/Dockerfile` (both `FROM` lines), sample apps, docs, examples |
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

### Update spark-operator

1. Check the [community releases](https://github.com/kubeflow/spark-operator/releases). The controller
   image tag and the chart tarball come from the same release, so bump them together. If the new Spark
   has no matching operator release, you may have to build the operator image from scratch on the new
   Spark base instead of skipping the bump.
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

1. Change `FROM apache/spark:<version>` in `spark-customized/Dockerfile`, in the main stage and in the
   `jdk-arm64` stage.
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
   only, as configured in `.github/docker-build-config.json`.
6. Re-check the JDK override. Both images replace the bundled JDK with Temurin on amd64 and copy
   `/opt/java/openjdk` over the base image. Delete the three `jdk-*` stages and the `COPY --from=jdk` line
   once the base images ship Temurin 21.0.13.1 or later. While the override stays, bump its tag for CVE
   fixes in both Dockerfiles and keep the `jdk-arm64` stage on the same base image as the main stage. arm64
   keeps the JDK from the base image, so the two architectures differ on purpose.
7. Run a CVE pass on the built image. Close patch-level findings with another override JAR in both
   Dockerfiles; the patched JAR set in the baseline table is the current example.
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
   oauth2-proxy container in `templates/deployment.yaml` and the `oauth2Proxy` block of `values.yaml`. Keep
   the local additions: the Gateway API `httproute.yaml` and `oauth2Proxy.gateway` values, the
   `ingressEnabled` and `gatewayEnabled` helpers in `_helpers.tpl` with their `null` semantics, and the
   `requiredSecretKeys` and `client_id` handling.
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
   `docs/public/troubleshooting-guide.md` rather than the copy under `references/`: the sync workflow
   overwrites the copy on every push to `main`.
4. When you add an agent package, register it in `apm.yml`. If the package copies files out of `docs/` the
   way the troubleshooting references do, add the copies to the jscpd ignore list
   (`.github/linters/.jscpd.json`).

### Verify the update

1. Build the images: stage 1 for amd64 and arm64, stage 2 (Python) for amd64, as configured in
   `.github/docker-build-config.json`, then the five sample application images in
   `.github/workflows/test-images.yml`, which take the new Spark images as their base.
2. Assemble and render the chart: run `./create_chart.sh`, then `helm template ./target/chart/spark-on-k8s`.
   Render the guarded branches too, because the defaults leave most of them out:
   `--api-versions gateway.networking.k8s.io/v1` exercises the HTTPRoute paths, and
   `--api-versions security.openshift.io/v1` exercises the OpenShift security-context branch, which
   must drop `runAsUser`, `runAsGroup` and `fsGroup` from the controller and webhook pods. Enable the
   history server with `oauth2Proxy`, the thrift server, the integration tests and the status
   provisioner in the values used for the render.
3. Run the Robot suites with the tags `test_app` (plus `java`, `py`, `long-pi`), `history-server`,
   `volcano`, `hive-connection`, `hive-seaweedfs` and `alerts`. CI does not run these suites, so this check
   is manual.
4. Check the functional paths by hand: submit a `SparkApplication`, open the history server, run a query
   on the thrift server, log in through oauth2-proxy and Keycloak, and confirm that the status provisioner
   reports the deployment as complete.

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