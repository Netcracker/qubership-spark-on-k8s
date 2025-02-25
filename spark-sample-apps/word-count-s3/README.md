## Table of Contents

* [Overview](#overview)
* [Run Word Count Application](#run-word-count-application)
    * [Prerequisites](#prerequisites)
    * [Steps to run word-count-s3 application](#steps-to-run-word-count-s3-application)
* [Build Docker Image of Application](#build-docker-image-of-application)
    

## Overview

Word Count S3 sample application is intended to demonstrate Spark integration with S3 storage.  
The application downloads a file from S3 storage, calculates the number of words in the file and uploads the result back to S3 storage.  
MinIO will be used as a S3 object storage.

## Run Word Count Application

### Prerequisites

* Spark Operator GCP deployed on Kubernetes.  
  Refer to [Installation Guide](/docs/installation-guide.md) for installation details.
* MinIO server and credentials. 
* Docker image of word-count-s3 application.  
  If you do not have the image, refer to [build instructions](#build-docker-image-of-application).

### Steps to run word-count-s3 application

1. Create a bucket on S3 storage and upload [log4j.properties](./input/log4j.properties) file (or any other text file) to the bucket.
   In this example application the file is uploaded to `spark-samples` bucket, at `/wordcount/input/` path - `s3a://spark-samples/wordcount/input/log4j.properties`.
2. Create a Kubernetes Secret to store MinIO credentials.  
   The command below submits to Kubernetes a Secret [/word-count-s3/cr/s3-cred.yaml](./cr/s3-cred.yaml) with MinIO credentials minio/minio123.
   
   ```
   kubectl apply -f s3-cred.yaml --namespace <spark_applications_namespace> 
   ```  
   `<spark_applications_namespace>` is the namespace for applications mentioned in [Spark Operator Installation Prerequisites](/docs/installation-guide.md#prerequisites).

3. Update [/word-count-s3/cr/spark-word-count-s3.yaml](./cr/spark-word-count-s3.yaml) file.  
   This object is used by the GCP Spark operator to run and manage Spark applications.  
   For more information, refer to the [User Guide](/docs/user-guide.md#Spark Application on Kubernetes). 
   
   The following properties should be configured in [/word-count-s3/cr/spark-word-count-s3.yaml](./cr/spark-word-count-s3.yaml):
   
   |Property|Description|
   |:-------|:----------|
   |metadata.namespace|The namespace where Spark applications are submitted. The namespace is specified by `sparkJobNamespaces` deployment parameter.|
   |spec.image|Docker image of the application. See [Prerequisites](#prerequisites)| 
   |spec.sparkConf."spark.s3.input.file"|S3 link to the input file uploaded to S3 storage in Step 1.|
   |spec.sparkConf."spark.s3.output.path"|S3 style path to upload the application result files.|
   |spec.driver.serviceAccount|The service account for the Spark applications. Refer to [NOTE ServiceAccount](/docs/user-guide.md#note-serviceaccount) for the serviceAccount name details.|
   
4. Submit the application by applying the `spark-word-count-s3.yaml` file to the Kubernetes namespace intended for the applications.  
   
   Example of submission command: 
      
   ```
   kubectl apply -f spark-word-count-s3.yaml --namespace <spark_applications_namespace>
   ```

5. Check that the application completed successfully.  
   - Refer to Kubernetes namespace where Spark application has been submitted.  
   - Find `SparkApplication` in the list of `Custom Resource Definitions`. 
   - Open `spark-word-count-s3` object. 
     At the bottom of `Data` section `status.applicationState.state`should be `COMPLETED`.
     ```yaml
     status:
       applicationState:
         state: COMPLETED
     ``` 
6. Check that the output path on S3 storage specified in `spec.sparkConf."spark.s3.output.path"` contains the following files:  
   - _SUCCESS
   - part-00001
   - part-00000

## Build Docker Image of Application

To build a docker image for the spark-streaming-checkpoint application, use [Dockerfile](Dockerfile).

