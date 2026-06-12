This guide covers the following:

* [Overview](#overview)
  * [Spark Operator](#spark-operator)
  * [Spark History Server](#spark-history-server)
    * [Authentication for Spark History Server](#authentication-for-spark-history-server) 
  * [Spark Thrift Server](#spark-thrift-server)
* [Supported Deployment Scheme](#supported-deployment-scheme)
  * [On-Prem](#on-prem)
    * [Non-HA Deployment Scheme](#non-ha-deployment-scheme)
    * [HA Deployment Scheme](#ha-deployment-scheme)
    * [DR Deployment Scheme](#dr-deployment-scheme) 

# Overview

This section provides an overview of Kubeflow Spark operator and related entities.

## Spark Operator

Kubeflow Spark Operator is a Kubernetes Operator for Apache Spark. Kubeflow spark operator chart is used as a subchart in qubership-spark-on-k8s helm charts. The operator makes specifying and running Spark applications easier. It uses Kubernetes custom resources for specifying and managing Spark applications. Application configuration details are specified in the CR file and submitted to the Kubernetes cluster.
Spark Operator handles the CR file and executes spark-submit for the application.

![Spark Operator Architecture](/docs/public/images/architecture/spark-operator-architecture.png)

## Spark History Server

Spark History Server is an optional component. It is a part of the Spark base image and allows accessing the Spark applications' user interface after their completion, as the Spark application user interface becomes unavailable after the application's driver completes. Applications can be configured to log events that are later rendered by the Spark History Server.
Spark History Server tracks completed and running Spark applications. The History Server and applications should point to the same log directory. Currently, S3 storage is the only fully supported log storage.
The authentication for the Spark History Server user interface is implemented through OAuth2 Proxy. It is deployed as a sidecar container for the History Server.

![Spark History Server](/docs/public/images/architecture/spark-history-server.png)

### Authentication for Spark History Server

The authentication for the Spark History Server user interface is implemented through [OAuth2 Proxy](https://github.com/oauth2-proxy/oauth2-proxy). 
It provides authentication using Authentication Providers, in our case Keycloak.  
When authentication for the History Server is enabled, the authentication related annotations are added to the History Server's ingress.  
When NGINX receives a request, it first sends the request onto `nginx.ingress.kubernetes.io/auth-url`, which specifies the URL that should be used for checking if the user is authenticated.
The service at this URL, in our case OAuth2 Proxy, is responsible for validating whether the user is authenticated.
If the user is authenticated, then the service returns a 2xx status code, and the request is passed onto the Spark History Server. 
If it is not authenticated, then it is passed to the URL specified in `nginx.ingress.kubernetes.io/auth-signin` to start the authentication.

![Spark History Server with OAuth2 Proxy](/docs/public/images/architecture/oauth2-proxy-spark-history-server.png)

## Spark Thrift Server

Spark Thrift Server provides Spark SQL capabilities to end-users in a pure SQL way through a JDBC interface. It allows to execute SQL queries using SQL clients.
Spark Thrift Server is a Spark application that is started using the `start-thriftserver.sh` script. SQL queries submitted to the Spark Thrift server get all the benefits of distributed capabilities of the Spark SQL query engine.   
As a Spark application, Spark Thrift server consists of a driver and multiple executor pods. 

## Cluster Mode

When a query is submitted, the driver requests resources required for processing the query and creates as many executors as need (dynamic allocation is enabled by default) to perform the tasks.  
Spark Thrift Server communicates with Hive Metastore to get the metadata required for query compilation.

![Spark Thrift Server in Cluster Mode](/docs/public/images/architecture/spark-thrift-cluster.png)

## Local Mode

In local mode, the Spark driver executes queries in local threads, it does not create executor pods.

![Spark Thrift Server in Local Mode](/docs/public/images/architecture/spark-thrift-local.png)

# Supported Deployment Scheme

The information about supported deployment scheme s provided in the below sub-sections.

## On-Prem

### Non-HA Deployment Scheme

Spark Operator in the non-HA mode has only one replica of each component. Spark History Server is optional component.

![Spark Operator non-HA Scheme](/docs/public/images/architecture/spark-operator-non-ha-scheme.png)

## HA Deployment Scheme

Spark Operator supports the HA mode, in which there can be more than one replicas of the operator, with only one of the replicas (the leader replica) actively operating. 
If the leader replica fails, the leader election process is engaged again to determine a new leader from the replicas available.
Spark History Server is optional component and it does not support the HA mode.

![Spark Operator HA Scheme](/docs/public/images/architecture/spark-operator-ha-scheme.png)

### DR Deployment Scheme

Spark Operator supports DR deployment in the Active-Active scheme. An independent instance of Spark Operator is installed on each site.  
The Spark Operator deployment in the DR deployment is as shown in the following scheme.

![Spark Operator DR Scheme](/docs/public/images/architecture/spark-operator-dr-scheme.png)
