# Spark Hive Test

## Overview
This Spark application is designed to run in a Kubernetes cluster using the Spark Operator. It interacts with a Hive Metastore and reads/writes data from an S3-compatible storage.

## Deployment Details

### Kubernetes SparkApplication Configuration
The application is defined as a `SparkApplication` resource in Kubernetes, utilizing the Spark Operator (`apiVersion: sparkoperator.k8s.io/v1beta2`).

- **Application Name:** `spark-hive-test`
- **Namespace:** `spark-apps`
- **Image:** `ghcr.io/netcracker/qubership-tests-spark-hive-connection:main`
- **Spark Version:** `4.0.0`
- **Mode:** `cluster`
- **Python Version:** `3`

## Configuration
The application includes various Spark and Hadoop configurations to integrate with Hive and S3-compatible storage.

### Key Spark Configurations
- `spark.sql.warehouse.dir`: `s3a://hive/warehouse`
- `spark.sql.hive.metastore.version`: `3.1.3`
- `spark.sql.hive.metastore.jars.path`: `/opt/spark/hivejars/*`
- `spark.hadoop.hive.metastore.uris`: `thrift://hive-metastore.hive-metastore:9083`
- `spark.hadoop.fs.s3a.endpoint`: `https://test-minio.com`
- `spark.hadoop.fs.s3a.connection.ssl.enabled`: `false`
- `spark.hadoop.fs.s3a.impl`: `org.apache.hadoop.fs.s3a.S3AFileSystem`
- `spark.hadoop.fs.s3a.path.style.access`: `true`
- `spark.hadoop.fs.s3a.committer.magic.enabled`: `true`
- `spark.driver.extraJavaOptions`: `-Dcom.amazonaws.sdk.disableCertChecking`
- `spark.executor.extraJavaOptions`: `-Dcom.amazonaws.sdk.disableCertChecking`
- `spark.sql.catalogImplementation`: `hive`
- `spark.sql.legacy.createHiveTableByDefault`: `false`

### Security & Execution Context
- Runs as a non-root user (`runAsUser: 185`)
- Uses Kubernetes `seccompProfile` with `RuntimeDefault`
- Drops all privileged capabilities for security

### Kubernetes Secret for S3 Credentials
The application uses a Kubernetes Secret to securely store S3 credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: s3-secrets
  namespace: spark-apps
type: Opaque
stringData:
  AWS_ACCESS_KEY_ID: {"awsaccesskey"}
  AWS_SECRET_ACCESS_KEY: {"awssecretkey"}  
  S3_ENDPOINT_URL: {"aws endpoint url"}
```

### Init Containers
The application includes an init container to delete old S3 data before running the Spark job:

- **Name:** `delete-s3`
- **Image:** Same as the main application
- **Script:** `delete_s3.py`
- **Function:** Deletes old data from `s3://hive/warehouse/mysparkdb2.db/`
- **Environment Variables:**
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `S3_ENDPOINT_URL`
- **Security Context:** Runs as a non-root user with restricted privileges

## Environment Variables in Spark Application
The following environment variables are set within the Spark application to improve execution and suppress unnecessary warnings:

- `AWS_JAVA_V1_DISABLE_DEPRECATION_ANNOUNCEMENT=true`: Disables deprecation warnings from AWS Java SDK v1.
- `PYTHONPATH="/opt/spark/python:/opt/spark/python/lib/py4j-0.10.9.7-src.zip"`: Ensures that PySpark and Py4J dependencies are correctly resolved in the Python environment.
- `AWS_ACCESS_KEY_ID`: AWS accesskey referenced from s3_secrets to connect to S3 endpoint
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key referenced from s3_secrets to connect to S3 endpoint

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
