# Spark Hive Test

## Overview
This Spark application is designed to run in a Kubernetes cluster using the Spark Operator. It interacts with a Hive Metastore and reads/writes data from an S3-compatible storage.

## Deployment Details

### Kubernetes SparkApplication Configuration
The application is defined as a `SparkApplication` resource in Kubernetes, utilizing the Spark Operator (`apiVersion: sparkoperator.k8s.io/v1beta2`).

- **Application Name:** `spark-hive-test`
- **Namespace:** `spark-apps`
- **Image:** `ghcr.io/netcracker/qubership-tests-spark-hive-connection:main`
- **Spark Version:** `4.0.2`
- **Mode:** `cluster`
- **Python Version:** `3`

## Configuration
The application includes various Spark and Hadoop configurations to integrate with Hive and S3-compatible storage.

### Key Spark Configurations
    "spark.jars.ivy": "/tmp/.ivy"
    # --- Hive Metastore Config ---
    "spark.sql.hive.metastore.version": "4.0.1"
    "spark.sql.hive.metastore.jars": "path"
    "spark.sql.hive.metastore.jars.path": "/opt/spark/hivejars/*"
    "spark.hadoop.hive.metastore.uris": "thrift://hive-metastore.hive-metastore:9083"
    "spark.hadoop.hive.metastore.schema.verification": "false"
    "spark.hadoop.hive.metastore.schema.verification.record.version": "false"
    "spark.sql.catalogImplementation": "hive"
    "spark.sql.legacy.createHiveTableByDefault": "false"
    "spark.sql.streaming.fileSource.log.deletion": "false"
    "spark.sql.sources.commitProtocolClass": "org.apache.spark.internal.io.cloud.PathOutputCommitProtocol"
    "spark.hadoop.mapreduce.outputcommitter.factory.scheme.s3a": "org.apache.hadoop.fs.s3a.commit.S3ACommitterFactory"
    # --- Hive TLS config ---
    "spark.hadoop.hive.metastore.use.SSL": "true"
    "spark.hadoop.hive.metastore.truststore.path": "/java-security/cacerts"
    "spark.hadoop.hive.metastore.truststore.password": "changeit"
    # --- S3A / MinIO Core Config ---
    "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem"
    "spark.hadoop.fs.s3a.path.style.access": "true"
    "spark.hadoop.fs.s3a.fast.upload": "true"
    "spark.hadoop.fs.s3.buckets.create.enabled": "true"
    "spark.hadoop.fs.s3a.metadatastore.authoritative": "true"
    "spark.hadoop.fs.s3a.committer.magic.enabled": "true"
    "spark.hadoop.fs.s3a.committer.name": "magic"
    "spark.sql.parquet.output.committer.class": "org.apache.spark.internal.io.cloud.BindingParquetOutputCommitter"
    # ---S3 TLS config ---
    "spark.hadoop.fs.s3a.connection.ssl.enabled": "true"
    # --- Logs and Timeouts ---
    "spark.kubernetes.submission.connectionTimeout": "60000000"
    "spark.kubernetes.submission.requestTimeout": "60000000"
    "spark.driver.extraJavaOptions": "-Djavax.net.ssl.trustStore=/java-security/cacerts -Djavax.net.ssl.trustStorePassword=changeit -Dcom.amazonaws.sdk.disableCertChecking --add-modules jdk.incubator.vector -Dlog4j2.logger.fileStreamSink.name=org.apache.spark.sql.execution.streaming.FileStreamSink -Dlog4j2.logger.fileStreamSink.level=error"
    "spark.executor.extraJavaOptions": "-Djavax.net.ssl.trustStore=/java-security/cacerts -Djavax.net.ssl.trustStorePassword=changeit -Dcom.amazonaws.sdk.disableCertChecking --add-modules jdk.incubator.vector -Dlog4j2.logger.fileStreamSink.name=org.apache.spark.sql.execution.streaming.FileStreamSink -Dlog4j2.logger.fileStreamSink.level=error"

### Security & Execution Context
- Runs as a non-root user (`runAsUser: 185`)
- Uses Kubernetes `seccompProfile` with `RuntimeDefault`
- Drops all privileged capabilities for security

### Kubernetes Secret for S3 Credentials
The application uses a pre created Kubernetes Secret to securely store S3 credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: s3-secrets
  namespace: spark-apps
type: Opaque
stringData:
  AWS_ACCESS_KEY_ID: {minioaccesskey}
  AWS_SECRET_ACCESS_KEY: {miniosecretkey}
  S3_ENDPOINT_URL: {minio url}
  BUCKET_NAME: {bucket name}
  DB_NAME: {database name}
  TABLE_NAME: {table name}
```
### Kubernetes secret for S3 Certificates
The application uses a pre created Kuberenetes Secret to securely store S3 and Hive Metastore TLS certificates

```yaml
kind: Secret
apiVersion: v1
metadata:
  name: ca-certificates
  namespace: spark-apps
type: Opaque
stringData:
  hive.pem: |
    -----BEGIN CERTIFICATE-----
    hive metastore certificate content
    -----END CERTIFICATE-----
  s3.pem: |
    -----BEGIN CERTIFICATE-----
    s3 certificate content
    -----END CERTIFICATE----- 
```

### Init Containers
The application includes an init container to delete old S3 data before running the Spark job:

- **Name:** `delete-s3`
- **Image:** Same as the main application
- **Script:** `delete_s3.py`
- **Function:** Deletes old data from `s3://hive/warehouse/mysparkdb2.db/`
- **Security Context:** Runs as a non-root user with restricted privileges

## Hive Metastore and S3 TLS support
Add the follwing configuration to spark application to connect to Hive Metastore and S3 storage securely.

```yaml
volumes:
  - name: ca-certificates
      secret:
        secretName: ca-certs
# The following should be added to driver, initcontainer, and executor
volumeMounts:
  - name: ca-certificates
    mountPath: "/certs/trust"
    readOnly: true 
env:
  - name: TRUST_CERTS_DIR
    value: /certs/trust               
```


## Environment Variables in Spark Application
The following environment variables are set within the Spark application to import certificates:

- `TRUST_CERTS_DIR`: Stores certificates 


## Restart Policy
The application will not restart automatically but has retry mechanisms in place:
- **On Failure:** 3 retries, 10-second interval
- **On Submission Failure:** 5 retries, 20-second interval

## Running the Application
To deploy the Spark job in Kubernetes:
```sh
kubectl apply -f spark-hive-test.yaml
```
To check the status:
```sh
kubectl get sparkapplications -n spark-apps
```
To view logs:
```sh
kubectl logs -f <driver-pod-name> -n spark-apps
```

## Notes
- Ensure that the required Hive Metastore and S3 storage are accessible.
- Spark and Hadoop configurations must match the infrastructure setup.
- Security settings comply with best practices to minimize risks.

## Troubleshooting
If the Spark job fails to connect to Hive Metastore, verify:
- The metastore URI is correct and accessible.
- Hive schema verification is disabled (`spark.hadoop.hive.metastore.schema.verification=false`).

For S3 connection issues, check:
- The endpoint, access key, and secret key settings.
- SSL settings (`spark.hadoop.fs.s3a.connection.ssl.enabled=false`).

## Expected Output
The expected output of the application, as seen in the logs, is:

```
+---+--------+
| id|    name|
+---+--------+
|  4|Jennifer|
|  1|   James|
|  3|    Jeff|
|  2|     Ann|
+---+--------+
```
