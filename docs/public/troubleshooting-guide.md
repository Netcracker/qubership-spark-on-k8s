This guide lists the troubleshooting techniques and known issues of the Spark Operator.

# Explore Logs

* You can find the Spark Operator logs in the operator's pod logs.
* You can find the Spark application logs in the driver's and executor's logs, whose pods are located in the application namespace specified by the `.Values.spark-operator.spark.jobNamespaces` parameter during the Spark Operator deployment.
* When the application fails to submit or run, the Spark Operator adds logs into the application custom resource description.

  To get the logs, either navigate to the application CR using Kubernetes user interface or use the following `kubectl` command: 

  ```
   kubectl describe sparkapplication.sparkoperator.k8s.io <spark_application_name> --namespace <applications_namespace>
  ```

* The `attach_log` parameter of the Airflow `SparkKubernetesSensor` allows appending a Spark application driver pod's logs to the sensor log.  
  The application logs are rendered in the task of `SparkKubernetesSensor` when the application fails or completes successfully.

# Spark User Interface

Apache Spark provides a suite of web user interfaces (Jobs, Stages, Tasks, Storage, Environment, Executors, and SQL) that can be used to monitor the status, resource consumption, and troubleshooting of your Spark application.  
For more details, refer to the _Apache Spark_ official documentation at [https://spark.apache.org/docs/4.0.1/web-ui.html#streaming-dstreams-tab](https://spark.apache.org/docs/4.0.1/web-ui.html#streaming-dstreams-tab).

To enable the Spark user interface for applications, the Spark Operator should be deployed with the following properties:

```
uiService: true #enabled by default
ingressUrlFormat: "{{$appName}}-ui-svc.your.cloud.qubership.com" #should be set according to the cluster's ingress url routing rules
```

Kubernetes service and ingress are created automatically for each application submitted to the Spark Operator.

# Known Issues

* Getting `java.nio.file.AccessDeniedException` in driver's or executor's pod logs.  
  
  *Example of stacktrace:*

  ```
  Caused by: java.nio.file.AccessDeniedException: ./smart-event-stream-processor-app-1.1.5.2-SNAPSHOT.jar
      at sun.nio.fs.UnixException.translateToIOException(UnixException.java:84)
      at sun.nio.fs.UnixException.rethrowAsIOException(UnixException.java:102)
      at sun.nio.fs.UnixException.rethrowAsIOException(UnixException.java:107)
      at sun.nio.fs.UnixCopyFile.copyFile(UnixCopyFile.java:243)
      at sun.nio.fs.UnixCopyFile.copy(UnixCopyFile.java:581)
      at sun.nio.fs.UnixFileSystemProvider.copy(UnixFileSystemProvider.java:253)
      at java.nio.file.Files.copy(Files.java:1274)
      at org.apache.spark.util.Utils$.org$apache$spark$util$Utils$$copyRecursive(Utils.scala:664)
      at org.apache.spark.util.Utils$.copyFile(Utils.scala:635)
      at org.apache.spark.util.Utils$.fetchFile(Utils.scala:502)
  ``` 
 
  *Root cause*:

  The driver or executor pod is running under a user that has no access to the file mentioned in the error stacktrace.  
  Most probably, the Spark application `dockerfile` user is the `root` user, but the driver/executor is running under the `non-root` user.

  *Solution*:  
  
  The application's `dockerfile` should always set a `USER`. For more information, refer to [https://docs.docker.com/engine/reference/builder/#user](https://docs.docker.com/engine/reference/builder/#user).  
  In the Spark application's `dockerfile`, use `chown` and `chmod` commands to set the user that is to be used for the driver or executor access to the file mentioned in the error stacktrace.

* Spark application pods are not getting patched by admission webhook. `webhook.go:247] Serving admission request` line is not present in the spark operator log.

  *Solution*:

  Check spark operator resources, more than 1CPU/1GB of resources may be needed.

* CRD Validation Error When Applying SparkApplication CRD
 When applying the CustomResourceDefinition (CRD) for sparkapplications.sparkoperator.k8s.io, and sparkoperator.k8s.io_scheduledsparkapplications users might encounter the following error:
  The CustomResourceDefinition "sparkapplications.sparkoperator.k8s.io" is invalid:
  metadata.annotations: Too long: must have at most 262144 bytes
   spec.preserveUnknownFields: Invalid value: true: must be false in order to use defaults in the schema 

  *Cause*:

  This happens because the CRD manifest contains large annotations (often from Helm or ArgoCD metadata) that exceed the Kubernetes limit of 262144 bytes. Additionally, Kubernetes 1.22+ requires spec.preserveUnknownFields to be false to allow the use of default values in the OpenAPI schema.

  *Solution*:
  
  To bypass this issue, apply the CRD using `--server-side=true` which skips the client-side size validation.

* MD 5 error when connecting to minio s3.

  *Cause*:

  Old minio version, see github.com/minio/minio/issues/20845 and https://github.com/aws/aws-sdk-java-v2/discussions/5802

  *Solution*:

  Update minio version. It also might be necessary to set AWS java SDK v2 properties `RequestChecksumCalculation` and `ResponseChecksumValidation` to `WHEN_REQUIRED`.

