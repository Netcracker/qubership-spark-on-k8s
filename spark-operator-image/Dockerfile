FROM alpine:latest AS unpacker
ENV HADOOP_VERSION=3.4.1
ENV SPARK_JARS_DIR=/opt/spark/jars
ENV MAVEN_REPO=https://repo1.maven.org/maven2
RUN apk add curl
RUN mkdir -p /opt/spark/jars/ && \
    #curl -k https://dlcdn.apache.org/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz | tar xvz -C /opt && \
    curl -k -L $MAVEN_REPO/software/amazon/awssdk/bundle/2.32.13/bundle-2.32.13.jar --output $SPARK_JARS_DIR/bundle-2.32.13.jar && \
    curl -k -L $MAVEN_REPO/org/apache/hadoop/hadoop-aws/$HADOOP_VERSION/hadoop-aws-$HADOOP_VERSION.jar --output $SPARK_JARS_DIR/hadoop-aws-$HADOOP_VERSION.jar

FROM ghcr.io/kubeflow/spark-operator/controller:2.3.0
ENV SPARK_JARS_DIR=/opt/spark/jars

COPY --from=unpacker --chmod=0777 $SPARK_JARS_DIR/ $SPARK_JARS_DIR/
