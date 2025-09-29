FROM alpine:latest AS unpacker
ENV HADOOP_VERSION=3.4.1
ENV SPARK_JARS_DIR=/opt/spark/jars
ENV MAVEN_REPO=https://repo1.maven.org/maven2

RUN apk add curl
RUN mkdir -p /opt/spark/jars/ && \
    curl -k -L $MAVEN_REPO/software/amazon/awssdk/bundle/2.32.14/bundle-2.32.14.jar --output $SPARK_JARS_DIR/bundle-2.32.14.jar && \
    curl -k -L $MAVEN_REPO/org/apache/hadoop/hadoop-aws/$HADOOP_VERSION/hadoop-aws-$HADOOP_VERSION.jar --output $SPARK_JARS_DIR/hadoop-aws-$HADOOP_VERSION.jar

FROM ghcr.io/kubeflow/spark-operator/controller:2.3.0
ENV SPARK_JARS_DIR=/opt/spark/jars

RUN rm /opt/spark/examples/jars/jackson-mapper-asl-1.9.13.jar

COPY --from=unpacker --chmod=0644 $SPARK_JARS_DIR/ $SPARK_JARS_DIR/

# copy entrypoint and make it executable
COPY --chmod=0755 operator-entrypoint.sh /usr/bin/operator-entrypoint.sh

ENTRYPOINT ["/usr/bin/operator-entrypoint.sh"]
