The following section provide the monitoring comparison of the Spark Operator.

### Per Application Metrics Gathering Variants

|   |Spark Native Monitoring Graphite | Spark Native Monitoring Prometheus | Spark Operator Native Monitoring(jmx exporter) | spark-metrics/PrometheusSink (separate project) |
|---|---|---|---|---|
|Spark 2 batch jobs standalone Hadoop|Supported|Not Supported|Not Supported|Supported (requires prometheus push)|
|Spark 3 batch jobs standalone Hadoop|Supported|Supported, but prometheus does not know where to scrape and applications need to be long enough for prometheus to scrape.|Not Supported|Supported (requires prometheus push)|
|Spark 2 batch jobs Operator|Supported|Not Supported|Supported, but applications need to be long enough for prometheus to scrape.|Supported (requires prometheus push)|
|Spark 3 batch jobs Operator|Supported|Supported, but applications need to be long enough for prometheus to scrape.|Supported, but applications need to be long enough for prometheus to scrape.|Supported (requires prometheus push)|
|Spark 3 streaming jobs standalone Hadoop|Supported|Supported, but prometheus does not know where to scrape.|Not Supported|Supported (requires prometheus push)|
|Spark 3 streaming jobs Operator|Supported|Supported|Supported|Supported (requires prometheus push)|

### Required Additional Configurations

||Spark Native Monitoring Graphite|Spark Native Monitoring Prometheus|Spark Operator Native Monitoring(jmx exporter)|spark-metrics/PrometheusSink (separate project)|
|---|---|---|---|---|
|Standalone Hadoop|`metrics.properties` with graphite configuration to $SPARK_HOME/conf on standalone Hadoop nodes.|`metrics.properties` with prometheus configuration to $SPARK_HOME/conf on standalone Hadoop nodes.|Not Supported|Additional JAR and `metrics.properties` configured to use this jar.|
|Airflow (when job is launched from Airflow)|`metrics.properties` with graphite configuration to $SPARK_HOME/conf in airflow worker pods.|`metrics.properties` with prometheus configuration to $SPARK_HOME/conf in airflow worker pods and additional parameters in spark-submit.|Not Supported|Additional JAR in pod and `metrics.properties` configured to use this jar.|
|CR/Docker (when job is executed in Kubernetes)|Mount `metrics.properties` with graphite configuration as a configmap and use it in the application CR.|Mount `metrics.properties` with prometheus configuration as a configmap and use it in the application CR, also specify `sparkConf`.|Add jmx exporter to dockerfile, configure the CR to use it.|Additional JAR in application images, `metrics.properties` configmap to use the jar.|
|Additional configuration|Graphite exporter and Prometheus to scrape the exporter.|Prometheus needs to be configured to scrape driver/executor endpoints (not supported in the operator).|Prometheus needs to be configured to scrape driver/executor endpoints since `prometheus.io/path: /metrics` annotations are not supported in platform monitoring.|Platform monitoring needs to support Prometheus push.|