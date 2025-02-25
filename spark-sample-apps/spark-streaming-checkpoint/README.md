The following topics are covered in this section:

* [Overview](#overview)
* [Run spark-streaming-checkpoint Application](#run-spark-streaming-checkpoint-application)
   * [Prerequisites](#prerequisites)
   * [Steps to Run spark-streaming-checkpoint Application](#steps-to-run-spark-streaming-checkpoint-application)
* [Build Docker Image of Application](#build-docker-image-of-application)

## Overview

The Spark Streaming Kafka Word Count application continuously reads string data from a Kafka topic and prints out the number of each word in a string.  
The application uses Spark checkpoints to recover after a failure. S3 storage bucket and Kubernetes PVC are used to store the checkpoint files.

## Run spark-streaming-checkpoint Application

### Prerequisites

* Spark Operator GCP is deployed on Kubernetes.  
  For more details about the installation, refer to the [Spark Operator Installation Procedure](/docs/installation-guide.md) in the _Cloud Platform Installation_ guide.
* Kafka is deployed on Kubernetes.
* Docker image of the Spark Streaming Checkpoint application.
  If you do not have the image, refer to the [build instructions](#build-docker-image-of-application).

### Steps to Run spark-streaming-checkpoint Application

1. Create a Kafka topic.  
   In the current application example, the default Kafka topic name is `spark-streaming-test`.

1. Update the [/spark-streaming-checkpoint/cr/spark-streaming-checkpoint-s3.yaml](./cr/spark-streaming-checkpoint-s3.yaml) or [/spark-streaming-checkpoint/cr/spark-streaming-checkpoint-pvc.yaml](./cr/spark-streaming-checkpoint-pvc.yaml) file based on which storage is going to be used for the checkpoints.  
   This object is used by the GCP Spark operator to run and manage Spark applications.  
   For more information, refer to the [User Guide](../../docs/user-guide.md#Spark Application on Kubernetes).

   The following properties should be configured in [/spark-streaming-checkpoint/cr/spark-streaming-checkpoint-s3.yaml](./cr/spark-streaming-checkpoint-s3.yaml) or [/spark-streaming-checkpoint/cr/spark-streaming-checkpoint-pvc.yaml](./cr/spark-streaming-checkpoint-pvc.yaml):

   |Property|Default|Example|Description|
   |:-------|:----------|:----------|:----------|
   |spec.image|-|-|Docker image of the application. See [Prerequisites](#prerequisites)| 
   |spec.sparkConf.spark.kafka.brokers|"kafka.kafka-service:9092"|-|Kafka brokers list separated by comma `,`.|
   |spec.sparkConf.spark.kafka.groupId|"spark-streaming-word-count"|-|Kafka consumer group ID.| 
   |spec.sparkConf.spark.kafka.topics|"spark-streaming-test"|-|Kafka topics list separated by comma `,`.| 
   |spec.sparkConf.spark.kafka.securityProtocol|""|"SASL_PLAINTEXT"|Security protocol used to connect to Kafka.| 
   |spark.kafka.saslMechanism|""|"SCRAM-SHA-512"|Used for Basic authentication to Kafka.| 
   |spark.kafka.saslJaasConfig|""|"org.apache.kafka.common.security.scram.ScramLoginModule required username=\"client\" password=\"client\";"|Kafka client Basic authentication config.| 
   |spark.checkpoint.directory/ "/mnt/spark/checkpoints" | For PV: "/mnt/spark/checkpoints-new", for S3: "s3a://spark/checkpoints" | Custom parameter to set the checkpointing directory. This parameter is handled by the application, not by the Spark as Spark parameters.| 

1. In case of using S3, refer to [S3 Storage](../../docs/applications-management.md#s3-storage) for connection configuration details.

1. Submit the application by applying the `spark-streaming-checkpoint-s3.yaml` or `spark-streaming-checkpoint-pvc.yaml` file to the Kubernetes namespace intended for the applications.

   Following is an example of a submission command.

   ```
   kubectl apply -f spark-streaming-checkpoint-s3.yaml --namespace <spark_applications_namespace>
   ```

1. Enter some text to the Kafka topic.  
   While testing, all the parameters, except for 'Value' can be omitted.
   Example of 'Value': "one, two, two, three, three, three".

1. Check that the driver pod contains the logs similar to the following.

   ```
   21/09/29 07:27:44 INFO DAGScheduler: Job 351 finished: print at JavaDirectKafkaWordCount.java:100, took 0.023663 s
   -------------------------------------------
   Time: 1632900464000 ms
   -------------------------------------------
   (two,2)
   (one,1)
   (three,3)
   
   21/09/29 07:27:44 INFO JobScheduler: Finished job streaming job 1632900464000 ms.0 from job set of time 1632900464000 ms
   ```
   
1. To check that checkpointing works, the driver pod can be deleted. While the application is getting restarted by the Spark Operator according to the `restartPolicy` parameter, add new text to the Kafka topic.  
   The new text from the Kafka topic should be streamed by the application after restart.  

## Add Ingress for Spark UI

There are two ways how an ingress for the Spark UI can be added:

1. Deploy the Spark Operator with the `ingressUrlFormat` parameter.  
   The Spark Operator automatically creates an ingress for a submitted Spark application.
   For more information, refer to [https://kubeflow.github.io/spark-operator/docs/quick-start-guide.html#driver-ui-access-and-ingress](https://kubeflow.github.io/spark-operator/docs/quick-start-guide.html#driver-ui-access-and-ingress).

   Following is an example of a deployment parameter.

   ```
   ...
   ingressUrlFormat: "{{$appName}}-ui-svc.dashboard.cloud.qubership.com"
   ...
   ```

2. Alternatively, an ingress can be added using the prepared yaml file.  
   See an example at [spark-streaming-app-ingress.yaml](../../spark-sample-apps/spark-streaming-word-count/cr/spark-streaming-app-ingress.yaml).

## Build Docker Image of Application

To build a docker image for the spark-streaming-checkpoint application, use [Dockerfile](Dockerfile).