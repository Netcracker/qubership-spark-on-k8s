# Overview

This guide provides references to the original GCP Spark Operator documentation and describes parts of the configuration that are specific to Qubership.

## Table of Contents

* [Spark Application on Kubernetes](#spark-application-on-kubernetes)
* [Using a SparkApplication](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#using-a-sparkapplication)
* [Integration with S3 Storage](#integration-with-s3-storage)
* [Spark Application Dependencies](#integration-with-s3-storage)
* [Writing a SparkApplication Spec](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#writing-a-sparkapplication-spec)
    * [Specifying Deployment Mode](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#specifying-deployment-mode)
    * [Specifying Application Dependencies](#spark-application-dependencies)
    * [Specifying Spark Configuration](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#specifying-spark-configuration)
    * [Specifying Hadoop Configuration](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#specifying-hadoop-configuration)
    * [Writing Driver Specification](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#writing-driver-specification)
    * [Writing Executor Specification](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#writing-executor-specification)
    * [Specifying Extra Java Options](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#specifying-extra-java-options)
    * [Specifying Environment Variables](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#specifying-environment-variables)
    * [Requesting GPU Resources](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#requesting-gpu-resources)
    * [Host Network](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#host-network)    
    * [Mounting Secrets](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#mounting-secrets)
    * [Mounting ConfigMaps](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#mounting-configmaps)
        * [Mounting a ConfigMap storing Spark Configuration Files](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#mounting-a-configmap-storing-spark-configuration-files)
        * [Mounting a ConfigMap storing Hadoop Configuration Files](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#mounting-a-configmap-storing-hadoop-configuration-files)
    * [Mounting Volumes](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#mounting-volumes)
    * [Using Secrets As Environment Variables](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#using-secrets-as-environment-variables)
    * [Using Image Pull Secrets](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#using-image-pull-secrets)
    * [Using Pod Affinity](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#using-pod-affinity)
    * [Using Tolerations](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#using-tolerations)
    * [Using Pod Security Context](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#using-pod-security-context)
    * [Using Sidecar Containers](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#using-sidecar-containers)
    * [Using Init-Containers](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#using-init-containers)
    * [Using Volume For Scratch Space](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#using-volume-for-scratch-space)
    * [Using Termination Grace Period](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#using-termination-grace-period)
    * [Using Container LifeCycle Hooks](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#using-container-lifecycle-hooks)
    * [Python Support](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#python-support)
    * [Monitoring](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#monitoring)
    * [Dynamic Allocation](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#dynamic-allocation)
* [Working with SparkApplications](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#working-with-sparkapplications)
    * [Creating a New SparkApplication](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#creating-a-new-sparkapplication)
    * [Deleting a SparkApplication](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#deleting-a-sparkapplication)
    * [Updating a SparkApplication](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#updating-a-sparkapplication)
    * [Checking a SparkApplication](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#checking-a-sparkapplication)
    * [Configuring Automatic Application Restart and Failure Handling](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#configuring-automatic-application-restart-and-failure-handling)
    * [Setting TTL for a SparkApplication](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#setting-ttl-for-a-sparkapplication)
* [Running Spark Applications on a Schedule using a ScheduledSparkApplication](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#running-spark-applications-on-a-schedule-using-a-scheduledsparkapplication)
* [Enabling Leader Election for High Availability](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#enabling-leader-election-for-high-availability)
* [Enabling Resource Quota Enforcement](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#enabling-resource-quota-enforcement)
* [Running Multiple Instances Of The Operator Within The Same K8s Cluster](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#running-multiple-instances-of-the-operator-within-the-same-k8s-cluster)
* [Customizing the Operator](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#customizing-the-operator)
* [Using Spark Operator with Volcano](#using-spark-operator-with-volcano)

**IMPORTANT**: It is recommended to use the following property in all spark applications:

```yaml
spec:
...
  sparkConf:
...
    "spark.jars.ivy": "/tmp/.ivy"
```

The application might work without this property, but it is required for successful execution in some clouds. Hence, to avoid problems with migration between clouds, it is recommended to always set it.

## Spark Application on Kubernetes

Qubership-spark-on-k8s includes Kubeflow Spark operator chart as a subchart. The Kubeflow Spark operator uses Kubernetes objects of `SparkApplication` custom resource type to run and manage the Spark applications. The application specification is described in the YAML file and submitted to Kubernetes.

To run a Spark application on Kubernetes:

1. Prepare a docker image of application.  
   The following images can be used as parent docker images: ghcr.io/netcracker/qubership-spark-customized, qubership-spark-customized-py.
   
   Parent images define a user with id=185.  
   The Kubeflow Spark operator provides an ability to set up security context for the driver and executor pods.
                                                                                                
       driver:
         securityContext:
          runAsUser: 185
       executor:
         securityContext:
           runAsUser: 185
                                                                                                ```
   **Note**: A mutating admission webhook is needed to use this feature.
   
For more information on how to enable the mutating admission webhook, see [Quick Start Guide](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/quick-start-guide.md).

2. Prepare a `SparkApplication` specification and store it in the YAML file.  
   Following is an example of a `SparkApplication` specification and description of main parameters.
   
   ```yaml
   apiVersion: "sparkoperator.k8s.io/v1beta2"
   kind: SparkApplication
   metadata:
     name: spark-pi
     namespace: spark-apps-gcp
   spec:
     type: Scala
     mode: cluster
     image: "ghcr.io/netcracker/qubership-spark-customized:main"
     imagePullPolicy: Always
     mainClass: org.apache.spark.examples.SparkPi
     mainApplicationFile: "local:///opt/spark/examples/jars/spark-examples_2.13-4.0.1.jar"
     sparkVersion: "4.0.1"
     restartPolicy:
       type: Never
     driver:
       cores: 1
       coreLimit: "1200m"
       memory: "512m"
       labels:
         version: 4.0.1
       serviceAccount: sparkoperator-spark
     executor:
       cores: 1
       instances: 1
       memory: "512m"
       labels:
         version: 4.0.1
   ```
   **Note**: It is possible to add labels to the CR. For example, for Qubership Cloud release recommends adding the following labels to the CR:
   
   ```yaml
   ...
   kind: SparkApplication
   ...
   metadata:
   ...
     labels:
       app.kubernetes.io/processed-by-operator: spark-operator
       app.kubernetes.io/managed-by: the-tool-used-to-create-this-cr
   ```
### Support for Read-Only Root Filesystem

If the `TRUST_CERTS_DIR` environment variable is specified, certificates will be imported to `/java-security/cacerts`. Hence, a writable volume such as an emptyDir should be mounted with path `/java-security/` to support Read only Root filesystem.

Configuration Steps:

Define the Writable Volumes: Mount an emptyDir volume to a path `/java-security` and another emptyDir volume to a path `/tmp`.

```YAML
spec:
  volumes:
     - name: common-volume
         emptyDir: {}
     - name: java-cacerts-dir
         emptyDir: {}
  driver:
    volumeMounts:
      - name: common-volume
        mountPath: /tmp
        subPath: tmp
      - name: java-cacerts-dir     
        mountPath: /java-security
        subPath: java-security
    env:
       - name: TRUST_CERTS_DIR
         value: /spark/customcerts    
   executor:
     volumeMounts:
       - name: common-volume
         mountPath: /tmp
         subPath: tmp
       - name: java-cacerts-dir     
         mountPath: /java-security
         subPath: java-security
     env:
       - name: TRUST_CERTS_DIR
         value: /spark/customcerts               
```

#### Main Parameters of Application

The full list of parameters can be found in the GCP Spark operator [api-docs](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/api-docs.md).

|Parameter|Description|
|---|---|
|apiVersion|"sparkoperator.k8s.io/v1beta2"|
|kind|SparkApplication|
|metadata.name|The application name.|
|metadata.namespace|The Kubernetes namespace intended for the Spark application submission. It is configured during the deployment.|
|spec.type|The type of the Spark application. For example, Scala, Java, Python, or R.|
|spec.mode|The deployment mode of the Spark application.|
|spec.image|The docker image of the Spark application.|
|spec.imagePullPolicy|The image pull policy for the driver, executor, and init-container.|
|spec.mainClass|The fully-qualified main class of the Spark application. This only applies to Java/Scala Spark applications.|
|spec.sparkVersion|The version of Spark the application uses.|
|spec.sparkConf|SparkConf carries user-specified Spark configuration properties as they would use the “–conf” option in spark-submit.|
|spec.restartPolicy.type|The policy on if and in which conditions the controller should restart an application - OnFailure/Never/Always|
|spec.driver|The driver specification.|
|spec.driver.serviceAccount|The name of the custom Kubernetes service account used by the pod.|
|spec.executor|The executor specification.|
|spec.executor.instances|The number of executor instances.|
|spec.batchSchedulerOptions.priorityClassName|Priority class name for spark applications.|

---
#### NOTE ServiceAccount

The driver pod by default uses the `default` service account in the namespace it is running in to talk to the Kubernetes API server. The default service account, however, may or may not have sufficient permissions to create executor pods and the headless service used by the executors to connect to the driver. If it does not have the permissions, a custom service account that has the right permissions should be used instead. The optional field `.spec.driver.serviceAccount` can be used to specify the name of the custom service account.  

The service account is created during the operator deployment. The name of the service account depends on the helm release name of the operator.

For more information, refer to the original documents: [writing-driver-specification](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#writing-driver-specification).

## Spark Application Dependencies

As the Spark documentation ([Spark 3.4.1 on Kubernetes](https://spark.apache.org/docs/3.4.1/running-on-kubernetes.html#dependency-management), [Spark 3.0.0 on Kubernetes](https://spark.apache.org/docs/3.0.0/running-on-kubernetes.html#dependency-management), [Spark 2.4.5 on Kubernetes](https://spark.apache.org/docs/2.4.5/running-on-kubernetes.html#dependency-management)) suggests, the dependencies can be referred to by their remote URL or can be pre-mounted into custom-built Docker images.  
Those dependencies can be added to the classpath by referencing them with local:// URIs and/or setting the SPARK_EXTRA_CLASSPATH environment variable in the Dockerfiles.

**Note**: Currently, the URL approached dependencies do not work properly for the Spark Operator.

For more information on Spark Operator dependencies, refer to [https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#specifying-application-dependencies](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#specifying-application-dependencies).

## Environment Variables in Spark since 3.3.2

In the latest community operator version, sometimes it is possible to encounter a bug with the passing environment variables from secrets in the applications. For more information, refer to [https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/issues/1229](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/issues/1229). As a WA, you can pass environment variables as shown in the following example:

```yaml
spec:
  driver:
    envSecretKeyRefs:
      YOUR_CUSTOM_DRIVER_ENV_1:
        name: your_first_secret
        key: SECRET_KEY_1
      YOUR_CUSTOM_DRIVER_ENV_2:
        name: your_second_secret
        key: SECRET_KEY_2
...
  executor:
    envSecretKeyRefs:
      YOUR_CUSTOM_EXECUTOR_ENV_1:
        name: your_second_secret
        key: SECRET_KEY_3
```

## Executor Statuses upon Driver Completion

When the driver completes, it kills the executors. Due to this, the executors might end up being in an incorrect state. To avoid this, it is possible to use the following:

```yaml
...
spec:
...
  sparkConf:
    spark.kubernetes.executor.deleteOnTermination: 'false'
...
```

This property tells the driver not to delete the executors upon completion.

## Integration with S3 Storage

Spark provides an ability to work with S3 storage. For more information, refer to the official Spark documentation at [https://spark.apache.org/docs/3.4.1/cloud-integration.html](https://spark.apache.org/docs/3.4.1/cloud-integration.html).  

To work with S3 storage:

1. Prepare a docker image for the Spark application. For details see [Spark Application on Kubernetes](#spark-application-on-kubernetes).  
   Spark uses Hadoop libs to work with S3. Hadoop 3 is required for proper work, hence a Spark docker image with Hadoop 3 should be used as a base image for the Spark application.
   
2. Configure an S3A connector for the Spark application to use the S3 storage.  
   Properties are set in the Hadoop configuration section of the `SparkApplication` yaml file. Refer to the Spark Operator documentation for Hadoop configuration for more details at [https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/master/docs/user-guide.md#specifying-hadoop-configuration](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/master/docs/user-guide.md#specifying-hadoop-configuration).  
   
   Following is an example of the S3 configuration using `hadoopConf`:

   ```yaml
   spec:
     hadoopConf:
       "fs.s3a.endpoint": http://ypur.s3.endpoint.address.com
       "fs.s3a.impl": org.apache.hadoop.fs.s3a.S3AFileSystem
       "fs.s3a.connection.ssl.enabled": "false"
       "fs.s3a.path.style.access": "true"
       "fs.s3a.committer.magic.enabled": "false"
       "fs.s3a.committer.name": directory
       "fs.s3a.committer.staging.abort.pending.uploads": "true"
       "fs.s3a.committer.staging.conflict-mode": append
       "fs.s3a.connection.timeout": "200000"
   ``` 
   
   The rest of the other properties are described in the following links:

   * https://hadoop.apache.org/docs/current/hadoop-aws/tools/hadoop-aws/index.html
   * https://hadoop.apache.org/docs/r3.3.2/hadoop-aws/tools/hadoop-aws/committers.html
   
3. Configure S3 storage credentials.
   S3 storage access key and secret key can be added to `hadoopConf`, but it is **not secure**:
   
   ```yaml
   spec:
     hadoopConf:
       "fs.s3a.endpoint": http://your.s3.endpoint.qubership.com
       "fs.s3a.access.key": minioaccesskey
       "fs.s3a.secret.key": miniosecretkey
   ```
   
   To secure the credentials, store the access and secret keys in a Kubernetes Secret and refer to them in the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables, respectively.
   
   Example of Kubernetes Secret yaml:
   
   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: s3-cred
   type: Opaque
   data:
     ## Access Key for MinIO, base64 encoded (echo -n 'minioaccesskey' | base64)
     accesskey: bWluaW9hY2Nlc3NrZXk=
     ## Secret Key for MinIO, base64 encoded (echo -n 'miniosecretkey' | base64)
     secretkey: bWluaW9zZWNyZXRrZXk=
   ```
   
   The environment variables, `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, should be set for the application's driver and executor pods:

   ```yaml
   driver:
     envSecretKeyRefs:
       AWS_ACCESS_KEY_ID:
         name: aws-s3-credentials
         key: AWS_ACCESS_KEY_ID
       AWS_SECRET_ACCESS_KEY:
         name: aws-s3-credentials
         key: AWS_SECRET_ACCESS_KEY
   executor:
     envSecretKeyRefs:
       AWS_ACCESS_KEY_ID:
         name: aws-s3-credentials
         key: AWS_ACCESS_KEY_ID
       AWS_SECRET_ACCESS_KEY:
         name: aws-s3-credentials
         key: AWS_SECRET_ACCESS_KEY
   ```

# Using Spark Operator with Volcano

For more information about Volcano, refer to the _Official Volcano Documentation_ at [https://volcano.sh/en/](https://volcano.sh/en/).

## Spark Operator Installation Prerequisites

For Spark Operator to take use of Volcano scheduler, it is necessary to install Spark Operator after Volcano installation with the following parameters:

```yaml
webhook:
  enable: true
controller:
  batchScheduler:
    enable: true
```

Or, in qubership-spark-on-k8s chart:

```yaml
spark-operator:
    webhook:
      enable: true
    controller:
      batchScheduler:
        enable: true
```

## Post Installation Configuration

The post-installation configurations are specified below.

### Creating Queues

It is possible to create Volcano Queues with CR objects that must be applied to a Kubernetes cluster, for example:

```yaml
apiVersion: scheduling.volcano.sh/v1beta1
kind: Queue
metadata:
  name: sparkqueue1
spec:
  reclaimable: true
  weight: 1
  capability:
    cpu: "3"
    memory: "3G"
```

For more information about creating and configuring Volcano queues, refer to the _Volcano Documentation_ at [https://volcano.sh/en/docs/queue/](https://volcano.sh/en/docs/queue/).

### Submitting Spark Application

After creating a queue and with Spark Operator installed, it should be possible to submit a Spark application for the queue. In the application, the following parameters must be specified:

```yaml
spec:
...
  batchScheduler: "volcano"
  batchSchedulerOptions:
    queue: sparkqueue1
    resources:
        cpu: "3"
        memory: "3G"
...
```

With these parameters, Spark Operator creates a pod group that is scheduled by Volcano. For more information, refer to [https://volcano.sh/en/docs/podgroup/](https://volcano.sh/en/docs/podgroup/). 

**Note**: Before starting the application, Volcano validates that the queue has enough resources for the application by checking `spec.batchSchedulerOptions.resources` specified in the application CR, so set the parameter accordingly.

### Spark Application Example

The Spark application example is specified below.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: metricspropertiesconfigmap
  labels:
    component: config
data:
  metrics.properties: |
    *.sink.prometheusServlet.class=org.apache.spark.metrics.sink.PrometheusServlet
    *.sink.prometheusServlet.path=/metrics/prometheus
    master.sink.prometheusServlet.path=/metrics/master/prometheus
    applications.sink.prometheusServlet.path=/metrics/applications/prometheus

```

```yaml
apiVersion: "sparkoperator.k8s.io/v1beta2"
kind: SparkApplication
metadata:
  name: spark-pi-long-run-metrics1
spec:
  batchScheduler: "volcano"
  batchSchedulerOptions:
    queue: sparkqueue1
    resources:
        cpu: "3"
        memory: "3G"
  type: Scala
  mode: cluster
  image: "ghcr.io/netcracker/qubership-spark-customized:main"
  imagePullPolicy: Always
  mainClass: org.apache.spark.examples.SparkPi
  mainApplicationFile: "local:///opt/spark/examples/jars/spark-examples_2.13-4.0.1.jar"
  sparkVersion: "4.0.1"
  arguments:
    - "200"
  restartPolicy:
    type: Never
  sparkConf:
    "spark.thread.sleep": "1"
    spark.ui.prometheus.enabled: "true"
    spark.executor.processTreeMetrics.enabled: "true"
    spark.metrics.conf: "/etc/metrics/conf/metrics.properties"
  driver:
    cores: 1
    coreLimit: "1100m"
    memory: "1G"
    labels:
      version: 3.3.0
    serviceAccount: sparkoperator-spark-spark
    configMaps:
      - name: metricspropertiesconfigmap
        path: /etc/metrics/conf
  executor:
    cores: 1
    instances: 1
    memory: "1G"
    labels:
      version: 4.0.1
    configMaps:
      - name: metricspropertiesconfigmap
        path: /etc/metrics/conf
```

**Note**: When Spark Operator application pods are the only pods in the cluster that are scheduled by Volcano, it is possible to set tolerations in the Spark applications instead of using [Volcano implementation](#using-separate-kubernetes-nodes-for-pods-scheduled-by-volcano). For more information, refer to the _Official Spark Operator Documentation_ at [https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/master/docs/user-guide.md#using-tolerations](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/master/docs/user-guide.md#using-tolerations) . In this case, it is necessary to specify tolerations both for driver and executor pods separately, for example:

```yaml
...
  driver:
    tolerations:
    - key: sparkcompute
      operator: Equal
      value: execute
      effect: NoSchedule
...
  executor:
    tolerations:
    - key: sparkcompute
      operator: Equal
      value: execute
      effect: NoSchedule
...
```

