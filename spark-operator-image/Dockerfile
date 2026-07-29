FROM alpine:latest AS unpacker
ENV HADOOP_VERSION=3.4.1
ENV SPARK_JARS_DIR=/opt/spark/jars
ENV netty_version=4.1.136.Final
ENV jackson_version=2.18.8
ENV MAVEN_REPO=https://repo1.maven.org/maven2
RUN apk add curl
RUN mkdir -p /opt/spark/jars/ && \
    curl -k -L $MAVEN_REPO/software/amazon/awssdk/bundle/2.44.14/bundle-2.44.14.jar --output $SPARK_JARS_DIR/bundle-2.44.14.jar && \
    curl -k -L $MAVEN_REPO/org/apache/hadoop/hadoop-aws/$HADOOP_VERSION/hadoop-aws-$HADOOP_VERSION.jar --output $SPARK_JARS_DIR/hadoop-aws-$HADOOP_VERSION.jar && \
    curl -k -L $MAVEN_REPO/com/fasterxml/jackson/core/jackson-annotations/$jackson_version/jackson-annotations-$jackson_version.jar --output $SPARK_JARS_DIR/jackson-annotations-$jackson_version.jar && \
    curl -k -L $MAVEN_REPO/com/fasterxml/jackson/core/jackson-core/$jackson_version/jackson-core-$jackson_version.jar --output $SPARK_JARS_DIR/jackson-core-$jackson_version.jar && \
    curl -k -L $MAVEN_REPO/com/fasterxml/jackson/core/jackson-databind/$jackson_version/jackson-databind-$jackson_version.jar --output $SPARK_JARS_DIR/jackson-databind-$jackson_version.jar && \
    curl -k -L $MAVEN_REPO/com/fasterxml/jackson/dataformat/jackson-dataformat-yaml/$jackson_version/jackson-dataformat-yaml-$jackson_version.jar --output $SPARK_JARS_DIR/jackson-dataformat-yaml-$jackson_version.jar && \
    curl -k -L $MAVEN_REPO/com/fasterxml/jackson/datatype/jackson-datatype-jsr310/$jackson_version/jackson-datatype-jsr310-$jackson_version.jar --output $SPARK_JARS_DIR/jackson-datatype-jsr310-$jackson_version.jar && \
    curl -k -L $MAVEN_REPO/com/fasterxml/jackson/module/jackson-module-scala_2.13/$jackson_version/jackson-module-scala_2.13-$jackson_version.jar --output $SPARK_JARS_DIR/jackson-module-scala_2.13-$jackson_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-all/$netty_version/netty-all-$netty_version.jar --output $SPARK_JARS_DIR/netty-all-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-buffer/$netty_version/netty-buffer-$netty_version.jar --output $SPARK_JARS_DIR/netty-buffer-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec/$netty_version/netty-codec-$netty_version.jar --output $SPARK_JARS_DIR/netty-codec-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-dns/$netty_version/netty-codec-dns-$netty_version.jar --output $SPARK_JARS_DIR/netty-codec-dns-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-http2/$netty_version/netty-codec-http2-$netty_version.jar --output $SPARK_JARS_DIR/netty-codec-http2-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-http/$netty_version/netty-codec-http-$netty_version.jar --output $SPARK_JARS_DIR/netty-codec-http-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-socks/$netty_version/netty-codec-socks-$netty_version.jar --output $SPARK_JARS_DIR/netty-codec-socks-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-common/$netty_version/netty-common-$netty_version.jar --output $SPARK_JARS_DIR/netty-common-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-handler/$netty_version/netty-handler-$netty_version.jar --output $SPARK_JARS_DIR/netty-handler-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-handler-proxy/$netty_version/netty-handler-proxy-$netty_version.jar --output $SPARK_JARS_DIR/netty-handler-proxy-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-resolver/$netty_version/netty-resolver-$netty_version.jar --output $SPARK_JARS_DIR/netty-resolver-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-resolver-dns/$netty_version/netty-resolver-dns-$netty_version.jar --output $SPARK_JARS_DIR/netty-resolver-dns-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport/$netty_version/netty-transport-$netty_version.jar --output $SPARK_JARS_DIR/netty-transport-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-classes-epoll/$netty_version/netty-transport-classes-epoll-$netty_version.jar --output $SPARK_JARS_DIR/netty-transport-classes-epoll-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-classes-kqueue/$netty_version/netty-transport-classes-kqueue-$netty_version.jar --output $SPARK_JARS_DIR/netty-transport-classes-kqueue-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-epoll/$netty_version.Final/netty-transport-native-epoll-$netty_version.Final-linux-aarch_64.jar --output $SPARK_JARS_DIR/netty-transport-native-epoll-$netty_version.Final-linux-aarch_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-epoll/$netty_version.Final/netty-transport-native-epoll-$netty_version.Final-linux-riscv64.jar --output $SPARK_JARS_DIR/netty-transport-native-epoll-$netty_version.Final-linux-riscv64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-epoll/$netty_version.Final/netty-transport-native-epoll-$netty_version.Final-linux-x86_64.jar --output $SPARK_JARS_DIR/netty-transport-native-epoll-$netty_version.Final-linux-x86_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-kqueue/$netty_version.Final/netty-transport-native-kqueue-$netty_version.Final-osx-aarch_64.jar --output $SPARK_JARS_DIR/netty-transport-native-kqueue-$netty_version.Final-osx-aarch_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-kqueue/$netty_version.Final/netty-transport-native-kqueue-$netty_version.Final-osx-x86_64.jar --output $SPARK_JARS_DIR/netty-transport-native-kqueue-$netty_version.Final-osx-x86_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-unix-common/$netty_version.Final/netty-transport-native-unix-common-$netty_version.Final.jar --output $SPARK_JARS_DIR/netty-transport-native-unix-common-$netty_version.Final.jar && \
    curl -k -L $MAVEN_REPO/org/glassfish/jersey/core/jersey-client/3.0.17/jersey-client-3.0.17.jar --output $SPARK_JARS_DIR/jersey-client-3.0.17.jar

FROM ghcr.io/kubeflow/spark-operator/controller:2.5.1
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

RUN rm /opt/spark/examples/jars/jackson-mapper-asl-1.9.13.jar \
    $SPARK_JARS_DIR/jersey-client-3.0.16.jar \
    $SPARK_JARS_DIR/netty-all-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-buffer-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-codec-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-codec-dns-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-codec-http2-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-codec-http-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-codec-socks-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-common-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-handler-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-handler-proxy-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-resolver-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-resolver-dns-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-transport-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-transport-classes-epoll-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-transport-classes-kqueue-4.1.118.Final.jar \
    $SPARK_JARS_DIR/netty-transport-native-epoll-4.1.118.Final-linux-aarch_64.jar \
    $SPARK_JARS_DIR/netty-transport-native-epoll-4.1.118.Final-linux-riscv64.jar \
    $SPARK_JARS_DIR/netty-transport-native-epoll-4.1.118.Final-linux-x86_64.jar \
    $SPARK_JARS_DIR/netty-transport-native-kqueue-4.1.118.Final-osx-aarch_64.jar \
    $SPARK_JARS_DIR/netty-transport-native-kqueue-4.1.118.Final-osx-x86_64.jar \
    $SPARK_JARS_DIR/netty-transport-native-unix-common-4.1.118.Final.jar \
    $SPARK_JARS_DIR/jackson-annotations-2.18.2.jar \
    $SPARK_JARS_DIR/jackson-core-2.18.2.jar \
    $SPARK_JARS_DIR/jackson-databind-2.18.2.jar \
    $SPARK_JARS_DIR/jackson-dataformat-yaml-2.18.2.jar \
    $SPARK_JARS_DIR/jackson-datatype-jsr310-2.18.2.jar \
    $SPARK_JARS_DIR/jackson-module-scala_2.13-2.18.2.jar

COPY --from=unpacker --chmod=0644 $SPARK_JARS_DIR/ $SPARK_JARS_DIR/
COPY --chmod=0755 operator-entrypoint.sh /opt/spark/operator-entrypoint.sh

ENTRYPOINT ["/opt/spark/operator-entrypoint.sh"]
USER spark