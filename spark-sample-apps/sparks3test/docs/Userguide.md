Running Spark Application with S3 Connectivity

This guide explains how to run a Spark job on Kubernetes using the Spark Operator, configured to securely connect to an S3 endpoint.

## Prerequisites

Login to the S3 web console and create a bucket with name `sparktest`.
Archive the app folder, select ZIP archive while archiving.
Upload app.zip and test.json into the created bucket.
Configure s3-connection-config.yaml and s3-certificates.yaml and apply in K8s.

Configure the created S3 bucket name in the spark application at 

```yaml
 deps:
    pyFiles:
      - s3a://{S3 BUCKET}/test.JSON
  sparkConf:
    spark.archives: s3a://{S3 BUCKET}/app.zip#sparkapp     
```

## Application Code

Spark job (json_read.py) reads a JSON file from S3 and prints its content.

## SparkApplication Manifest

Below is the SparkApplication manifest (s3-connection-test.yaml) that configures the Spark Operator to run this job:

````yaml
apiVersion: sparkoperator.k8s.io/v1beta2
kind: SparkApplication
metadata:
  name: s3-connection-test
  namespace: spark-apps
spec:
  type: Python
  pythonVersion: "3"
  mode: cluster
  image: ghcr.io/netcracker/qubership-spark-customized-py:main
  imagePullPolicy: Always
  mainApplicationFile: local:////opt/spark/work-dir/sparkapp/app/json_read.py
  sparkVersion: "4.0.0"
  restartPolicy:
    type: Never
  volumes:
    - name: s3-certs-volume
      secret:
        secretName: s3-certificates
    - name: s3-connection-config-volume
      secret:
        secretName: s3-connection-config
        defaultMode: 444    
  driver:
    cores: 1
    memory: 1g
    env:
      - name: TRUST_CERTS_DIR
        value: /opt/spark/cacerts
      - name: S3_JSON_FILE
        value: /opt/spark/work-dir/test.json
      - name: HADOOP_CONF_DIR
        value: /opt/spark/s3config
      - name: SPARK_CONF_DIR
        value: /opt/spark/s3config         
    volumeMounts:
      - name: s3-certs-volume
        mountPath: /opt/spark/cacerts
        readOnly: true
      - name: s3-connection-config-volume
        mountPath: /opt/spark/s3config
        readOnly: true        
    labels:
      version: 4.0.0
    serviceAccount: sparkapps-sa
    securityContext:
      seccompProfile:
        type: RuntimeDefault
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      runAsUser: 185
      capabilities:
        drop:
          - ALL

  executor:
    cores: 1
    instances: 1
    memory: 1g
    env:
      - name: TRUST_CERTS_DIR
        value: /opt/spark/cacerts  
      - name: S3_JSON_FILE
        value: /opt/spark/work-dir/test.json
      - name: HADOOP_CONF_DIR
        value: /opt/spark/s3config
      - name: SPARK_CONF_DIR
        value: /opt/spark/s3config        
    volumeMounts:
      - name: s3-certs-volume
        mountPath: /opt/spark/cacerts
        readOnly: true
      - name: s3-connection-config-volume
        mountPath: /opt/spark/s3config
        readOnly: true          
    labels:
      version: 4.0.0
    securityContext:
      seccompProfile:
        type: RuntimeDefault
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      runAsUser: 185
      capabilities:
        drop:
          - ALL 
  deps:
    pyFiles:
      - s3a://{S3 BUCKET}/test.JSON
  sparkConf:
    spark.hadoop.fs.s3a.path.style.access: "true"
    spark.archives: s3a://{S3 BUCKET}/app.zip#sparkapp
    spark.driver.extraJavaOptions: "-Djavax.net.ssl.trustStore=/opt/spark/cacerts -Djavax.net.ssl.trustStorePassword=changeit"
    spark.executor.extraJavaOptions: "-Djavax.net.ssl.trustStore=/opt/spark/cacerts -Djavax.net.ssl.trustStorePassword=changeit"

```    

## Deployment

Apply the manifest:

kubectl apply -f s3-connection-test.yaml

## Verify Job Status

Check if the Spark job is running:

```
kubectl get sparkapplications -n spark-apps
```
Inspect the driver pod logs:

```
kubectl logs -n spark-apps <driver-pod-name>
```

You should check the JSON file content read from S3 printed in the logs.

## Summary

Secrets provide S3 certificates and access configs.

Volumes and mounts inject them into the Spark driver and executors.

Environment variables point Spark to the right config paths.

Truststore setup ensures the secure TLS communication with S3.

With this configuration, Spark Operator can run the jobs that securely connect to and read data from S3.
