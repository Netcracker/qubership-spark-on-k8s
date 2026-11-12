FROM alpine:latest AS unpacker
ENV HADOOP_VERSION=3.4.1
ENV SPARK_JARS_DIR=/opt/spark/jars
ENV seaweedfs_version=4.38
ENV MAVEN_REPO=https://repo1.maven.org/maven2
RUN apk add curl
RUN mkdir -p /opt/spark/jars/ && \
    curl -k -L $MAVEN_REPO/software/amazon/awssdk/bundle/2.44.14/bundle-2.44.14.jar --output $SPARK_JARS_DIR/bundle-2.44.14.jar && \
    curl -k -L $MAVEN_REPO/org/apache/hadoop/hadoop-aws/$HADOOP_VERSION/hadoop-aws-$HADOOP_VERSION.jar --output $SPARK_JARS_DIR/hadoop-aws-$HADOOP_VERSION.jar && \
    curl -k -L $MAVEN_REPO/com/seaweedfs/seaweedfs-hadoop3-client/$seaweedfs_version/seaweedfs-hadoop3-client-$seaweedfs_version.jar --output $SPARK_JARS_DIR/seaweedfs-hadoop3-client-$seaweedfs_version.jar

FROM ghcr.io/kubeflow/spark-operator/controller:2.6.0
ENV SPARK_JARS_DIR=/opt/spark/jars
USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gnupg2 \
        gpg \
        gpg-agent \
        dirmngr \
        gpgv \
        gnupg-l10n \
        gnupg-utils \
        gpgsm \
        gpgconf && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /usr/local/bin/gosu https://github.com/tianon/gosu/releases/download/1.19/gosu-amd64 \
    && chmod +x /usr/local/bin/gosu

COPY --from=unpacker --chmod=0644 $SPARK_JARS_DIR/ $SPARK_JARS_DIR/
COPY --chmod=0755 operator-entrypoint.sh /opt/spark/operator-entrypoint.sh

ENTRYPOINT ["/opt/spark/operator-entrypoint.sh"]
USER spark