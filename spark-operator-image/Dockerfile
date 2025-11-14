FROM alpine:latest AS unpacker
ENV HADOOP_VERSION=3.4.2
ENV SPARK_JARS_DIR=/opt/spark/jars
ENV MAVEN_REPO=https://repo1.maven.org/maven2
RUN apk add curl
RUN mkdir -p /opt/spark/jars/ && \
    curl -k -L $MAVEN_REPO/software/amazon/awssdk/bundle/2.32.14/bundle-2.32.14.jar --output $SPARK_JARS_DIR/bundle-2.32.14.jar && \
    curl -k -L $MAVEN_REPO/org/apache/hadoop/hadoop-aws/$HADOOP_VERSION/hadoop-aws-$HADOOP_VERSION.jar --output $SPARK_JARS_DIR/hadoop-aws-$HADOOP_VERSION.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-all/4.1.125.Final/netty-all-4.1.125.Final.jar --output $SPARK_JARS_DIR/netty-all-4.1.125.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-buffer/4.1.125.Final/netty-buffer-4.1.125.Final.jar --output $SPARK_JARS_DIR/netty-buffer-4.1.125.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec/4.1.125.Final/netty-codec-4.1.125.Final.jar --output $SPARK_JARS_DIR/netty-codec-4.1.125.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-http2/4.1.125.Final/netty-codec-http2-4.1.125.Final.jar --output $SPARK_JARS_DIR/netty-codec-http2-4.1.125.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-http/4.1.125.Final/netty-codec-http-4.1.125.Final.jar --output $SPARK_JARS_DIR/netty-codec-http-4.1.125.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-socks/4.1.125.Final/netty-codec-socks-4.1.125.Final.jar --output $SPARK_JARS_DIR/netty-codec-socks-4.1.125.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-common/4.1.125.Final/netty-common-4.1.125.Final.jar --output $SPARK_JARS_DIR/netty-common-4.1.125.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-handler/4.1.125.Final/netty-handler-4.1.125.Final.jar --output $SPARK_JARS_DIR/netty-handler-4.1.125.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-handler-proxy/4.1.125.Final/netty-handler-proxy-4.1.125.Final.jar --output $SPARK_JARS_DIR/netty-handler-proxy-4.1.125.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-resolver/4.1.125.Final/netty-resolver-4.1.125.Final.jar --output $SPARK_JARS_DIR/netty-resolver-4.1.125.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport/4.1.125.Final/netty-transport-4.1.125.Final.jar --output $SPARK_JARS_DIR/netty-transport-4.1.125.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-classes-epoll/4.1.125.Final/netty-transport-classes-epoll-4.1.125.Final.jar --output $SPARK_JARS_DIR/netty-transport-classes-epoll-4.1.125.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-classes-kqueue/4.1.125.Final/netty-transport-classes-kqueue-4.1.125.Final.jar --output $SPARK_JARS_DIR/netty-transport-classes-kqueue-4.1.125.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-epoll/4.1.125.Final/netty-transport-native-epoll-4.1.125.Final-linux-aarch_64.jar --output $SPARK_JARS_DIR/netty-transport-native-epoll-4.1.125.Final-linux-aarch_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-epoll/4.1.125.Final/netty-transport-native-epoll-4.1.125.Final-linux-x86_64.jar --output $SPARK_JARS_DIR/netty-transport-native-epoll-4.1.125.Final-linux-x86_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-kqueue/4.1.125.Final/netty-transport-native-kqueue-4.1.125.Final-osx-aarch_64.jar --output $SPARK_JARS_DIR/netty-transport-native-kqueue-4.1.125.Final-osx-aarch_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-kqueue/4.1.125.Final/netty-transport-native-kqueue-4.1.125.Final-osx-x86_64.jar --output $SPARK_JARS_DIR/netty-transport-native-kqueue-4.1.125.Final-osx-x86_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-unix-common/4.1.125.Final/netty-transport-native-unix-common-4.1.125.Final.jar --output $SPARK_JARS_DIR/netty-transport-native-unix-common-4.1.125.Final.jar

FROM ghcr.io/kubeflow/spark-operator/controller:2.3.0
ENV SPARK_JARS_DIR=/opt/spark/jars
USER root

RUN curl -fsSL -o /usr/local/bin/gosu https://github.com/tianon/gosu/releases/download/1.19/gosu-amd64 \
    && chmod +x /usr/local/bin/gosu

RUN rm /opt/spark/examples/jars/jackson-mapper-asl-1.9.13.jar \
    $SPARK_JARS_DIR/netty-all-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-buffer-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-codec-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-codec-http2-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-codec-http-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-codec-socks-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-common-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-handler-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-handler-proxy-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-resolver-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-transport-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-transport-classes-epoll-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-transport-classes-kqueue-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-transport-native-epoll-4.1.118.Final-linux-aarch_64.jar \
    $SPARK_JARS_DIR/netty-transport-native-epoll-4.1.118.Final-linux-x86_64.jar \
    $SPARK_JARS_DIR/netty-transport-native-kqueue-4.1.118.Final-osx-aarch_64.jar \
    $SPARK_JARS_DIR/netty-transport-native-kqueue-4.1.118.Final-osx-x86_64.jar \
    $SPARK_JARS_DIR/netty-transport-native-unix-common-4.1.118.Final.jar

COPY --from=unpacker --chmod=0644 $SPARK_JARS_DIR/ $SPARK_JARS_DIR/
COPY --chmod=0755 operator-entrypoint.sh /opt/spark/operator-entrypoint.sh

ENTRYPOINT ["/opt/spark/operator-entrypoint.sh"]
USER spark