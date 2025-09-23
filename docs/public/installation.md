This document describes the installation procedures for the qubership-spark-on-k8s chart. Qubership-spark-on-k8s chart includes kubeflow spark-operator chart as a subchart as the main component. 
The following topics are covered in the document:

* [Prerequisites](#prerequisites)
    * [Common](#common) 
      * [Deployment to Restricted Environment](#deployment-to-restricted-environment)
* [Best Practices and Recommendations](#best-practices-and-recommendations)
    * [HWE](#hardware-requirements)
        * [Small](#small)
        * [Medium](#medium)
        * [Large](#large)
* [Parameters](#parameters)
  * [Spark Operator](#spark-operator)
    * [Monitoring Configuration](#monitoring-configuration) 
  * [Spark History Server](#spark-history-server)
  * [Spark Thrift Server](#spark-thrift-server)
  * [Spark Integration Tests](#spark-integration-tests)
  * [Status Provisioner Job](#status-provisioner-job)
* [Installation](#installation)
  * [Before You Begin](#before-you-begin)
  * [On-Prem](#on-prem)
    * [Manual Deployment](#manual-deployment)
    * [HA Scheme](#ha-scheme)
    * [Non-HA Scheme](#non-ha-scheme-not-recommended)
    * [Spark History Server Deployment](#spark-history-server-deployment) 
        * [Using Secure S3 Endpoint for Spark History Server](#using-secure-s3-endpoint-for-spark-history-server) 
        * [Enabling HTTPS for Spark History Server Ingresses](#enabling-https-for-spark-history-server-ingresses)
        * [Enabling HTTPS for Spark History Server Service](#enabling-https-for-spark-history-server-service)
        * [Enabling TLS on Spark History Server UI Inside Kubernetes](#enabling-tls-on-spark-history-server-ui-inside-kubernetes)
          * [Re-encrypt Route In Openshift Without NGINX Ingress Controller](#re-encrypt-route-in-openshift-without-nginx-ingress-controller)
        * [Enabling Authentication Using OAuth2 Proxy](#enabling-authentication-using-oauth2-proxy)
        * [Enabling HTTPS for OAuth2 Proxy Service](#enabling-https-for-oauth2-proxy-service)
        * [Enabling TLS on OAuth2 Proxy Inside Kubernetes](#enabling-tls-on-oauth2-proxy-inside-kubernetes)
          * [Re-encrypt OAuth2 Proxy Route In Openshift without NGINX Ingress Controller](#re-encrypt-oauth2-proxy-route-in-openshift-without-nginx-ingress-controller)
        * [S3 Initialization Job](#s3-initialization-job)
          * [AWS V4 Signature Configuration](#aws-v4-signature-configuration)
          * [TLS](#tls)
    * [Spark Thrift Server Deployment](#spark-thrift-server-deployment)
* [Upgrade](#upgrade)
  * [Spark Upgrade](#spark-upgrade)
  * [Spark Operator Upgrade](#spark-operator-upgrade)
* [Rollback](#rollback) 

# Prerequisites

The prerequisites are specified in the below sections.

## Common

The common prerequisites are specified below.

* Create the two namespaces - one for the operator and the other for the Spark applications.  
  For example, `spark-operator-gcp` and `spark-apps`, respectively.   
  **Note**: To avoid monitoring dashboard issues, the operator's namespace **must not match** any combination of `spark<any_delimiter>operator` words. For example, Spark Operator, Spark-Operator, spark operator, and so on do not work.
  The namespaces, where applications can be deployed are specified by the `spark-operator.spark.jobNamespaces` parameter.
* If you intend to use Spark Operator with Volcano, Volcano must be installed before Spark Operator. For more information about using Spark Operator with Volcano, refer to [User guide](/docs/public/user-guide.md#using-spark-operator-with-volcano)
* Install Keycloak to use OAuth2 Proxy authentication for the Spark History Server and Spark applications.

## S3

* For Spark History Server, the `logDirectory` path in S3 storage should be created. For example, `s3a://tmp/spark/logs`.
* For Spark Thrift, the `hivemetastore.warehouse` path and `spark.kubernetes.file.upload.path` in `sparkProperties` should be created in S3. For example, `s3a://thrift/warehouse` and `s3a://thrift/tmp`. 

#### Deployment to Restricted Environment

If Spark operator is installed to the cloud with security restrictions and/or the deploy user has no access to cluster wide resources, the following prerequisites must be met:

* The Kubeflow Spark Operator Custom Resource Definitions (CRD) should be created by the cloud administrator. 
CRD is provided by the community as part of the HELM chart archive. CRDs can be found in the release docker-transfer image in the chart with path qubership-spark-on-k8s\charts\spark-operator\crds\

During the deployment, the `--skip-crds flag` flag must be used.

* Deploy user must have permissions to create webhooks required for spark operator:

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: restricted_deploy_user_cluster_role
rules:
- apiGroups:
  - admissionregistration.k8s.io
  resources:
  - mutatingwebhookconfigurations
  - validatingwebhookconfigurations
  verbs:
  - get
  - create
  - update
  - patch
  - list 
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClustrRoleBinding
metadata:
  name: restricted_deploy_user_cluster_role_binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: restricted_deploy_user_cluster_role
subjects:
- kind: ServiceAccount
  name: restricted-sa
  namespace: kube-system 
```

* Specific roles and cluster roles must be created in Spark operator and Spark applications namespaces for the deploy user. You can do it by applying the following templates:

```yaml
# objects needed for controller
---
# Source: spark-operator/templates/controller/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ${Replace_with_sparkoperator_controller_name} # Replace the name with spark operator controller name, usually sparkoperator-spark-operator-controller
  namespace: ${Replace_with_sparkoperator_installation_namespace} # Replace the namespace with spark operator installation namespace
  labels:
    helm.sh/chart: spark-operator-2.3.0
    app.kubernetes.io/name: spark-operator
    app.kubernetes.io/instance: ${spark_operator_instance} #spark operator instance, sparkoperator by default
    app.kubernetes.io/version: "2.3.0"
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: controller
rules:
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - get
- apiGroups:
  - apiextensions.k8s.io
  resources:
  - customresourcedefinitions
  verbs:
  - get
---
# Source: spark-operator/templates/controller/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${Replace_with_sparkoperator_controller_name}
  namespace: ${Replace_with_sparkoperator_installation_namespace}
  labels:
    helm.sh/chart: spark-operator-2.3.0
    app.kubernetes.io/name: spark-operator
    app.kubernetes.io/instance: ${spark_operator_instance}
    app.kubernetes.io/version: "2.3.0"
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: controller
subjects:
- kind: ServiceAccount
  name: ${Replace_with_sparkoperator_controller_name}
  namespace: ${Replace_with_sparkoperator_installation_namespace}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ${Replace_with_sparkoperator_controller_name}
---
# Source: spark-operator/templates/controller/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ${Replace_with_sparkoperator_controller_name}
  namespace: ${Replace_with_sparkoperator_installation_namespace}
  labels:
    helm.sh/chart: spark-operator-2.3.0
    app.kubernetes.io/name: spark-operator
    app.kubernetes.io/instance: ${spark_operator_instance}
    app.kubernetes.io/version: "2.3.0"
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: controller
rules:
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - create
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  resourceNames:
  - ${Replace_with_sparkoperator_controller_lock_name} # Replace the name with spark operator controller lock name, usually sparkoperator-spark-operator-controller-lock
  verbs:
  - get
  - update
---
# Source: spark-operator/templates/controller/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ${Replace_with_sparkoperator_controller_name}
  namespace: ${Replace_with_apps_namespace} # replace with applications namespace
  labels:
    helm.sh/chart: spark-operator-2.3.0
    app.kubernetes.io/name: spark-operator
    app.kubernetes.io/instance: ${spark_operator_instance}
    app.kubernetes.io/version: "2.3.0"
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: controller
rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete
  - deletecollection
- apiGroups:
  - ""
  resources:
  - configmaps
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete
- apiGroups:
  - ""
  resources:
  - persistentvolumeclaims
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete
- apiGroups:
  - ""
  resources:
  - services
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete
- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - create
  - update
  - patch
- apiGroups:
  - extensions
  - networking.k8s.io
  resources:
  - ingresses
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - delete
- apiGroups:
  - sparkoperator.k8s.io
  resources:
  - sparkapplications
  - scheduledsparkapplications
  - sparkconnects
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete
- apiGroups:
  - sparkoperator.k8s.io
  resources:
  - sparkapplications/status
  - sparkapplications/finalizers
  - scheduledsparkapplications/status
  - scheduledsparkapplications/finalizers
  - sparkconnects/status
  verbs:
  - get
  - update
  - patch
- apiGroups:
  - scheduling.incubator.k8s.io
  - scheduling.sigs.dev
  - scheduling.volcano.sh
  resources:
  - podgroups
  verbs:
  - "*" 
---
# Source: spark-operator/templates/controller/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${Replace_with_sparkoperator_controller_name}
  namespace: ${Replace_with_sparkoperator_installation_namespace}
  labels:
    helm.sh/chart: spark-operator-2.3.0
    app.kubernetes.io/name: spark-operator
    app.kubernetes.io/instance: ${spark_operator_instance}
    app.kubernetes.io/version: "2.3.0"
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: controller
subjects:
- kind: ServiceAccount
  name: ${Replace_with_sparkoperator_controller_name}
  namespace: ${Replace_with_sparkoperator_installation_namespace}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ${Replace_with_sparkoperator_controller_name}
---
# Source: spark-operator/templates/controller/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${Replace_with_sparkoperator_controller_name}
  namespace: ${Replace_with_apps_namespace}
  labels:
    helm.sh/chart: spark-operator-2.3.0
    app.kubernetes.io/name: spark-operator
    app.kubernetes.io/instance: ${spark_operator_instance}
    app.kubernetes.io/version: "2.3.0"
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: controller
subjects:
- kind: ServiceAccount
  name: ${Replace_with_sparkoperator_controller_name}
  namespace: ${Replace_with_sparkoperator_installation_namespace}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ${Replace_with_sparkoperator_controller_name}
```

```yaml
# objects needed for webhook
---
# Source: spark-operator/templates/webhook/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ${Replace_with_sparkoperator_webhook_name} # Replace the name with spark operator webhook name, usually sparkoperator-spark-operator-webhook
  namespace: ${Replace_with_sparkoperator_installation_namespace}
  labels:
    helm.sh/chart: spark-operator-2.3.0
    app.kubernetes.io/name: spark-operator
    app.kubernetes.io/instance: ${spark_operator_instance}
    app.kubernetes.io/version: "2.3.0"
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: webhook
rules:
- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - create
  - update
  - patch
- apiGroups:
  - admissionregistration.k8s.io
  resources:
  - mutatingwebhookconfigurations
  - validatingwebhookconfigurations
  verbs:
  - list
  - watch
- apiGroups:
  - admissionregistration.k8s.io
  resources:
  - mutatingwebhookconfigurations
  - validatingwebhookconfigurations
  resourceNames:
  - ${Replace_with_sparkoperator_webhook_name}
  verbs:
  - get
  - update
---
# Source: spark-operator/templates/webhook/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${Replace_with_sparkoperator_webhook_name}
  namespace: ${Replace_with_sparkoperator_installation_namespace}
  labels:
    helm.sh/chart: spark-operator-2.3.0
    app.kubernetes.io/name: spark-operator
    app.kubernetes.io/instance: ${spark_operator_instance}
    app.kubernetes.io/version: "2.3.0"
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: webhook
subjects:
- kind: ServiceAccount
  name: ${Replace_with_sparkoperator_webhook_name}
  namespace: ${Replace_with_sparkoperator_installation_namespace}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ${Replace_with_sparkoperator_webhook_name}
---
# Source: spark-operator/templates/webhook/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ${Replace_with_sparkoperator_webhook_name}
  namespace: ${Replace_with_sparkoperator_installation_namespace}
  labels:
    helm.sh/chart: spark-operator-2.3.0
    app.kubernetes.io/name: spark-operator
    app.kubernetes.io/instance: ${spark_operator_instance}
    app.kubernetes.io/version: "2.3.0"
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: webhook
rules:
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - create
- apiGroups:
  - ""
  resources:
  - secrets
  resourceNames:
  - ${Replace_with_sparkoperator_webhook_certs_name} # Replace the name with spark operator webhook certs name, usually sparkoperator-spark-operator-webhook-certs
  verbs:
  - get
  - update
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - create
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  resourceNames:
  - ${Replace_with_sparkoperator_webhook_lock_name} # Replace the name with spark operator webhook lock name, usually sparkoperator-spark-operator-webhook-lock
  verbs:
  - get
  - update
---
# Source: spark-operator/templates/webhook/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ${Replace_with_sparkoperator_webhook_name}
  namespace: ${Replace_with_apps_namespace}
  labels:
    helm.sh/chart: spark-operator-2.3.0
    app.kubernetes.io/name: spark-operator
    app.kubernetes.io/instance: ${spark_operator_instance}
    app.kubernetes.io/version: "2.3.0"
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: webhook
rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - resourcequotas
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - sparkoperator.k8s.io
  resources:
  - sparkapplications
  - sparkapplications/status
  - sparkapplications/finalizers
  - scheduledsparkapplications
  - scheduledsparkapplications/status
  - scheduledsparkapplications/finalizers
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete
---
# Source: spark-operator/templates/webhook/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${Replace_with_sparkoperator_webhook_name}
  namespace: ${Replace_with_sparkoperator_installation_namespace}
  labels:
    helm.sh/chart: spark-operator-2.3.0
    app.kubernetes.io/name: spark-operator
    app.kubernetes.io/instance: ${spark_operator_instance}
    app.kubernetes.io/version: "2.3.0"
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: webhook
subjects:
- kind: ServiceAccount
  name: ${Replace_with_sparkoperator_webhook_name}
  namespace: ${Replace_with_sparkoperator_installation_namespace}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ${Replace_with_sparkoperator_webhook_name}
---
# Source: spark-operator/templates/webhook/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${Replace_with_sparkoperator_webhook_name}
  namespace: ${Replace_with_apps_namespace}
  labels:
    helm.sh/chart: spark-operator-2.3.0
    app.kubernetes.io/name: spark-operator
    app.kubernetes.io/instance: ${spark_operator_instance}
    app.kubernetes.io/version: "2.3.0"
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: webhook
subjects:
- kind: ServiceAccount
  name: ${Replace_with_sparkoperator_webhook_name}
  namespace: ${Replace_with_sparkoperator_installation_namespace}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ${Replace_with_sparkoperator_webhook_name}
```

```yaml
# objects for spark-applications
---
# Source: spark-operator/templates/spark/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ${Replace_with_sparkapp_sa_name} # Replace the name with spark app name, sparkapps-sa by default
  namespace: ${Replace_with_apps_namespace}
  labels:
    helm.sh/chart: spark-operator-2.3.0
    app.kubernetes.io/name: spark-operator
    app.kubernetes.io/instance: ${spark_operator_instance}
    app.kubernetes.io/version: "2.3.0"
    app.kubernetes.io/managed-by: Helm
rules:
- apiGroups:
  - ""
  resources:
  - pods
  - configmaps
  - persistentvolumeclaims
  - services
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete
  - deletecollection
---
# Source: spark-operator/templates/spark/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${Replace_with_sparkapp_sa_name}
  namespace: ${Replace_with_apps_namespace}
  labels:
    helm.sh/chart: spark-operator-2.3.0
    app.kubernetes.io/name: spark-operator
    app.kubernetes.io/instance: ${spark_operator_instance}
    app.kubernetes.io/version: "2.3.0"
    app.kubernetes.io/managed-by: Helm
subjects:
- kind: ServiceAccount
  name: ${Replace_with_sparkapp_sa_name}
  namespace: ${Replace_with_apps_namespace}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ${Replace_with_sparkapp_sa_name}

---
# Source: spark-operator/templates/spark/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
automountServiceAccountToken: true
metadata:
  name: ${Replace_with_sparkapp_sa_name}
  namespace: ${Replace_with_apps_namespace}
  labels:
    helm.sh/chart: spark-operator-2.3.0
    app.kubernetes.io/name: spark-operator
    app.kubernetes.io/instance: ${spark_operator_instance}
    app.kubernetes.io/version: "2.3.0"
    app.kubernetes.io/managed-by: Helm
```

During the deployment, `spark-operator.controller.rbac.create`,  `spark-operator.webhook.rbac.create`, `spark-operator.spark.rbac.create` and `spark-operator.spark.serviceAccount.create` parameters must be set to `false` to avoid role creation.


* If the Pod Security Policy as given in [https://kubernetes.io/docs/concepts/policy/pod-security-policy/](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) is enabled on the Kubernetes (K8s) cluster, it is mandatory to set the `securityContext.runAsUser` parameter to 185.
* If you are using the OpenShift cloud with restricted SCC, the Spark and Spark applications' namespaces must have specific annotations:

```bash
oc annotate --overwrite namespace airflow openshift.io/sa.scc.uid-range="185/185"
oc annotate --overwrite namespace airflow openshift.io/sa.scc.supplemental-groups="185/185"
```
* If setting annotations is not allowed and default SCC is used, it is necessary to set the spark operator and thrift server securityContext `runAsUser` parameter to `~`, for example, for spark operator:

```yaml
controller:
...
  podSecurityContext:
...
    runAsUser: ~
...
webhook:
...
  podSecurityContext:
...
    runAsUser: ~
...
spark-history-server:
...
  oauth2Proxy:
...
    securityContext:
...
      runAsUser: ~
...
  securityContext:
...
    runAsUser: ~
...
spark-thrift-server:
...
  securityContext:
...
    runAsUser: ~
```

# Best Practices and Recommendations

Best practices and recommendations for the installation are as follows:

## Hardware Requirements

The hardware requirements are as follows:

**Note**: Kubeflow Spark Operator include some parameters that are not part of resource profiles that can affect performance or can be useful for performance debugging:
* `spark-operator.controller.workers` - Reconcile concurrency, higher values might increase memory usage.
* `spark-operator.controller.maxTrackedExecutorPerApp` - Specifies the maximum number of Executor pods that can be tracked by the controller per SparkApplication.
* `spark-operator.controller.pprof.*` - can be used to enable and configure [pprof](https://github.com/google/pprof)
* `spark-operator.controller.workqueueRateLimiter.*` - Workqueue rate limiter configuration forwarded to the controller-runtime Reconciler.

The hardware requirements as per profiles are as follows:

### Small

`Small` profile is enough to start the spark operator services and to run not more than one spark application at the same time.

The profile resources are given below:

| Container                             | CPU  | RAM, Mi | Number of containers |
|---------------------------------------|------|---------|----------------------|
| Spark-operator-controller             | 0.2  | 400     | 1                    |
| Spark-operator-webhook                | 0.2  | 300     | 1                    |
| Spark-history-server  (`*`)           | 0.45 | 1088    | 1                    |
| Oauth2-proxy (`*`)                    | 0.1  | 128     | 1                    |
| Status-provisioner  (`**`)            | 0.2  | 200     | 1                    |
| Integration tests   (`*`)(`**`)       | 0.2  | 256     | 1                    |

Here `*` - optional container based on configuration, `**` - temporary container.

### Medium

`Medium` profile is enough to start the spark operator services and to run a few spark applications at the same time.

The profile resources are given below:

| Container                             | CPU  | RAM, Mi | Number of containers |
|---------------------------------------|------|---------|----------------------|
| Spark-operator-controller             | 1.5  | 3000    | 1                    |
| Spark-operator-webhook                | 0.3  | 512     | 1                    |
| Spark-history-server  (`*`)           | 0.55 | 1088    | 1                    |
| Oauth2-proxy (`*`)                    | 0.2  | 256     | 1                    |
| Status-provisioner  (`**`)            | 0.2  | 200     | 1                    |
| Integration tests   (`*`)(`**`)       | 0.4  | 256     | 1                    |

Here `*` - optional container based on configuration, `**` - temporary container.

### Large

`Large` profile is enough to start the spark operator services and to run the significant amount of spark applications at the same time.

The profile resources are shown below:

| Container                             | CPU  | RAM, Mi | Number of containers |
|---------------------------------------|------|---------|----------------------|
| Spark-operator-controller             | 3    | 6000    | 2                    |
| Spark-operator-webhook                | 0.6  | 768     | 2                    |
| Spark-history-server  (`*`)           | 1.05 | 2112    | 1                    |
| Oauth2-proxy (`*`)                    | 0.4  | 512     | 1                    |
| Status-provisioner  (`**`)            | 0.2  | 200     | 1                    |
| Integration tests   (`*`)(`**`)       | 0.4  | 256     | 1                    |

Here `*` - optional container based on configuration, `**` - temporary container.

# Parameters

The parameters are described in the below sub-sections.

## Spark Operator

For more information, refer to the original Helm Chart documents at [https://github.com/kubeflow/spark-operator/tree/master/charts/spark-operator-chart](https://github.com/kubeflow/spark-operator/tree/master/charts/spark-operator-chart). In spark-on-k8s Kubeflow spark-operator chart is added as a subchart, so the parameters should be set at `spark-operator` sub-parameters..

The following table lists the additional spark-on-k8s configuration parameters.  

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| grafanadashboard.enable | bool | `false` | The string to submit a Grafana dashboard.|
| grafanaApplicationDashboard.enable | bool | `false` | The string to submit a Grafana dashboard for applications.|
| appServiceMonitor.enable | bool | `false` | The string to submit a service monitor for Spark applications.|

### Monitoring Configuration

To enable all monitoring options, it is necessary to set the following parameters:

```yaml
spark-operator:
    # Enable metrics
    prometheus:
    # Enable metrics
      metrics:
        enable: true
    # Enable pod monitor to gather metrics
      podMonitor:
        create: true
    # Enable dashboard for applications
grafanaApplicationDashboard:
  enable: true
# Enable service monitor for applications
appServiceMonitor:
  enable: false
# Enable spark operator dashboard
grafanadashboard:
  enable: false
# Enable spark operator alerts
prometheusRules:
  alert:
    enable: false
```

## Spark History Server

The following table lists the Spark History Server configuration parameters.  
As qubership-spark-on-k8s chart is a parent chart, it can override the Spark History Server deployment parameters.

| Parameter                                              | Mandatory                                    | Type              | Default                                                                                                                   | Description                                                                                                                                                                                                                                                                              |
|--------------------------------------------------------|----------------------------------------------|-------------------|---------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `spark-history-server.enabled`                         | false                                        | string            | false                                                                                                                     | It enables the Spark History Server deployment.                                                                                                                                                                                                                                          |
| `spark-history-server.ingress.enabled`                 | false                                        | bool              | true                                                                                                                      | It enables the Spark History Server ingress creation.                                                                                                                                                                                                                                    |
| `spark-history-server.ingress.host`                    | Mandatory if ingress is enabled              | string            | -                                                                                                                         | It is the ingress host and should be compatible with the cluster's ingress URL routing rules.                                                                                                                                                                                            |
| `spark-history-server.ingress.path`                    | Mandatory if ingress is enabled.             | string            | -                                                                                                                         | It should be set to '/'.                                                                                                                                                                                                                                                                 |
| `spark-history-server.image.pullPolicy`                | false                                        | string            | `"IfNotPresent"`                                                                                                          | The image pull policy.                                                                                                                                                                                                                                                                   |
| `spark-history-server.image.repository`                | false                                        | string            | '"ghcr.io/netcracker/qubership-spark-customized"'                                                                         | The image repository.                                                                                                                                                                                                                                                                    |
| `spark-history-server.image.tag`                       | false                                        | string            | current release                                                                                                           | This overrides the image tag whose default is the chart appVersion.                                                                                                                                                                                                                      |
| `spark-history-server.imagePullSecrets`                | false                                        | list              | `[]`                                                                                                                      | The image pull secrets.                                                                                                                                                                                                                                                                  |
| `spark-history-server.fullnameOverride`                | false                                        | string            | `"spark-history-server"`                                                                                                  | The string to override a release name.                                                                                                                                                                                                                                                   |
| `spark-history-server.logDirectory`                    | true                                         | string            | 's3a://tmp/spark/logs'                                                                                                       | The directory to look for Spark applications' event logs.                                                                                                                                                                                                                                |
| `spark-history-server.podSecurityContext`              | false                                        | object            | `{}`                                                                                                                      | The pod security context.                                                                                                                                                                                                                                                                |
| `spark-history-server.replicaCount`                    | false                                        | int               | `1`                                                                                                                       | The desired number of pods.                                                                                                                                                                                                                                                              |
| `spark-history-server.resources`                       | false                                        | object            | `{}`                                                                                                                      | The pod resource requests and limits.                                                                                                                                                                                                                                                    |
| `spark-history-server.securityContext`                 | false                                        | object            | `{}`                                                                                                                      | The operator container security context.                                                                                                                                                                                                                                                 |
| `spark-history-server.serviceAccount.create`           | false                                        | bool              | `true`                                                                                                                    | This creates a service account for the Spark History Server.                                                                                                                                                                                                                             |
| `spark-history-server.serviceAccounts.name`            | false                                        | string            | `""`                                                                                                                      | The optional name for the Spark History Server service account.                                                                                                                                                                                                                          |
| `spark-history-server.service.externalPort`            | false                                        | int               | `80`                                                                                                                      | The Spark History Server service external port.                                                                                                                                                                                                                                          |
| `spark-history-server.service.internalPort`            | false                                        | int               | `18080`                                                                                                                   | The Spark History Server service internal port.                                                                                                                                                                                                                                          |
| `spark-history-server.service.type`                    | false                                        | string            | `ClusterIP`                                                                                                               | The Spark History Server service type.                                                                                                                                                                                                                                                   |
| `spark-history-server.sparkProperties`                 | false                                        | string            | `""`                                                                                                                      | The Spark properties that are added to the config map, which is mounted by `/opt/spark/conf` and exposed to the `SPARK_CONF_DIR` environment variable.                                                                                                                                   |
| `spark-history-server.s3.enabled`                      | false                                        | bool              | `false`                                                                                                                   | It should be enabled if S3 storage is used to store event logs.                                                                                                                                                                                                                          |
| `spark-history-server.s3.endpoint`                     | Mandatory if s3 is enabled.                  | string            | ""                                                                                                                        | The S3 storage endpoint.                                                                                                                                                                                                                                                                 |
| `spark-history-server.s3.accesskey`                    | Mandatory if s3 is enabled.                  | string            | ""                                                                                                                        | The base64 encoded S3 storage access key. It is stored in a secret.                                                                                                                                                                                                                      |
| `spark-history-server.s3.secretkey`                    | Mandatory if s3 is enabled.                  | string            | ""                                                                                                                        | The base64 encoded S3 storage secret key. It is stored in a secret.                                                                                                                                                                                                                      |
| `spark-history-server.s3.sslInsecure`                  | false                                        | bool, null        | `~`                                                                                                                       | If set to true, sets env `JAVA_TOOL_OPTIONS` to `-Dcom.amazonaws.sdk.disableCertChecking`, meaning that there will be no certificate validation for S3. **Note:** Default image include AWS java SDK v2, where disabling certificate verification is not supported.                      |
| `spark-history-server.s3InitJob.enabled`               | bool                                         | false             | `"true"`                                                                                                                  | The parameter that enables the Pre-install/upgrade Helm job. The job creates S3 path in S3 object storage and upload a mock file. The S3 path to create is set in `s3.warehouseDir` parameter.                                                                                           |
| `spark-history-server.s3InitJob.awsSigV4`              | string                                       | false             | `"aws:minio:s3:s3"`                                                                                                       | AWS V4 signature authentication configuration of the following format `<provider1[:prvdr2[:reg[:srv]]]>`. Used to authenticate requests to S3 storage. Configured to work with S3 MinIO by default. Details at https://curl.se/docs/manpage.html.                                        |
| `spark-history-server.s3InitJob.initAnnotations`       | string                                       | false             | `"helm.sh/hook": pre-install, pre-upgrade "helm.sh/hook-weight": "-10" helm.sh/hook-delete-policy": before-hook-creation` | The S3 init job annotations.                                                                                                                                                                                                                                                             |
| `spark-history-server.s3InitJob.priorityClassName`     | string                                       | false             | `~`                                                                                                                       | Priority class name for init job.                                                                                                                                                                                                                                                        |
| `spark-history-server.oauth2Proxy.enabled`             | false                                        | bool              | false                                                                                                                     | It enables OAuth2 Proxy authentication for the Spark History Server UI.                                                                                                                                                                                                                  |
| `spark-history-server.oauth2Proxy.config.clientID`     | Mandatory if oauth2Proxy is enabled.         | string            | ""                                                                                                                        | The Keycloak client ID, configured for the Spark History Server authentication.                                                                                                                                                                                                          |
| `spark-history-server.oauth2Proxy.config.clientSecret` | Mandatory if oauth2Proxy is enabled.         | string            | ""                                                                                                                        | The Keycloak client secret, configured for the Spark History Server authentication.                                                                                                                                                                                                      |
| `spark-history-server.oauth2Proxy.config.configFile`   | Mandatory if oauth2Proxy is enabled.         | multi-line string | ""                                                                                                                        | The OAuth2 Proxy configuration. All properties are described in the _OAuth2 Proxy Official Documentation_ at [https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/overview#config-file](https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/overview#config-file). |
| `spark-history-server.oauth2Proxy.ingress.enabled`     | Mandatory if oauth2Proxy is enabled.         | bool              | false                                                                                                                     | It enables the OAuth2 Proxy ingress.                                                                                                                                                                                                                                                     |
| `spark-history-server.oauth2Proxy.ingress.host`        | Mandatory if oauth2Proxy ingress is enabled  | string            | -                                                                                                                         | It is the ingress host and should be compatible with the cluster's ingress URL routing rules.                                                                                                                                                                                            |
| `spark-history-server.oauth2Proxy.ingress.path`        | Mandatory if oauth2Proxy ingress is enabled. | string            | -                                                                                                                         | It should be set to '/'.                                                                                                                                                                                                                                                                 |
| `spark-history-server.priorityClassName`               | false                                        | string, null      | `~`                                                                                                                       | Priority class name for spark history server pods.                                                                                                                                                                                                                                       |
| `spark-history-server.extraEnv`                        | false                                        | object, null      | `~`                                                                                                                       | Extra environment variables for spark-history-server.                                                                                                                                                                                                                                    |
| `spark-history-server.extraVolumes`                    | false                                        | object, null      | `~`                                                                                                                       | Extra volumes for spark-history-server.                                                                                                                                                                                                                                                  |
| `spark-history-server.extraVolumeMounts`               | false                                        | object, null      | `~`                                                                                                                       | Extra volumeMounts for spark-history-server.                                                                                                                                                                                                                                             |
| `spark-history-server.extraSecrets`                    | false                                        | object, null      | `~`                                                                                                                       | Extra secrets that can be created by spark-history-server chart.                                                                                                                                                                                                                         
| `spark-history-server.affinity`                        | false                                        | object            | `{}`                                                                                                                         | The parameter specifies the affinity scheduling rules.                                                                                                                                                                                                                                   |
| `spark-history-server.livenessProbe.enabled`            | No        | Boolean | `true` | Enables or disables the liveness probe.                                     |
| `spark-history-server.livenessProbe.initialDelaySeconds`| No        | Integer | `0`     | Number of seconds after the container has started before liveness probes are initiated. |
| `spark-history-server.livenessProbe.timeoutSeconds`     | No        | Integer | `1`     | Number of seconds after which the probe times out.                          |
| `spark-history-server.livenessProbe.failureThreshold`   | No        | Integer | `3`     | Minimum consecutive failures for the probe to be considered failed, causing container restart. |
| `spark-history-server.livenessProbe.periodSeconds`      | No        | Integer | `10`    | How often (in seconds) to perform the probe.                                |
| `spark-history-server.readinessProbe.enabled`            | No        | Boolean | `true` | Enables or disables the readiness probe.                                    |
| `spark-history-server.readinessProbe.initialDelaySeconds`| No        | Integer | `0`     | Number of seconds after the container has started before readiness probes are initiated. |
| `spark-history-server.readinessProbe.timeoutSeconds`     | No        | Integer | `1`     | Number of seconds after which the probe times out.                          |
| `spark-history-server.readinessProbe.failureThreshold`   | No        | Integer | `3`     | Minimum consecutive failures for the probe to be considered failed, marking the container as **Not Ready**. |
| `spark-history-server.readinessProbe.periodSeconds`      | No        | Integer | `10`    | How often (in seconds) to perform the probe.                                                     |


## Spark Thrift Server

**Note**: Thrift Server is not tested with spark 4. Qubership Spark 4 customized image does not include delta libraries (delta-storage, delta-spark) that are required for Spark Thrift Server.

The following table lists the Spark Thrift Server configuration parameters.  
As GCP Spark Operator's chart is a parent chart, it can override the Spark Thrift Server deployment parameters.

| Parameter                                                       | Mandatory                        | Type               | Default                                                                                           | Description                                                                                                                                                                                                                                                                                                                                                            |
|-----------------------------------------------------------------|----------------------------------|--------------------|---------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `spark-thrift-server.enabled`                                   | false                            | string             | false                                                                                             | It enables the Spark Thrift Server deployment.                                                                                                                                                                                                                                                                                                                         |
| `spark-thrift-server.ingress.enabled`                           | false                            | bool               | true                                                                                              | It enables the Spark Thrift Server ingress creation.                                                                                                                                                                                                                                                                                                                   |
| `spark-thrift-server.ingress.host`                              | Mandatory if ingress is enabled.  | string             | -                                                                                                 | It is the ingress host and should be compatible with the cluster's ingress URL routing rules.                                                                                                                                                                                                                                                                          |
| `spark-thrift-server.ingress.path`                              | Mandatory if ingress is enabled. | string             | -                                                                                                 | It should be set to '/'.                                                                                                                                                                                                                                                                                                                                               |
| `spark-thrift-server.image.pullPolicy`                          | false                            | string             | `"IfNotPresent"`                                                                                  | The image pull policy.                                                                                                                                                                                                                                                                                                                                                 |
| `spark-thrift-server.image.repository`                          | false                            | string             | '"ghcr.io/netcracker/qubership-spark-customized"'                                                 | The image repository.                                                                                                                                                                                                                                                                                                                                                  |
| `spark-thrift-server.image.tag`                                 | false                            | string             | current release                                                                                   | This overrides the image tag.                                                                                                                                                                                                                                                                                                                                          |
| `spark-thrift-server.imagePullSecrets`                          | false                            | list               | `[]`                                                                                              | The image pull secrets.                                                                                                                                                                                                                                                                                                                                                |
| `spark-thrift-server.fullnameOverride`                          | false                            | string             | `"spark-thrift-server"`                                                                           | The string to override a release name.                                                                                                                                                                                                                                                                                                                                 |
| `spark-thrift-server.podSecurityContext`                        | false                            | object             | `{}`                                                                                              | The pod security context.                                                                                                                                                                                                                                                                                                                                              |
| `spark-thrift-server.replicaCount`                              | false                            | int                | `1`                                                                                               | The desired number of pods. Currently, only one replica is supported.                                                                                                                                                                                                                                                                                                  |
| `spark-thrift-server.resources`                                 | false                            | object             | `{}`                                                                                              | The pod resource requests and limits.                                                                                                                                                                                                                                                                                                                                  |
| `spark-thrift-server.securityContext`                           | false                            | object             | `{}`                                                                                              | The operator container security context.                                                                                                                                                                                                                                                                                                                               |
| `spark-thrift-server.serviceAccount.create`                     | false                            | bool               | `true`                                                                                            | This creates a service account for the Spark thrift Server.                                                                                                                                                                                                                                                                                                            |
| `spark-thrift-server.serviceAccounts.name`                      | false                            | string             | `""`                                                                                              | The optional name for the Spark thrift Server service account.                                                                                                                                                                                                                                                                                                         |
| `spark-thrift-server.service.type`                              | false                            | string             | `NodePort`                                                                                        | The Spark thrift Server service type.                                                                                                                                                                                                                                                                                                                                  |
| `spark-thrift-server.service.ports.thriftServerPort.name`       | false                            | string             | `thrift-server-port`                                                                              | Thrift Server's port protocol.                                                                                                                                                                                                                                                                                                                                         |
| `spark-thrift-server.service.ports.thriftServerPort.protocol`   | false                            | string             | `TCP`                                                                                             | Name of the Thrift server's port.                                                                                                                                                                                                                                                                                                                                      |
| `spark-thrift-server.service.ports.thriftServerPort.port`       | false                            | int                | `10000`                                                                                           | The Thrift server's port.                                                                                                                                                                                                                                                                                                                                                  |
| `spark-thrift-server.service.ports.thriftServerPort.targetPort` | false                            | int                | `10000`                                                                                           | The Thrift server's target port.                                                                                                                                                                                                                                                                                                                                           |
| `spark-thrift-server.service.ports.thriftServerPort.nodePort`   | false                            | int                | `30204`                                                                                           | The Thrift server's node port.                                                                                                                                                                                                                                                                                                                                             |
| `spark-thrift-server.service.ports.sparkDriverPort.name`        | false                            | string             | `spark-driver-port`                                                                               | Name of the Thrift server's driver port.                                                                                                                                                                                                                                                                                                                               |
| `spark-thrift-server.service.ports.sparkDriverPort.protocol`    | false                            | string             | `TCP`                                                                                             | Name of the Thrift server's port.                                                                                                                                                                                                                                                                                                                                      |
| `spark-thrift-server.service.ports.sparkDriverPort.port`        | false                            | int                | `7078`                                                                                            | The Thrift server's driver port.                                                                                                                                                                                                                                                                                                                                           |
| `spark-thrift-server.service.ports.sparkDriverPort.targetPort`  | false                            | int                | `7078`                                                                                            | The Thrift server's driver target port.                                                                                                                                                                                                                                                                                                                                    |
| `spark-thrift-server.service.ports.sparkUIPort.name`            | false                            | string             | `spark-ui`                                                                                        | Name of the Thrift server's UI port.                                                                                                                                                                                                                                                                                                                                   |
| `spark-thrift-server.service.ports.sparkUIPort.protocol`        | false                            | string             | `TCP`                                                                                             | Name of the Thrift server's port.                                                                                                                                                                                                                                                                                                                                      |
| `spark-thrift-server.service.ports.sparkUIPort.port`            | false                            | int                | `4040`                                                                                            | The Thrift server's port.                                                                                                                                                                                                                                                                                                                                                  |
| `spark-thrift-server.service.ports.sparkUIPort.targetPort`      | false                            | int                | `4040`                                                                                            | The Thrift server's target port.                                                                                                                                                                                                                                                                                                                                           |
| `spark-thrift-server.service.ports.sparkUIPort.nodePort`        | false                            | int                | `30868`                                                                                           | The Thrift server's node port.                                                                                                                                                                                                                                                                                                                                             |
| `spark-thrift-server.service.ports.additionalPorts`             | false                            | list               | `- name: spark-blockmanager protocol: TCP port: 22322 targetPort: 22322 nodePort: 32486`          | Declaration of additional ports.                                                                                                                                                                                                                                                                                                                                       |
| `spark-thrift-server.sparkProperties`                           | false                            | string             | Default properties' examples are below the table.                                                  | The Spark properties that are added to the config map, which is mounted by `/opt/spark/conf` and exposed to the `SPARK_CONF_DIR` environment variable.                                                                                                                                                                                                                 |
| `spark-thrift-server.s3.endpoint`                               | true                             | string             | ""                                                                                                | The S3 storage endpoint.                                                                                                                                                                                                                                                                                                                                               |
| `spark-thrift-server.s3.accesskey`                              | true                             | string             | ""                                                                                                | The S3 storage access key.                                                                                                                                                                                                                                                                                                                                                 |
| `spark-thrift-server.s3.secretkey`                              | true                             | string             | ""                                                                                                | The S3 storage secret key.                                                                                                                                                                                                                                                                                                                                                 |
| `spark-thrift-server.log4j2Properties`                          | false                            | multi-line string  | Default properties' examples are below the table.                                                  | Log4j2 configuration.                                                                                                                                                                                                                                                                                                                                                  |
| `spark-thrift-server.hivemetastore.uri`                         | true                             | string             | -                                                                                                 | The Hive Metastore URI. For example, `thrift://hive-metastore.hive-metastore-r.svc:9083`                                                                                                                                                                                                                                                                                        |
| `spark-thrift-server.hiveConfigSecret.hiveSiteProperties`       | false                            | multi-line string  | -                                                                                                 | The `hive-site.xml` config stored in a Kubernetes Secret.                                                                                                                                                                                                                                                                                                                  |
| `spark-thrift-server.hiveConfigSecret.coreSiteProperties`       | false                            | multi-line string  | -                                                                                                 | The `core-site.xml` config stored in a Kubernetes Secret.                                                                                                                                                                                                                                                                                                                                                       |
| `spark-thrift-server.hiveConfigSecret.coreSiteProperties`       | false                            | multi-line string  | -                                                                                                 | The `hdfs-site.xml` config stored in a Kubernetes Secret.                                                                                                                                                                                                                                                                                       |
| `spark-thrift-server.hivemetastore.warehouse`                   | true                             | string             | `s3a://thrift/warehouse`                                                                          | The bucket in S3 to store data.                                                                                                                                                                                                                                                                                                                                            |
| `spark-thrift-server.sparkMasterUri`                            | true                             | string             | "local"                                                                                           | The master URL for the Spark cluster. By default, it works in the local master mode. To use Kubernetes as a resource manager, Spark master should be set to the Kubernetes API Server, k8s://HOST:PORT. For example, `k8s://https://my.k8s.cluster.qubership.com:6443`. For more details, refer to [https://spark.apache.org/docs/latest/submitting-applications.html#master-urls](https://spark.apache.org/docs/latest/submitting-applications.html#master-urls). |
| `spark-thrift-server.priorityClassName`                         | false                            | string, null       | `~`                                                                                               | Priority class name for spark Thrift server pods.                                                |

```yaml
# Default log4j2 properties
log4j2Properties: |
 rootLogger.level = info
 rootLogger.appenderRef.stdout.ref = console
 appender.console.type = Console
 appender.console.name = console
 appender.console.target = SYSTEM_ERR
 appender.console.layout.type = PatternLayout
 logger.spark.name = org.apache.spark
 logger.spark.level = debug
 logger.nio.name = java.base/sun.nio.ch
 logger.nio.level = debug
 logger.thriftserver.name = org.apache.spark.sql.hive.thriftserver
 logger.thriftserver.level = debug
 logger.hive.name = org.apache.hive
 logger.hive.level = debug
 appender.console.layout.pattern = %d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n%ex

# Default Spark properties
sparkProperties: |
  spark.kubernetes.executor.deleteOnTermination true
  spark.driver.extraJavaOptions "-Divy.cache.dir=/tmp -Divy.home=/tmp"
  spark.kubernetes.file.upload.path s3a://thrift/tmp
  spark.dynamicAllocation.enabled true
  spark.hadoop.fs.s3a.committer.name directory
  spark.hadoop.fs.s3a.fast.upload true
  spark.hadoop.fs.s3a.impl org.apache.hadoop.fs.s3a.S3AFileSystem
  spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version 2
  spark.hadoop.mapreduce.fileoutputcommitter.cleanup-failures.ignored true
  spark.hadoop.parquet.enable.summary-metadata false
  spark.sql.catalogImplementation hive
  spark.sql.hive.metastorePartitionPruning true
  spark.sql.legacy.createHiveTableByDefault.enabled false
  spark.sql.parquet.filterPushdown true
  spark.sql.parquet.mergeSchema true
  spark.sql.parquet.output.committer.class org.apache.parquet.hadoop.ParquetOutputCommitter
  spark.hadoop.fs.s3a.aws.credentials.provider org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider
  spark.hadoop.fs.s3.buckets.create.enabled true
  spark.hadoop.fs.s3a.committer.magic.enabled false
  spark.hadoop.fs.s3a.committer.staging.abort.pending.uploads true
  spark.sql.extensions io.delta.sql.DeltaSparkSessionExtension
  spark.sql.catalog.spark_catalog org.apache.spark.sql.delta.catalog.DeltaCatalog
  spark.hadoop.fs.s3a.committer.staging.conflict-mode append
  spark.hadoop.fs.s3a.connection.ssl.enabled false
  spark.sql.sources.default parquet
  spark.hadoop.fs.s3a.connection.timeout 200000
  spark.hadoop.fs.s3a.fast.upload.active.blocks 4
  spark.hadoop.fs.s3a.fast.upload.buffer array
  spark.hadoop.fs.s3a.max.total.tasks 5
  spark.hadoop.fs.s3a.multipart.threshold 128M
  spark.hadoop.fs.s3a.path.style.access true
  spark.hadoop.fs.s3a.threads.max 10
  spark.hadoop.fs.s3a.path.style.access true
  spark.serializer org.apache.spark.serializer.KryoSerializer
  spark.blockManager.port 22322
  spark.executor.memory 6g
  spark.sql.shuffle.partitions 50
```

## Spark Integration Tests

The Spark Integration Tests parameters are specified below.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `enabled`  | bool | `false` | The parameter specifies whether the integration tests are installed or not. Set to `true` to run tests. |
| `service.name` | string | `spark-integration-tests-runner` | The parameter specifies the name of the Spark integration tests' service. |
| `serviceAccount.create` | bool | `true` | The parameter specifies whether the service account for Spark Integration Tests is to be deployed or not. |
| `serviceAccount.name` | string | `spark-integration-tests` | The parameter specifies the name of the service account that is used to deploy Spark Integration Tests. |
| `image` | string | <div style="width:300px">`ghcr.io/netcracker/qubership-spark-on-k8s-tests:main`</div> | The parameter specifies the Docker image of Spark Service. |
| `tags` | string | `test_app` | The parameter specifies the tags combined together with AND, OR, and NOT operators that select the test cases to run. To run all tests, set `tags: alertsORtest_app`.|
| `sparkAppsNamespace` | string | `spark-apps` | The parameter specifies the name of the Kubernetes namespace, where Spark apps are located. |
| `resources.requests.memory` | string | `256Mi` | The parameter specifies the minimum amount of memory the container should use. |
| `resources.requests.cpu` | string | `200m` | The parameter specifies the minimum number of CPUs the container should use. |
| `resources.limits.memory` | string | `256Mi` | The parameter specifies the maximum amount of memory the container can use. |
| `resources.limits.cpu` | string | `400m` | The parameter specifies the maximum number of CPUs the container can use. |
| `integrationTests.affinity` | object | `{}` | The parameter specifies the affinity scheduling rules. |
| `status_writing_enabled` | bool | `true` | The parameter specifies enable/disable writing status of Integration tests' execution to the specified Custom Resource. |
| `cr_status_writing.is_short_status_message` | bool | `true` | The parameter specifies the size of the integration test status message. |
| `cr_status_writing.only_integration_tests` | bool | `true` | The parameter specifies whether to deploy only integration tests without any component (component was installed before). |
| `cr_status_writing.status_custom_resource_path` | string | `apps/v1/spark/deployments/spark-integration-tests-runner` | The parameter (optional) specifies the path to Custom Resource that should be used for the write status of auto-tests execution. |
| `prometheusUrl` | string | `""` | The parameter specifies the path to Custom Resource that should be used for the write status of auto-tests execution. |
| `sparkAppsServiceAccount` | string | `sparkapps-sa` | The parameter specifies the service account name in the Spark apps namespace. |
| `priorityClassName`               | false                                        | string, null      | `~`                                                                                    | The parameter specifies the priority class name for spark tests pods.  |

 
For example:

```yaml
spark-integration-tests:
  enabled: true
  sparkAppsNamespace: spark-apps
  tags: alertsORtest_app
  prometheusUrl: http://my.prometheus.address.qubership.com
  service:
    name: spark-integration-tests-runner
  serviceAccount:
    create: true
    name: spark-integration-tests
  resources:
    requests:
      memory: 256Mi
      cpu: 50m
    limits:
      memory: 256Mi
      cpu: 400m
```

## Status Provisioner Job

Status Provisioner is a component for providing the overall service status.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `statusProvisioner.enabled` | bool | `true` | The parameter specifies if the status provisioner job is deployed.|
| `statusProvisioner.image` | string | <div style="width:300px"> `ghcr.io/netcracker/qubership-deployment-status-provisioner:0.1.1` </div> | The image for the Deployment Status Provisioner pod.|
| `statusProvisioner.lifetimeAfterCompletion` | int | `600` | The number of seconds that the job remains alive after its completion.|
| `statusProvisioner.podReadinessTimeout` | int | `300` | The timeout in seconds that the job waits for the monitored resources to be ready or completed.|
| `statusProvisioner.integrationTestsTimeout` | int | `2000` | The timeout in seconds that the job waits for the integration tests to complete.|
| `statusProvisioner.resources` | string | | The pod resource requests and limits.|
| `statusProvisioner.priorityClassName`               | false                                        | string, null      | `~`                                                     | Priority class name for spark operator pods. |


```yaml
statusProvisioner:
  enabled: true
  dockerImage: ghcr.io/netcracker/qubership-deployment-status-provisioner:0.1.1
  lifetimeAfterCompletion: 600
  podReadinessTimeout: 300
  integrationTestsTimeout: 300
  labels: {}
  resources: {}
```

# Installation

The installation procedure is described in the below sub-sections.

## Before You Begin

Installation [prerequisites](#prerequisites) should be fulfilled to prepare for the installation. 

# On-Prem

The installation for On-Prem is described below.

## Manual Deployment

The manual deployment procedure is specified below.

1. For qubership-spark-on-k8s installation, it is necessary to extract the combined chart from docker transfer image.

1. Edit the parameters in the **values.yaml** file. The configuration parameter details are described above.

1. Install the chart to the K8s namespace created in the [Prerequisites](#prerequisites) section.

   ```
   helm install <helm release name> <path to chart directory> --values <path to values.yaml file> --namespace <namespace to install> --debug
   #Example
   helm install spark-on-k8s spark-on-k8s --values spark-on-k8s/values.yaml --debug
   ```
## Non-HA Scheme (not recommended)

In this scheme Spark Operator is deployed in the non-HA scheme by default. The Operator controller and webhook replicas count is set to 1 by default.

## HA Scheme
 
To enable the HA mode, deploy the operator with more than one replicas of webhook and controller(`spark-operator.controller.replicas` and `spark-operator.webhook.replicas` parameters. One of the replicas is the leader. If the leader replica fails, the leader election process is started to determine a new leader from the replicas available. 
The leader pod's names are stored in a configmap.
   
For the application's high availability settings, refer to the Configuring Automatic Application Restart and Failure Handling section in the official User Guide at [https://github.com/kubeflow/spark-operator/blob/master/charts/spark-operator-chart/README.md](https://github.com/kubeflow/spark-operator/blob/master/charts/spark-operator-chart/README.md).

## DR Scheme

Spark Operator supports deployment in the Active-Active DR scheme.  
Independent instances of Spark Operator are installed on each site.

## Spark History Server Deployment

Spark History Server deployment can be enabled by the qubership-spark-on-k8s `spark-history-server.enabled` deployment parameter.
All possible parameters are listed in a table in the [Spark History Server Subchart Deployment Parameters](#spark-history-server) section.

Following is the example set of parameters that can be used to enable spark-history-server:

```yaml
spark-history-server:
  enabled: true
  ingress:
    enabled: true
    host: 'spark-history-server.your.cloud.qubership.com'
    path: '/'
  logDirectory: "s3a://tmp/spark/logs"
  s3:
    enabled: true
    endpoint: 'http://s3-endpoint.your.cloud.qubership.com'
    accesskey: 'bWluaW9hY2Nlc3NrZXk='
    secretkey: 'bWluaW9zZWNyZXRrZXk='
```

### Using Secure S3 Endpoint for Spark History Server

To connect to secure S3 endpoint, it is necessary to import S3 certificate to java truststore. Platform spark image entrypoint at the start of the image imports all certificates found in `TRUST_CERTS_DIR` directory into java truststore. The secret with certificate can be requested from cert-manager (using `spark-history-server.certManagerInegration.*`) parameters or created by the chart using `spark-history-server.extraSecrets` parameter. To mount the secret, the `spark-history-server.extraVolumeMounts` and `spark-history-server.extraVolumes` parameters must be used (the pre-created secret can also be mounted).  

For example:

```yaml
spark-history-server:
  extraEnv:
    - name: TRUST_CERTS_DIR
      value: /home/spark/trustcerts/
    - name: CURL_CA_BUNDLE
      value: /home/spark/trustcerts/s3Cert.crt
  extraVolumeMounts:
    - name: s3-tls-cert
      mountPath: /home/spark/trustcerts/s3Cert.crt
      subPath: s3Cert.crt
      readOnly: true
  extraVolumes:
    - name: s3-tls-cert
      secret:
        secretName: s3Cert
  extraSecrets:
    s3Cert:
      stringData: >
        s3Cert.crt: -----BEGIN CERTIFICATE-----

                       cert content goes here

                       -----END CERTIFICATE-----
  replicaCount: "1"
```

**Note**: Another insecure and not suitable for production option to connect to secure S3 endpoint is to disable certificate validation. To do so, it is necessary to set the `spark-history-server.s3.sslInsecure` parameter to true. Another option to disable the certificate validation is to use `spark-history-server.extraEnv` parameter and set `JAVA_TOOL_OPTIONS` environment variable to `-Dcom.amazonaws.sdk.disableCertChecking`. For this option to work, your image should include AWS java SDK v1, since the default image includes AWS java SDK v2 where disabling certificate verification is not supported.

### Enabling HTTPS for Spark History Server Ingresses

Some ingress providers allow setting the default certificates and forcing HTTPS for all ingresses in a cluster. For example, refer to nginx ingress details at [https://kubernetes.github.io/ingress-nginx/user-guide/tls/#default-ssl-certificate](https://kubernetes.github.io/ingress-nginx/user-guide/tls/#default-ssl-certificate). In this case, all ingresses in the K8s cluster are using the same default certificate.
However, it is possible to use TLS for Spark History Server Ingresses separately using a custom certificate. For example, for Web ingress, there are several options for adding a certificate manually:

1. Generate self-signed certificates for the `spark-history-server` service.

1.1. Create a configuration file for generating the SSL certificate.

```bash
cat <<EOF > server.conf 
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
prompt = no

[req_distinguished_name]
CN = spark-history-server.spark.svc

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
subjectAltName = @alt_names
[alt_names]
IP.1 = 127.0.0.1
DNS.1 = spark-history-server
DNS.2 = spark-history-server.spark
DNS.3 = spark-history-server.spark.svc
DNS.4 = <specify there ingress name of spark history server>
EOF
```

1.2. Create the CA certificate.

```bash
openssl req -days 730 -nodes -new -x509 -keyout ca.key -out ca.crt -subj "/CN=Spark History Server service"
```

1.3. Create KEY for the `spark-history-server` service.

```bash
openssl genrsa -out spark-tls.key 2048
```

1.4. Create a CRT file for `spark-history-server`.

```bash
openssl req -new -key spark-tls.key -subj "/CN=spark-history-server.spark.svc" -config server.conf | \
openssl x509 -req -days 730 -CA ca.crt -CAkey ca.key -CAcreateserial -out spark-tls.cert -extensions v3_request file server.conf
```

1.5 Create a secret for `spark-history-server` in Kubernetes.

```yaml  
kind: Secret
apiVersion: v1
metadata:
  name: spark-history-server-tls
  namespace: spark
data:
  ca.crt: >-
      crt | base 64 
  tls.crt: >-
      crt | base 64 
  tls.key: >-
      key | base 64 
  type: kubernetes.io/tls
```

1.6 Pass the following parameters to the chart:

```yaml 
ingress:
  enabled: true
  tls:
    enabled: true
    secretName: spark-history-server-tls
```

2. Using a ready-made certificate, implement the following actions.

2.1 Create a secret for `spark-history-server` in Kubernetes.

```yaml  
kind: Secret
apiVersion: v1
metadata:
  name: spark-history-server-made-tls
  namespace: spark
data:
  ca.crt: >-
      crt | base 64 
  tls.crt: >-
      crt | base 64 
  tls.key: >-
      key | base 64 
  type: kubernetes.io/tls
```

2.2 Pass the following parameters to the chart:

```yaml 
ingress:
  enabled: true
  tls:
    enabled: true
    secretName: spark-history-server-made-tls
```

#### Using Cert-manager to Get Certificate for Ingress

**Note**: Cert-manager must be installed in the cluster for this to work.

Cert-manager has support for providing https for ingresses by providing additional annotations. For more information, see [https://cert-manager.io/docs/usage/ingress/](https://cert-manager.io/docs/usage/ingress/). Spark-history-server chart allows adding custom annotations for spark-history-server ingress and therefore uses cert-manager for securing spark-history-server ingress resources. For example, there are several options for integrating cert-manager to create certificates:

1. Use annotation in ingress.

Pass the following parameters to the chart:

```yaml   
ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: common-cluster-issuer
  tls:
    enabled: true
    secretName: spark-history-server-tls
```

2. Use custom issuer and custom certificate.

When using this option, a separate certificate and issuer are created.

Pass the following parameters to the chart:

```yaml   
spark-history-server:
  replicaCount: "2"
  enabled: true
  certManagerInegration:
    enabled: true
    secretName: spark-history-server-services-tls-certificate
    subjectAlternativeName:
      additionalDnsNames: [specify there ingress name of spark history server]
  ingress:
    enabled: true
    tls:
      enabled: true
```

### Enabling HTTPS for Spark History Server Service

To enable HTTPS for Spark History Server Service:

1. Prepare the certificates as describe in the [Enabling HTTPS for Spark History Server Ingresses](#enabling-https-for-spark-history-server-ingresses) section.   
   Or use `extraVolumes` and `extraVolumeMounts` to mount existing certificates.
   Cert Manager configuration example:
   ```yaml
      certManagerInegration:
      enabled: true
      secretName: spark-history-tls-cm
      secretMounts:
        - mountPath: /home/spark/trustcerts/ca.crt
          subPath: ca.crt
        - mountPath: /home/spark/servercert/tls.crt
          subPath: tls.crt
        - mountPath: /home/spark/servercert/tls.key
          subPath: tls.key
      duration: 365
      subjectAlternativeName:
      additionalDnsNames: [ ]
      additionalIpAddresses: [ ]
      clusterIssuerName: common-cluster-issuer
   ```
2. Set the `extraEnv` variables pointing to certificates and keystore locations.
These locations should match with the directories where certificates are mounted in previous step.   
Certificates and the key should be in `pem` format. The keystore with specified private key and server side certificate is created on server's start up.
```yaml
extraEnv:
  - name: TRUST_CERTS_DIR
    value: "/home/spark/trustcerts"
  - name: TLS_KEY_PATH
    value: "/home/spark/servercert/tls.key"
  - name: TLS_CERT_PATH
    value: "/home/spark/servercert/tls.crt"
  - name: TLS_KEYSTORE_DIR
    value: "/tmp"
  - name: TLS_KEYSTORE_PASSWORD
    value: "keystorepassword"
```
`TLS_KEY_PATH` contains TLS private key location.  
`TLS_CERT_PATH` contains TLS server side certificate location.  
`TLS_KEYSTORE_DIR` contains the location of keystore used by Spart History server to store private key and server side certificate.  
`TLS_KEYSTORE_PASSWORD` contains password for the keystore.

3. Add Spark properties to enable TLS for Spark History server:
```yaml
sparkProperties: |
  spark.ssl.historyServer.enabled=true
  spark.ssl.historyServer.protocol=tls
  spark.ssl.historyServer.port=6044
  spark.ssl.historyServer.trustStore=/opt/java/openjdk/lib/security/cacerts
  spark.ssl.historyServer.keyStore=<keystor_dir>/keystore.p12
  spark.ssl.historyServer.trustStorePassword=changeit
  spark.ssl.historyServer.keyStorePassword=<set_keystore_password>
```

4. Configure TLS port for the service.
```yaml
service:
  externalPort: 443
  internalPort: 6044
  type: ClusterIP
```

### Enabling TLS on Spark History Server UI Inside Kubernetes

It is possible to enable TLS on Spark History Server web user interface directly inside kubernetes. For this, Spark History Server needs TLS key and certificate.
TLS key and certificate can be requested from cert-manager using `certManagerInegration.enabled` parameter. By default, it will create secret `spark-history-tls-cm` with TLS certificate, TLS key and CA certificate.
Alternatively, TLS key and certificate can be specified and mounted into the pod using `extraSecrets`, `extraVolumes`, `extraVolumeMounts` parameters.
Then, the mounted certificates should be set as described in the [Enabling HTTPS for Spark History Server Service](#enabling-https-for-spark-history-server-service) section to enable TLS on Spark History Server as a backend.
If using kubernetes with NGINX ingress controller, it is possible to pass the annotations for ingress controller to work with TLS backend. Configuration examples are shown below.

```yaml
ingress:
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
    nginx.ingress.kubernetes.io/proxy-ssl-verify: 'on'
    nginx.ingress.kubernetes.io/proxy-ssl-name: '<spark_history_server_service_name>.<spark_history_server_namespace>'              <----- replace with actual value
    nginx.ingress.kubernetes.io/proxy-ssl-secret: '<spark_history_server_namespace>/<spark_history_server_service_tls_secret_name>' <----- replace with actual values
  
certManagerInegration:
 enabled: true
 secretName: spark-history-tls-cm
 secretMounts:
  - mountPath: /home/spark/trustcerts/ca.crt
    subPath: ca.crt
  - mountPath: /home/spark/servercert/tls.crt
    subPath: tls.crt
  - mountPath: /home/spark/servercert/tls.key
    subPath: tls.key
 duration: 365
 subjectAlternativeName:
 additionalDnsNames: [ ]
 additionalIpAddresses: [ ]
 clusterIssuerName: common-cluster-issuer

extraEnv:
 - name: TRUST_CERTS_DIR
   value: "/home/spark/trustcerts"
 - name: TLS_KEY_PATH
   value: "/home/spark/servercert/tls.key"
 - name: TLS_CERT_PATH
   value: "/home/spark/servercert/tls.crt"
 - name: TLS_KEYSTORE_DIR
   value: "/tmp"
 - name: TLS_KEYSTORE_PASSWORD
   value: "keystorepassword"
   
sparkProperties: |
 spark.ssl.historyServer.enabled=true
 spark.ssl.historyServer.protocol=tls
 spark.ssl.historyServer.port=6044
 spark.ssl.historyServer.trustStore=/opt/java/openjdk/lib/security/cacerts
 spark.ssl.historyServer.keyStore=<keystor_dir>/keystore.p12
 spark.ssl.historyServer.trustStorePassword=changeit
 spark.ssl.historyServer.keyStorePassword=<set_keystore_password>

service:
 externalPort: 443
 internalPort: 6044
 type: ClusterIP
```

#### Re-encrypt Route In Openshift Without NGINX Ingress Controller

Ingress TLS re-encryption configuration in Openshift can be the same as for Kubernetes, if NGINX Ingress Controller is installed on Openshift.
In case of no NGINX Ingress Controller is installed on Openshift the following steps should be done to enable TLS re-encryption:

1. Disable Ingress in deployment parameters: `ingress.create: false`.

   Deploy with enabled web Ingress leads to incorrect Ingress and Route configuration.

2. Create the Route manually. You can use the following template as an example:

   ```yaml
   kind: Route
   apiVersion: route.openshift.io/v1
   metadata:
     annotations:
       route.openshift.io/termination: reencrypt
     name: <specify-unique-route-name>
     namespace: <specify-namespace-where-spark-history-server-is-installed>
   spec:
     host: <specify-your-target-host-here>
     to:
       kind: Service
       name: <spark_history_server_service_name>
       weight: 100
     port:
       targetPort: http
     tls:
       termination: reencrypt
       destinationCACertificate: <place-CA-certificate-here-from-spark-history-server-TLS-secret>
       insecureEdgeTerminationPolicy: Redirect
   ```

**Note**: If you can't access the webserver host after Route creation because of "too many redirects" error, then one of the possible root
causes is there is HTTP traffic between balancers and the cluster. To resolve that issue it is necessary to add the Route name to
the exception list at the balancers.

**Note**: It might be possible to create the route in Openshift automatically using annotations like `route.openshift.io/destination-ca-certificate-secret` and `route.openshift.io/termination: "reencrypt"` but this approach was not tested.


### Enabling Authentication Using OAuth2 Proxy

The authentication for the History Server user interface is implemented using the third-party OAuth2 Proxy service. It allows to add authentication
without changing the History Server's source code. OAuth2 Proxy is deployed as a sidecar for the History Server. 
The History Server's ingress is configured to check a request's authentication and redirect a user to the authentication page.
Keycloak is used as an Identity Provider.

To enable OAuth2 Proxy authentication:

1. Deploy Keycloak.
2. Configure a client.
   - If you are using Vanilla Keycloak, configure Keycloak referring to the OAuth2 Proxy official documentation at [https://oauth2-proxy.github.io/oauth2-proxy/configuration/providers/keycloak_oidc](https://oauth2-proxy.github.io/oauth2-proxy/configuration/providers/keycloak_oidc).
     In general, you need to: 
      * Create and configure a client.
      * Add Group Membership and Audience mappers to the client.
      * Create users to authenticate to the History Server UI.
5. Add the OAuth2 Proxy configuration to the Spark Operator's History Server deployment section.

```yaml
spark-history-server:
  oauth2Proxy:
    enabled: true
    config:
      # OAuth client ID
      clientID: "<your_client_id>" # set your client's ID
      # OAuth client secret
      clientSecret: "<your_client_secret>" # set your client's secret
      configFile: |-
       email_domains=[ "*" ] 
       insecure_oidc_allow_unverified_email=true
       insecure_oidc_skip_issuer_verification=true
       oidc_issuer_url="http://<keycloak_external_address>/auth/realms/<keycloak_realm_name>"
       cookie_secure=false
       provider="keycloak-oidc"
       code_challenge_method="S256"
       session_cookie_minimal=true
       upstreams="http://<spark_history_server_service_address>:80"
       skip_oidc_discovery=true
       login_url="https://<keycloak_external_address>/auth/realms/<keycloak_realm_name>/protocol/openid-connect/auth"
       redeem_url="http://<keycloak_inernal_address>/auth/realms/<keycloak_realm_name>/protocol/openid-connect/token"
       oidc_jwks_url="http://<keycloak_inernal_address>/auth/realms/<keycloak_realm_name>/protocol/openid-connect/certs"
       profile_url="http://<keycloak_inernal_address>/auth/realms/<keycloak_realm_name>/protocol/openid-connect/userinfo"
    ingress:
      enabled: true
      path: /
      supportsPathType: true
      pathType: ImplementationSpecific
      hosts:
        - <specify_oauth2_proxy_ingress_host>
```

4. Configure ingresses.
   OAuth2 Proxy ingress should be used to access the Spark History Server user interface. The Spark History Server's ingress should be disabled, it is not secured. 
  
**Note**: For Kubernetes cluster, the Spark History Server's ingress can be secured by adding annotations to require the authentication:

   ```yaml
   spark-history-server:
     ingress: #ingress of History Server
       enabled: true
       host: <history_server_host>
       path: /
       annotations:
         nginx.ingress.kubernetes.io/auth-url: "http://<oauth2_proxy_address>/oauth2/auth"
         nginx.ingress.kubernetes.io/auth-signin: "http://<oauth2_proxy_address>/oauth2/start?rd=$scheme://$best_http_host$request_uri"
         nginx.ingress.kubernetes.io/auth-response-headers: "x-auth-request-user, x-auth-request-email, x-auth-request-access-token"
         # nginx.ingress.kubernetes.io/proxy-buffer-size: 32k # set in case of getting 502 error code
   ```

### Configuring OAuth2 Proxy with HTTPS Enabled Keycloak

**Passing CA certificate to oauth2proxy**. For this approach, you need a secret created in kubernetes with CA certificate. You can do it manually. However, there are some other options for it:

1. Use a precreated certifciate.
2. Use the secret created by cert-manager (in this, secret `ca.crt` field must be used). For example:

```yaml
spark-history-server:
  certManagerInegration:
    secretName: spark-history-server-services-tls-certificate
    subjectAlternativeName:
      additionalDnsNames: localhost
```
3. Create the secret automatically using `spark-history-server.oauth2Proxy.extraObjects` parameter, for example (in this, secret `idpcert.crt` field must be used):
```yaml
spark-history-server:
...
    extraObjects:
      - apiVersion: v1
        kind: Secret
        metadata:
          name: oauth2proxyidpcert
        stringData:
          idpcert.crt: |-
            -----BEGIN CERTIFICATE-----
            certificate content goes here
            -----END CERTIFICATE-----
```

After this, it is necessary to mount the certificate into oauth2proxy pod and specify `provider-ca-file` additional argument, for example, for `oauth2proxyidpcert` secret:

```yaml
spark-history-server:
...
  oauth2Proxy:
    extraArgs:
      provider-ca-file: /idpcert.crt # path to certificate inside the containter
    extraVolumeMounts:
      - name: oauth2proxyidpcert
        mountPath: /idpcert.crt
        subPath: idpcert.crt # field in the secret with the certificate
        readOnly: true
    extraVolumes:
      - name: oauth2proxyidpcert
        secret:
          secretName: oauth2proxyidpcert
```

**Insecure mode (not recommended for production, only for testing)**. When using HTTPS instead of HTTP with self-signed certificates for testing, it is possible to ignore certificate errors using the `--ssl-upstream-insecure-skip-verify` and `--ssl-insecure-skip-verify` Oauth2Proxy options. It is possible to pass these options during the installation as in the following example:

```yaml
spark-history-server:
...
  oauth2Proxy:
...
    extraArgs:
      ssl-upstream-insecure-skip-verify: true
      ssl-insecure-skip-verify: true
...
```

### Enabling HTTPS for OAuth2 Proxy Service

1. Use `extraObjects`, `extraVolumes` and `extraVolumeMounts` to mount certificates and TLS private key.
In the configuration below, `ca-cm.crt` is used for proxying to TLS enabled Spark History Server. This certificate should be mounted either to `/etc/ssl/certs/ca-cm.crt` or set as `SSL_CERT_FILE` value using `extraEnv` variable. 
```yaml
oauth2Proxy:
  ...
  extraVolumeMounts:
   - name: oauth2proxycert
     mountPath: /tls.crt
     subPath: tls.crt
     readOnly: true
   - name: oauth2proxycert
     mountPath: /tls.key
     subPath: tls.key
     readOnly: true
   - name: oauth2proxycacerts
     mountPath: /etc/ssl/certs/ca-cm.crt
     subPath: ca-cm.crt
     readOnly: true

  extraVolumes:
   - name: oauth2proxycert
     secret:
       secretName: oauth2proxycert
   - name: oauth2proxycacerts
     secret:
       secretName: oauth2proxycacerts

  extraObjects:
   - apiVersion: v1
     kind: Secret
     metadata:
       name: oauth2proxycacerts
     stringData:
       ca-cm.crt: |-
         -----BEGIN CERTIFICATE-----
         certificate ca-cm.crt content goes here
         -----END CERTIFICATE-----
   - apiVersion: v1
     kind: Secret
     metadata:
       name: oauth2proxycert
     stringData:
       tls.crt: |-
         -----BEGIN CERTIFICATE-----
         certificate tls.crt content goes here
         -----END CERTIFICATE-----
       tls.key: |-
         -----BEGIN RSA PRIVATE KEY-----
         certificate tls.key content goes here
         -----END RSA PRIVATE KEY-----
```

2. Mounted OAuth2 Proxy service and mounted TLS certificate along with TLS private key should be configured as follows:
```yaml
oauth2Proxy:
  enabled: true
  httpScheme: https
  service:
     portNumber: 4443
     portName: tls
     targetPort: 8080
     appProtocol: https
  extraArgs:
    tls-cert-file: /tls.crt
    tls-key-file: /tls.key

  config:
    clientID: spark-history
    clientSecret: yourclientsecret
    configFile: >-
      ...
      ...
      redirect_url="https://<oauth2-proxy-tls-ingress>/oauth2/callback"
      upstreams="https://<spark-history-server-service-address>:443"
```

### Enabling TLS on OAuth2 Proxy Inside Kubernetes

It is possible to enable TLS on OAuth2 Proxy directly inside kubernetes. For this, OAuth2 Proxy Server needs TLS key and certificate.
TLS key and certificate can be specified and mounted into the pod using `extraObjects`, `extraVolumes`, `extraVolumeMounts` parameters.
Then the mounted certificates should be set as described in  [Enabling HTTPS for OAuth2 Proxy Service](#enabling-https-for-oauth2-proxy-service) to enable TLS on OAuth2 Proxy as a backend.
If using kubernetes with NGINX ingress controller, it is possible to pass annotations for ingress controller to work with TLS backend. Configuration examples are shown below.


```yaml
  ingress:
   enabled: true
   tls:
    - hosts:
       - oauth2proxy.k8s.qubership.com
      secretName: cm-tls-cert-ingress
   path: /
   supportsPathType: true
   pathType: ImplementationSpecific
   hosts:
    - oauth2proxy.k8s.qubership.com
   annotations:
    cert-manager.io/cluster-issuer: common-cluster-issuer
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
    nginx.ingress.kubernetes.io/proxy-ssl-verify: 'on'
    nginx.ingress.kubernetes.io/proxy-ssl-name: '<oauth2-proxy-service>.<spark-operator-gcp-namespace>'
    nginx.ingress.kubernetes.io/proxy-ssl-secret: '<spark-operator-gcp-namespace>/<oauth2proxy-server-cert-secret>'
```

#### Re-encrypt OAuth2 Proxy Route In Openshift without NGINX Ingress Controller

Ingress TLS re-encryption configuration in Openshift can be the same as for Kubernetes, if NGINX Ingress Controller is installed on Openshift.
In case of no NGINX Ingress Controller is installed on Openshift the following steps should be done to enable TLS re-encryption:

1. Disable Ingress in deployment parameters: `ingress.create: false`.

   Deploy with enabled web Ingress leads to incorrect Ingress and Route configuration.

2. Create Route manually. You can use the following template as an example:

   ```yaml
   kind: Route
   apiVersion: route.openshift.io/v1
   metadata:
     annotations:
       route.openshift.io/termination: reencrypt
     name: <specify-unique-route-name>
     namespace: <specify-namespace-where-oauth2-proxy-is-installed>
   spec:
     host: <specify-your-target-host-here>
     to:
       kind: Service
       name: <spark_history_server_service_name>
       weight: 100
     port:
       targetPort: http
     tls:
       termination: reencrypt
       destinationCACertificate: <place-CA-certificate-here-from-oauth2-proxy-TLS-secret>
       insecureEdgeTerminationPolicy: Redirect
   ```

**Note**: If you can't access the webserver host after Route creation because of "too many redirects" error, then one of the possible root
causes is there is HTTP traffic between balancers and the cluster. To resolve that issue it is necessary to add the Route name to
the exception list at the balancers.

**Note** It might be possible to create the route in openshift automatically using annotations like `route.openshift.io/destination-ca-certificate-secret` and `route.openshift.io/termination: "reencrypt"` but this approach was not tested.

### S3 Initialization Job

Hive Metastore requires a warehouse directory in the S3 storage. It is configured by `s3.warehouseDir` deployment parameter.  
To automatically create the bucket and path, `s3InitJob` should be enabled. After the bucket and path are created, a mock file is uploaded to the path to keep the path from being removed.
`Curl` communicates with S3 storage by AWS S3 REST API uses `curl`. `Curl` supports AWS V4 signature authentication for requests.

```yaml
s3InitJob:
  enabled: true
  awsSigV4: "aws:minio:s3:s3"
  priorityClassName: ~
  initAnnotations:
    "helm.sh/hook": pre-install, pre-upgrade
    "helm.sh/hook-weight": "-10"
    "helm.sh/hook-delete-policy": before-hook-creation
  resources:
    limits:
      cpu: 50m
      memory: 64Mi
    requests:
      cpu: 50m
      memory: 64Mi
```

Signature configuration string is set in `s3InitJob.awsSigV4` and is different for different S3 storages.
By default, `s3InitJob.awsSigV4: "aws:minio:s3:s3"` to work with S3 MinIO. If a different S3 storage is used, the signature configuration should be updated according the below instruction.

### AWS V4 Signature Configuration

Configuration string format: <provider1[:prvdr2[:reg[:srv]]]>

- The provider argument is a string that is used by the algorithm, when creating outgoing authentication headers.
- The region argument is a string that points to a geographic area of a resources collection (region-code) when the region name is omitted from the endpoint.
- The service argument is a string that points to a function provided by a cloud (service-code) when the service name is omitted from the endpoint.

### TLS

TLS configuration is described in the [Using Secure S3 Endpoint For Spark History Server](#using-secure-s3-endpoint-for-spark-history-server) section.

## Spark Thrift Server Deployment

You can enable the Spark Thrift Server deployment by the Spark Operator GCP `spark-thrift-server.enabled` deployment parameter.
All possible parameters are listed in a table in the [Spark Thrift Server Subchart Deployment Parameters](#spark-thrift-server) section.

Following are the Spark Operator deployment parameters with Spark Thrift Server deployment enabled:

```yaml
sparkJobNamespaces: [spark-apps] 
ingressUrlFormat: "{{$appName}}-ui-svc.your.cloud.qubership.com"
securityContext:
  runAsUser: 185
resources:
  limits:
    cpu: 100m
    memory: 300Mi
  requests:
    cpu: 100m
    memory: 300Mi
webhook:
  enable: true
podMonitor:
  enable: true
  labels:
    app.kubernetes.io/component: monitoring
    app.kubernetes.io/name: spark-operator-gcp-podmonitor
    app.kubernetes.io/part-of: platform-monitoring
    k8s-app: spark-operator-gcp-podmonitor
grafanadashboard:
  enable: true
prometheusRules:
  alert: 
    enable: true

spark-thrift-server:
  enabled: true
  ingress:
    enabled: true
    host: 'spark-thrift-server.kubernetes.cluster.com'
    path: '/'
  s3:
    enabled: true
    endpoint: 'http://minio-gateway.kubernetes.cluster.com'
    accesskey: 'accesskey'
    secretkey: 'secretkey'
  hivemetastore:
    uri: thrift://hive-metastore.hive-metastore-r.svc:9083
    warehouse: s3a://thrift/warehouse
  sparkMasterUri: k8s://https://kubernetes.cluster.com:6443
```

# Upgrade

The upgrade procedure is specified below.

## Spark Upgrade

Spark Operator supports 2.4.X and 3.X versions of Spark.

### Upgrade Process

1. Upgrade the version of the base docker image of Spark used in the Dockerfile of the Spark application.  
   The versions of Spark docker images can be found in the Spark Operator's release manifest.  
   Note that in the dockerfile of Spark 3, a user with ID 185 is set as the user that the actual main process runs as.

2. Update the version labels in the SparkApplication configuration file of the Spark application to avoid confusion due to the old version.
   This does not affect the functionality.

3. Upgrade the Spark Operator using helm upgrade.
