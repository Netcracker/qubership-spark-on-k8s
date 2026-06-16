# Overview

This section describes the overall steps required for standalone Spark applications' migration to Kubernetes. 

# Reference Documents

Spark documentation - [Running Spark on Kubernetes](https://spark.apache.org/docs/latest/running-on-kubernetes.html) 

Google Cloud Platform documentation - [Using a SparkApplication](https://github.com/GoogleCloudPlatform/spark-on-k8s-operator/blob/spark-operator-chart-1.0.4/docs/user-guide.md#using-a-sparkapplication)
 
# Migration Procedure

To migrate standalone Spark applications to Kubernetes:

1. Prepare docker image for the application.  
   qubership-spark-customized and qubership-spark-customized-py  images can be used as the parent docker images.
   
   Parent images define a user with id=185.  
   Kubeflow Spark operator provides an ability to set up security context for driver and executor pods.  

2. Prepare the **<application_name>.yaml** file to describe an object of the `SparkApplication` type.  
   This object is used by the Spark operator to run and manage Spark applications.  
   For more information, refer to the [User Guide](/docs/public/user-guide.md#Spark Application on Kubernetes).

3. Submit the application by applying the **<application_name>.yaml** file to the Kubernetes namespace intended for the applications.

   Example of submission command: 
   
   ```bash
   kubectl apply -f <application_name>.yaml -n spark-apps-gcp
   ```