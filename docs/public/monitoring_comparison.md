The following section briefly describes how to configure the spark prometheus endpoints in the application run by the Spark Operator in Kubernetes. 

# Enabling Spark Native Monitoring Prometheus in Applications Run by Spark Operator

For more information, refer to the _Official Documentation_ at [https://spark.apache.org/docs/3.0.0-preview/monitoring.html#metrics](https://spark.apache.org/docs/3.0.0-preview/monitoring.html#metrics).

Note that the guide implies that the application image includes the `pgrep` command. To add it to the debian image, it is possible to perform the following:

```shell
FROM docker pull ghcr.io/netcracker/qubership-spark-customized:main
...
ARG spark_uid=185
USER root
RUN apt-get update \
    && apt-get install -y procps

USER ${spark_uid}
...
```

The Quership provided image should have `procps` installed.

If you do not need spark process tree metrics, `pgrep` is not needed.

Firstly, it is necessary to specify the `metrics.properties` file for spark-submit. The file content must be as follows:

```properties
*.sink.prometheusServlet.class=org.apache.spark.metrics.sink.PrometheusServlet
*.sink.prometheusServlet.path=/metrics/prometheus
master.sink.prometheusServlet.path=/metrics/master/prometheus
applications.sink.prometheusServlet.path=/metrics/applications/prometheus
```

One way to do it is through creating a configmap and mounting it into the pods. 

For example,

Configmap:

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

In the application CR,

```yaml
spec:
...
  executor:
    configMaps:
      - name: metricspropertiesconfigmap
        path: /etc/metrics/conf
...
  driver:
    configMaps:
      - name: metricspropertiesconfigmap
        path: /etc/metrics/conf
```

Another possible option is to add the file when building the application docker image (in this case, also ensure that the file has necessary permissions for the spark user, uid=185).

Secondly, it is necessary to transfer to `spark-submit` the following `--conf` parameters: `spark.ui.prometheus.enabled=true` and (if you need spark process tree metrics) `spark.executor.processTreeMetrics.enabled=true`. Also, it might be necessary to point `spark.metrics.conf` to where the configmap was mounted. For example, `spark.metrics.conf=/etc/metrics/conf/metrics.properties`. In the application CR, it is possible to do it by specifying `spec.sparkConf`. For example, 

```yaml
...
spec:
  sparkConf:
    spark.ui.prometheus.enabled: "true"
    spark.executor.processTreeMetrics.enabled: "true"
    spark.metrics.conf: "/etc/metrics/conf/metrics.properties"
...
```

After applying the CR, the metrics can be found at the driver spark UI at the `/metrics/prometheus` and `/metrics/executors/prometheus` endpoints.

When using the prometheus operator to configure prometheus to scrape these endpoints, it is possible to manually add serviceMonitor or podMonitor for the driver. Note that by default, the driver pod is named `${application-name}-driver` and the service is named `${application-name}-ui-svc`. The default port is 4040.  
**Note** that to automate UI services and ports creation, the Spark Operator should be deployed with `uiService` and `ingressUrlFormat` specified.
See [Spark User Interface](/docs/troubleshooting-guide.md#spark-ui) section for details.  

An example of serviceMonitor for the `spark-testappname` application is given below:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: spark-testappname-servicemonitor
  labels:
    app.kubernetes.io/component: monitoring
spec:
  selector:
    matchLabels:
      sparkoperator.k8s.io/app-name: spark-testappname
  endpoints:
  - port: spark-driver-ui-port
    path: /metrics/executors/prometheus
    interval: 30s
  - port: spark-driver-ui-port
    path: /metrics/prometheus
    interval: 30s
```

An example of service monitor to monitor all applications at once:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app.kubernetes.io/component: monitoring
  name: spark-servicemonitor
spec:
  endpoints:
  - interval: 5s
    path: /metrics/executors/prometheus/
    port: spark-ui
  - interval: 5s
    path: /metrics/prometheus
    port: spark-ui
  selector:
    matchExpressions:
    - key: spark-app-selector
      operator: Exists 
```

## Dashboard for Grafana Applications

When deploying an operator, it is also possible to install a grafana dashboard for the spark application. In order to do so, set `grafanaApplicationDashboard.enable` to `true` in the operator deployment parameters. Note that for the dashboard to work, it is necessary to enable the application prometheus monitoring as described above.

To specify the application that you want to monitor, you can use the `Spark Application Id` variable in the grafana dashboard. 

The dashboard contains the following sections: 

* `Executors - tasks` - This section contains information about the executors' tasks. The metrics are taken from the `/metrics/executors/prometheus` application endpoint.
* `Executors - memory` - This section contains information about the executors' memory. The metrics are taken from the `/metrics/executors/prometheus` application endpoint.
* `Executors - Garbage collection` - This section contains information about the executors' Garbage collection. The metrics are taken from the `/metrics/executors/prometheus` application endpoint.
* `Executors - Cores/Disks` - This section contains information about cores and disks used. The metrics are taken from the `/metrics/executors/prometheus` application endpoint.
* `Driver Block Manager` - This section shows information about the Driver Block Manager. The metrics are taken from the `/metrics/prometheus` application endpoint.
* `DAG Scheduler` - This section shows information about the DAG Scheduler. The metrics are taken from the `/metrics/prometheus` application endpoint.
* `CPU` - This section shows information about the CPU. The metrics are taken from the `/metrics/prometheus` application endpoint.
* `Streaming` - This section shows information related to streaming. The metrics are taken from the `/metrics/prometheus` application endpoint.
* `LiveListenerBus` - This section shows the metrics provided by LiveListenerBus. The metrics are taken from the `/metrics/prometheus` application endpoint.

**Note**: This dashboard can be deployed with spark operator by setting `appServiceMonitor.enable` to `true`. It will be deployed to `.Values.spark-operator.spark.jobNamespaces` if this parameter is specified (otherwise it will be deployed to spark operator namespace).

### DR Cluster

You can select a cluster to monitor the applications on a specific DR cluster in case if the Spark Operator is deployed in the DR scheme.  
Note that an appropriate proxy datasource should be selected to enable the cluster filtration.
