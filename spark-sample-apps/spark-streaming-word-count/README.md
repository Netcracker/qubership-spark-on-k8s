The following topics are covered in this section:

* [Overview](#overview)
* [Run spark-streaming-kafka-word-count Application](#run-spark-streaming-kafka-word-count-application)
    * [Prerequisites](#prerequisites)
    * [Steps to Run spark-streaming-kafka-word-count Application](#steps-to-run-spark-streaming-kafka-word-count-application)
* [Build Docker Image of Application](#build-docker-image-of-application)
    
## Overview

The Spark Streaming Kafka Word Count application continuously reads string data from Kafka topic and prints out the number of each word in string.  

## Run spark-streaming-kafka-word-count Application

### Prerequisites

* Spark Operator GCP is deployed on Kubernetes.  
  For more details about the installation, refer to the [Spark Operator Installation Procedure](/docs/installation-guide.md) in the _Cloud Platform Installation_ guide.
* Kafka is deployed on Kubernetes. 
* Docker image of the Spark Streaming Kafka Word Count application.
  If you do not have the image, refer to the [build instructions](#build-docker-image-of-application).

### Steps to Run spark-streaming-kafka-word-count Application

1. Create a Kafka topic.  
   In the current application example, the default Kafka topic name is `spark-streaming-test`.

1. Update the [/spark-streaming-word-count/cr/spark-streaming-word-count.yaml](./cr/spark-streaming-word-count.yaml) file.  
   This object is used by the GCP Spark operator to run and manage Spark applications.  
   For more information, refer to the [User Guide](/docs/user-guide.md#Spark Application on Kubernetes).

   The following properties should be configured in [/spark-streaming-word-count/cr/spark-streaming-word-count.yaml](./cr/spark-streaming-word-count.yaml):

   |Property|Default|Example|Description|
   |:-------|:----------|:----------|:----------|
   |spec.image|-|-|Docker image of the application. See [Prerequisites](#prerequisites)| 
   |spec.sparkConf.spark.kafka.brokers|"kafka.kafka-service:9092"|-|Kafka brokers list separated by comma `,`.|
   |spec.sparkConf.spark.kafka.groupId|"spark-streaming-word-count"|-|Kafka consumer group ID.| 
   |spec.sparkConf.spark.kafka.topics|"spark-streaming-test"|-|Kafka topics list separated by comma `,`.| 
   |spec.sparkConf.spark.kafka.securityProtocol|""|"SASL_PLAINTEXT"|Security protocol used to connect to Kafka.| 
   |spark.kafka.saslMechanism|""|"SCRAM-SHA-512"|Used for Basic authentication to Kafka.| 
   |spark.kafka.saslJaasConfig|""|"org.apache.kafka.common.security.scram.ScramLoginModule required username=\"client\" password=\"client\";"|Kafka client Basic authentication config.| 

1. Submit the application by applying the `spark-streaming-word-count.yaml` file to the Kubernetes namespace intended for the applications.  
   
   Example of submission command: 
      
   ```
   kubectl apply -f spark-streaming-word-count.yaml --namespace <spark_applications_namespace>
   ```
1. Enter some text to the Kafka topic.  
   While testing, all the parameters except for 'Value' can be omitted.
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

## Add Ingress for Spark UI

There are two ways how an ingress for Spark UI can be added:

1. Deploy the Spark Operator with `ingressUrlFormat` parameter.  
   Spark Operator will automatically create an ingress for a submitted Spark application.
   For details, refer to [https://kubeflow.github.io/spark-operator/docs/quick-start-guide.html#driver-ui-access-and-ingress](https://kubeflow.github.io/spark-operator/docs/quick-start-guide.html#driver-ui-access-and-ingress).  
   
   Example of deployment parameter:
   ```
   ...
   ingressUrlFormat: "{{$appName}}-ui-svc.dashboard.cloud.qubership.com
   ...
   ```
   
2. Or an ingress can be added using prepared yaml file.  
   See an example at [spark-streaming-app-ingress.yaml](../../spark-sample-apps/spark-streaming-word-count/cr/spark-streaming-app-ingress.yaml)
   
## Build Docker Image of Application

To build a docker image for the spark-streaming-checkpoint application, use [Dockerfile](Dockerfile).