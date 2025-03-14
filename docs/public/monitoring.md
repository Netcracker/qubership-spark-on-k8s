This section describes the Spark Operator monitoring.

# Table of Contents

* [Grafana Dashboard](#grafana-dashboard)  
* [Prometheus Rules](#prometheus-rules)


# Grafana Dashboard

This chapter describes Spark Operator monitoring dashboard.
To access the dashboard:

![Dashboard Variables](/docs/public/images/operator_dashboard_variables.png)

1. Navigate to the Grafana server and log in using the provided credentials.
1. Select the Spark Operator dashboard.
1. Select the `namespace`. 
1. Select the operator's `pod`.
1. Select the time range.

## DR Cluster

A cluster can be selected to monitor metrics on a specific DR cluster in case if the Spark Operator is deployed in the DR scheme.  
Note that an appropriate proxy datasource should be selected to enable cluster filtration.

## Metrics

* [Spark Operator Overview](#operator-overview)
* [Spark History Server Overview](#history-server-overview)
* [Spark Applications](#spark-applications)
* [Work Queue Metrics](#work-queue-metrics)
* [CPU](#cpu-usage) 
* [Memory](#memory-usage)
* [Disk](#disk-space-usage)
* [Network](#network)

### Operator Overview

This section describes the Spark Operator overall state.

![Operator Overview](/docs/public/images/operator_overview.png)

#### Operator Status

This displays the Spark Operator's health status (including controller and webhook pods).  
In case of several replicas, the status is 'UP' if one of the pods is in the 'Running' phase.  
This approach is based on the fact that only one of the replicas is always active.

If Spark History Server is deployed, it affects the status of the Spark Operator. Unhealthy History Server makes the Spark Operator state 'Degraded'.

#### Active Controller Replicas

This displays the number of the Spark Operator Controller running pods.  
Only one pod, which is the leader, is active.

#### Pods Count

This displays the number of spark operator pods in the namespace (including webhook and controller).

#### Pod Status

This displays the status of the pod.

The possible values are:

* Failed
* Pending
* Running
* Succeeded
* Unknown

#### Container Restart

This displays the number of each container restarts in the pod.

### History Server Overview

If History Server is installed, this section describes the overall state of the Spark History Server.

![History Server Overview](/docs/public/images/history_server_overview.png)

#### Spark History Server Status

This displays the Spark History Server's health status. 

#### Replicas Count

This displays the number of the Spark History Server's running pods.  

#### Pods Count

This displays the number of History Server related pods in the namespace.

#### Pod Status

This displays the status of the pods related to the History Server.

The possible values are:

* Failed
* Pending
* Running
* Succeeded
* Unknown

#### Container Restart

This displays the number of each container restarts in the pod.

### Spark Applications

This displays the Spark applications' overall metrics.

![Spark Applications](/docs/public/images/spark_applications.png)

#### Total Apps Count

This displays the total number of Spark applications handled by the Spark Operator.  
The value is reset to 0 after the Spark Operator restarts. The restarts are displayed on a graph area of the panel by the line going to 0. 

#### Number of Submitted Apps

This displays the total number of Spark applications submitted by the Spark Operator.  
The value is reset to 0 after the Spark Operator restarts. The restarts are displayed on a graph area of the panel by the line going to 0.

#### Running Apps Count

This displays the total number of Spark applications that are currently running.  

#### Running Executors Count

This displays the total number of Spark Executors that are currently running.  

#### Number of Failed Apps

This displays the total number of Spark applications that failed to complete.  
The value is reset to 0 after the Spark Operator restarts. The restarts are displayed on a graph area of the panel by the line going to 0.

#### Number of Successfully Completed Apps

This displays the total number of Spark applications that completed successfully.  
The value is reset to 0 after the Spark Operator restarts. The restarts are displayed on a graph area of the panel by the line going to 0.

#### Executors Completed Successfully

This displays the total number of Spark executors that completed successfully.  
The value is reset to 0 after the Spark Operator restarts. The restarts are displayed on a graph area of the panel by the line going to 0.

#### Failed Executors Count

This displays the total number of Spark executors that failed.  
The value is reset to 0 after the Spark Operator restarts. The restarts are displayed on a graph area of the panel by the line going to 0.

### Spark Applications Timing Metrics


![Spark Applications Timing Metrics](/docs/public/images/spark-applications-timing-metrics.png)

#### Average startup latency of Applications 

This displays the `average startup latency of applications`in seconds.

#### Average execution time of failed applications 

This displays the `average execution time of failed applications`in seconds.

#### Number of Applications by Start Latency

This displays the `the number of applications by start up latency`.

#### Average execution Time of successful applications

This displays the `average execution time of successful applications`in seconds.

### CPU Usage

This displays the CPU consumption in the Spark Operator pods based on the metrics collected from the docker.

![CPU](/docs/public/images/cpu.png)

### Memory Usage

This displays the memory consumption in the Spark Operator pods based on the metrics collected from the docker.

![Memory](/docs/public/images/memory.png)

### Disk Space Usage

This displays the disk usage for the Spark Operator pods.

![Disk](/docs/public/images/disk.png)

### Network

![Network](/docs/public/images/network.png)

#### Receive/Transmit Bandwidth

This displays the network traffic in bytes per second for the pod.

#### Rate of Received/Transmitted Packets

This displays the network packets for the pod.

#### Rate of Received/Transmitted Packets Dropped

This displays the dropped packets for the pod.

# Prometheus Rules

This section describes the Prometheus rules configured for the Spark Operator.

## Alerts

The following alerts are configured for the Spark Operator.

### Spark Operator Controller CPU Usage

When some of Spark Operator controller pods' CPU load is higher than `prometheusRules.alert.cpuThreshold`, Prometheus fires an alert.    
The threshold is the percentage of the CPU limit specified for the pod.

### Spark Operator Controller Memory Usage

When some of Spark Operator controller pods' memory usage is higher than `prometheusRules.alert.memoryThreshold`, Prometheus fires an alert.    
The threshold is the percentage of the memory limit specified for the pod.

### Spark Operator Webhook CPU Usage

When some of Spark Operator webhook pods' CPU load is higher than `prometheusRules.alert.cpuThreshold`, Prometheus fires an alert.    
The threshold is the percentage of the CPU limit specified for the pod.

### Spark Operator Webhook Memory Usage

When some of Spark Operator webhook pods' memory usage is higher than `prometheusRules.alert.memoryThreshold`, Prometheus fires an alert.    
The threshold is the percentage of the memory limit specified for the pod.

### Spark Operator Controller is Degraded

If some of the Spark Operator Controller's pods go down, Prometheus fires an alert.

### Spark Operator Controller is Down

If none of the Spark Operator Controller's pods are in the 'Running' phase, Prometheus fires an alert notifying that the operator is down.

### Spark Operator Webhook is Degraded

If some of the Spark Operator Webhook's pods go down, Prometheus fires an alert.

### Spark Operator Webhook is Down

If none of the Spark Operator Webhook's pods are in the 'Running' phase, Prometheus fires an alert notifying that the operator is down.
