- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Deployment](#deployment)
    - [Configuration](#configuration)
        - [Spark Service Integration Tests Parameters](#spark-service-integration-tests-parameters)
    - [Manual Deployment](#manual-deployment)

# Introduction

This guide covers the necessary steps to install and execute Spark service tests on Kubernetes using Helm.
The chart installs Spark Service Integration Tests service, pod and secret in Kubernetes.

# Prerequisites

* Kubernetes 1.11+ or OpenShift 3.11+
* `kubeclt` 1.11+ or `oc` 3.11+ CLI
* Helm 3.0+

# Deployment

Spark service integration tests installation is based on Helm Chart.
directory.

## Configuration

This section provides the list of parameters required for Spark Service Integration Tests installation and execution.

### Spark Service Integration Tests Parameters

The `service.name` parameter specifies the name of Spark integration tests service.

The `serviceAccount.create` parameter specifies whether service account for Spark Integration Tests is to be deployed or not.

The `serviceAccount.name` parameter specifies the name of the service account that is used to deploy Spark Integration Tests. If this
parameter is empty, the service account, the required role, role binding are
created automatically with default names (`spark-integration-tests`).

The `integrationTests.image` parameter specifies the Docker image of Spark Service.

The `integrationTests.tags` parameter specifies the tags combined together with `AND`, `OR` and `NOT` operators that select test cases to run. 
You can use `spark`, `test_app` tags to run appropriate tests. You can use `alerts` tags to run alert tests. 

To run alert tests you need to use `alerts` tag and set `prometheusUrl` variable in parameters:
```
spark-integration-tests:
  enabled: true
  tags: alerts
  prometheusUrl: http://prometheus.cloud.url.qubership.com
```

The `integrationTests.sparkAppsNamespace` parameter specifies the name of the Kubernetes namespace where Spark apps are located.

The `integrationTests.resources.requests.memory` parameter specifies the minimum amount of memory the container should use. 
The value can be specified with SI suffixes (E, P, T, G, M, K, m) or 
their power-of-two-equivalents (Ei, Pi, Ti, Gi, Mi, Ki). The default value is `256Mi.`

The `integrationTests.resources.requests.cpu` parameter specifies the minimum number of CPUs the container should use. 
The default value is `200m.`

The `integrationTests.resources.limits.memory` parameter specifies the maximum amount of memory the container can use. 
The value can be specified with SI suffixes (E, P, T, G, M, K, m) or 
their power-of-two-equivalents (Ei, Pi, Ti, Gi, Mi, Ki). The default value is `256Mi`.

The `integrationTests.resources.limits.cpu` parameter specifies the maximum number of CPUs the container can use. 
The default value is `400m.`

The `integrationTests.affinity` parameter specifies the affinity scheduling rules. The value should be specified in json format. The
parameter can be empty.

The `integrationTests.status_writing_enabled` - optional parameter specifies enable/disable writing status of Integration tests execution to
specified Custom Resource. The default value is "true".

The `integrationTests.cr_status_writing.is_short_status_message` - optional parameter specifies the size of integration test status message.
The message may have a short output of the tests execution result, which is contains the first line of file result.txt or full parsed result. The default value is "true".

The `integrationTests.cr_status_writing.only_integration_tests` - optional parameter specifies to deploy only integration tests without any
component (component was installed before). The default value is "true".

The `integrationTests.cr_status_writing.status_custom_resource_path` - optional parameter specifies path to Custom Resource that should be used
for write status of auto-tests execution. The value is a field from k8s entity selfLink without apis prefix and namespace part.
The path should be composed according to the following template: `<group>/<apiversion>/<namespace>/<plural>/<customResourceName>`.
The default value is ``apps/v1/spark/deployments/spark-integration-tests-runner``.

## Manual Deployment

### Installation

To deploy Spark service integration tests with Helm you need to customize the `values.yaml` file. For example:

```
service:
  name: spark-integration-tests-runner

serviceAccount:
  create: true
  name: "spark-integration-tests"

integrationTests:
  image: "ghcr.io/netcracker/qubership-spark-service-integration-tests"
  tags: "spark"
  sparkAppsNamespace: "spark-apps"
  resources:
    requests:
      memory: 256Mi
      cpu: 50m
    limits:
      memory: 256Mi
      cpu: 400m
```

To deploy the service you need to execute the following command:

```
helm install ${RELEASE_NAME} ./spark-service-integration-tests -n ${NAMESPACE}
```

where:

* `${RELEASE_NAME}` is the Helm Chart release name and the name of the Spark service integration tests. 
For example, `spark-integration-tests`.
* `${NAMESPACE}` is the Kubernetes namespace to deploy Spark service integration tests. 
For example, `spark`.

You can monitor the deployment process in the Kubernetes dashboard or using `kubectl` in the command line:

```
kubectl get pods
```

### Uninstalling

To uninstall Spark service integration tests from Kubernetes you need to execute the following command:

```
helm delete ${RELEASE_NAME} -n ${NAMESPACE}
```

where:

* `${RELEASE_NAME}` is the Helm Chart release name and the name of the already deployed Spark service integration tests. 
For example, `spark-integration-tests`.
* `${NAMESPACE}` is the Kubernetes namespace to deploy Spark service integration tests. 
For example, `spark`.

The command uninstalls all the Kubernetes resources associated with the chart and deletes the release.
