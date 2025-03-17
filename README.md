## Table of Contents

* [Overview](#overview)
* [Official Documents](#official-documents)
* [Architecture](/docs/public/architecture.md)
* [Installation Guide](/docs/public/installation.md)
* [User Guide](/docs/public/user-guide.md)
* [Applications Management](/docs/public/applications-management.md)  
* [Migration Guide](/docs/public/migration-guide.md)
* [Design](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/design.md)
* [Troubleshooting Guide](/docs/public/troubleshooting-guide.md)
* [Monitoring](/docs/public/monitoring.md)
* [Spark History Server](/docs/public/spark-history-server.md)
* [Helm Chart](#helm-chart)

## Overview

This repo contains helm charts and images to run [spark](https://spark.apache.org/) on kubernetes. It is based on [Kubeflow spark operator](https://github.com/kubeflow/spark-operator). The Spark and operator images include some additional improvements, for example, to work with S3 or with certificates. Additionally, this repository includes spark-history-server, spark-thrift-server charts and test applications that use spark image. Spark history server chart and some application charts include modified [oauth2-proxy helm chart](https://github.com/oauth2-proxy/manifests) to add authentication to spark-history and application UIs.

The final helm chart for this project can be extracted from qubership-spark-on-k8s-transfer release image. Alternatively, it is possible to use [create_chart.sh](create_chart.sh) script.