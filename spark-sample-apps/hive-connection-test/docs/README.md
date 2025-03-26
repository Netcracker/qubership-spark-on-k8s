# Spark Hive Test

## Overview
This Spark application is designed to run in a Kubernetes cluster using the Spark Operator. It interacts with a Hive Metastore and reads/writes data from an S3-compatible storage.

## Deployment Details

### Kubernetes SparkApplication Configuration
The application is defined as a `SparkApplication` resource in Kubernetes, utilizing the Spark Operator (`apiVersion: sparkoperator.k8s.io/v1beta2`).

- **Application Name:** `spark-hive-test`
- **Namespace:** `spark-apps`
- **Image:** `ghcr.io/netcracker/qubership-tests-spark-hive-connection:main`
- **Spark Version:** `3.5.3`
- **Mode:** `cluster`
- **Python Version:** `3`

## Configuration
The application includes various Spark and Hadoop configurations to integrate with Hive and S3-compatible storage.

### Key Spark Configurations
- `spark.sql.warehouse.dir`: `s3a://hive/warehouse`
- `spark.sql.hive.metastore.version`: `3.1.3`
- `spark.sql.hive.metastore.jars.path`: `/opt/spark/hivejars/*`
- `spark.hadoop.hive.metastore.uris`: `thrift://127.0.0.0:31663`
- `spark.hadoop.fs.s3a.endpoint`: `https://test-minio.com`
- `spark.hadoop.fs.s3a.access.key`: `minioaccesskey`
- `spark.hadoop.fs.s3a.secret.key`: `miniosecretkey`

### Security & Execution Context
- Runs as a non-root user (`runAsUser: 185`)
- Uses Kubernetes `seccompProfile` with `RuntimeDefault`
- Drops all privileged capabilities for security

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
