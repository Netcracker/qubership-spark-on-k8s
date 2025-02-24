This section describes the details of the Spark History Server.

## Table of Contents

* [Overview](#overview)
* [Official Documents](#official-documents)
* [Docker Image](#docker-image)
* [Deployment](#deployment)
* [Enabling Applications Event Logging](#enabling-applications-event-logging)  
* [Supported Storages](#supported-storages)
  * [S3](#s3)

## Overview

The Spark application UI becomes unavailable after the Spark application's driver completes. To be able to access the application's UI, after the completion, they can be configured to the log events to be rendered by the Spark History Server.

The Spark History Server tracks completed and running Spark applications. The History server and applications should point to the same log directory.  
![alt text](/docs/public/images/spark-history-server.png "Spark History Server")

## Official Documents

You can access the official Spark documentation at [https://spark.apache.org/docs/latest/monitoring.html#viewing-after-the-fact](https://spark.apache.org/docs/latest/monitoring.html#viewing-after-the-fact).

## Docker Image

The Spark History Server is included in the Spark base image.   
The `/opt/spark/sbin/start-history-server.sh` script runs the History Server.

## Deployment

The Spark History Server deployment can be enabled by the Spark Operator GCP `spark-history-server.enable` deployment parameter.
All possible parameters are listed in a table in the [Spark History Server Subchart Deployment Parameters](/docs/public/installation.md#spark-history-server) section.

The Spark History Server has its separate helm chart. This chart is a sub-chart of the spark-on-k8s helm chart.

For more information, refer to the [Spark History Server Deployment](/docs/public/installation.md#spark-history-server) section.

## Enabling Applications Event Logging

To enable event logging, the following parameters should be set for Spark applications:

* spark.eventLog.enabled true
* spark.eventLog.dir <logDirectory>

In the application's CR file, these parameters can be set in `sparkConf` as follows.

```yaml
sparkConf:
    "spark.eventLog.enabled": "true"
    "spark.eventLog.dir": "s3a://tmp/spark/logs"
```

Note that the application should be properly configured to log an event in the specified storage.  
In case of using S3 storage, refer to [S3 Storage](/docs/public/applications-management.md#s3-storage) for application configuration details.

## Supported Storages

The Spark History Server can use S3 or HDFS as the event logs storage.  
For parameters description, refer to the [Spark History Server Subchart Deployment Parameters](/docs/public/installation.md#spark-history-server) section.

### S3

When S3 storage is used, the following parameters should be set (values are just examples).

```yaml
spark-history-server:
  logDirectory: 's3a://tmp/spark/logs'  
  s3:
    enabled: true
    endpoint: 'http://minio.address.qubership.com'
    accesskey: 'minioaccesskey'
    secretkey: 'miniosecretkey'
```