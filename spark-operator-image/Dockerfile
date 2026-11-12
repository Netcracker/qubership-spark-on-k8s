FROM alpine:latest AS unpacker
ENV HADOOP_VERSION=3.4.1
ENV netty_version=4.2.18.Final
ENV jackson_version=2.21.8
ENV tcnative_version=2.0.84.Final
ENV zstd_version=1.5.7-25
ENV snappy_version=1.1.10.10
ENV lz4_version=1.11.4
ENV vertx_version=4.5.36
ENV xmlschema_version=2.3.3
ENV SPARK_JARS_DIR=/opt/spark/jars
ENV seaweedfs_version=4.38
ENV MAVEN_REPO=https://repo1.maven.org/maven2
RUN apk add curl
RUN mkdir -p /opt/spark/jars/ && \
    curl -k -L $MAVEN_REPO/software/amazon/awssdk/bundle/2.44.14/bundle-2.44.14.jar --output $SPARK_JARS_DIR/bundle-2.44.14.jar && \
    curl -k -L $MAVEN_REPO/org/apache/hadoop/hadoop-aws/$HADOOP_VERSION/hadoop-aws-$HADOOP_VERSION.jar --output $SPARK_JARS_DIR/hadoop-aws-$HADOOP_VERSION.jar && \
    curl -k -L $MAVEN_REPO/com/seaweedfs/seaweedfs-hadoop3-client/$seaweedfs_version/seaweedfs-hadoop3-client-$seaweedfs_version.jar --output $SPARK_JARS_DIR/seaweedfs-hadoop3-client-$seaweedfs_version.jar && \
    curl -k -L $MAVEN_REPO/com/fasterxml/jackson/core/jackson-core/$jackson_version/jackson-core-$jackson_version.jar --output $SPARK_JARS_DIR/jackson-core-$jackson_version.jar && \
    curl -k -L $MAVEN_REPO/com/fasterxml/jackson/core/jackson-databind/$jackson_version/jackson-databind-$jackson_version.jar --output $SPARK_JARS_DIR/jackson-databind-$jackson_version.jar && \
    curl -k -L $MAVEN_REPO/com/fasterxml/jackson/dataformat/jackson-dataformat-yaml/$jackson_version/jackson-dataformat-yaml-$jackson_version.jar --output $SPARK_JARS_DIR/jackson-dataformat-yaml-$jackson_version.jar && \
    curl -k -L $MAVEN_REPO/com/fasterxml/jackson/datatype/jackson-datatype-jsr310/$jackson_version/jackson-datatype-jsr310-$jackson_version.jar --output $SPARK_JARS_DIR/jackson-datatype-jsr310-$jackson_version.jar && \
    curl -k -L $MAVEN_REPO/com/fasterxml/jackson/module/jackson-module-scala_2.13/$jackson_version/jackson-module-scala_2.13-$jackson_version.jar --output $SPARK_JARS_DIR/jackson-module-scala_2.13-$jackson_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-all/$netty_version/netty-all-$netty_version.jar --output $SPARK_JARS_DIR/netty-all-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-buffer/$netty_version/netty-buffer-$netty_version.jar --output $SPARK_JARS_DIR/netty-buffer-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec/$netty_version/netty-codec-$netty_version.jar --output $SPARK_JARS_DIR/netty-codec-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-base/$netty_version/netty-codec-base-$netty_version.jar --output $SPARK_JARS_DIR/netty-codec-base-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-compression/$netty_version/netty-codec-compression-$netty_version.jar --output $SPARK_JARS_DIR/netty-codec-compression-$netty_version.jar && \
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
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-epoll/$netty_version/netty-transport-native-epoll-$netty_version-linux-aarch_64.jar --output $SPARK_JARS_DIR/netty-transport-native-epoll-$netty_version-linux-aarch_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-epoll/$netty_version/netty-transport-native-epoll-$netty_version-linux-riscv64.jar --output $SPARK_JARS_DIR/netty-transport-native-epoll-$netty_version-linux-riscv64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-epoll/$netty_version/netty-transport-native-epoll-$netty_version-linux-x86_64.jar --output $SPARK_JARS_DIR/netty-transport-native-epoll-$netty_version-linux-x86_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-kqueue/$netty_version/netty-transport-native-kqueue-$netty_version-osx-aarch_64.jar --output $SPARK_JARS_DIR/netty-transport-native-kqueue-$netty_version-osx-aarch_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-kqueue/$netty_version/netty-transport-native-kqueue-$netty_version-osx-x86_64.jar --output $SPARK_JARS_DIR/netty-transport-native-kqueue-$netty_version-osx-x86_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-unix-common/$netty_version/netty-transport-native-unix-common-$netty_version.jar --output $SPARK_JARS_DIR/netty-transport-native-unix-common-$netty_version.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-tcnative-boringssl-static/$tcnative_version/netty-tcnative-boringssl-static-$tcnative_version-linux-aarch_64.jar --output $SPARK_JARS_DIR/netty-tcnative-boringssl-static-$tcnative_version-linux-aarch_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-tcnative-boringssl-static/$tcnative_version/netty-tcnative-boringssl-static-$tcnative_version-linux-x86_64.jar --output $SPARK_JARS_DIR/netty-tcnative-boringssl-static-$tcnative_version-linux-x86_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-tcnative-boringssl-static/$tcnative_version/netty-tcnative-boringssl-static-$tcnative_version-osx-aarch_64.jar --output $SPARK_JARS_DIR/netty-tcnative-boringssl-static-$tcnative_version-osx-aarch_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-tcnative-boringssl-static/$tcnative_version/netty-tcnative-boringssl-static-$tcnative_version-osx-x86_64.jar --output $SPARK_JARS_DIR/netty-tcnative-boringssl-static-$tcnative_version-osx-x86_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-tcnative-boringssl-static/$tcnative_version/netty-tcnative-boringssl-static-$tcnative_version-windows-x86_64.jar --output $SPARK_JARS_DIR/netty-tcnative-boringssl-static-$tcnative_version-windows-x86_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-tcnative-classes/$tcnative_version/netty-tcnative-classes-$tcnative_version.jar --output $SPARK_JARS_DIR/netty-tcnative-classes-$tcnative_version.jar && \
    curl -k -L $MAVEN_REPO/com/github/luben/zstd-jni/$zstd_version/zstd-jni-$zstd_version.jar --output $SPARK_JARS_DIR/zstd-jni-$zstd_version.jar && \
    curl -k -L $MAVEN_REPO/org/xerial/snappy/snappy-java/$snappy_version/snappy-java-$snappy_version.jar --output $SPARK_JARS_DIR/snappy-java-$snappy_version.jar && \
    curl -k -L $MAVEN_REPO/at/yawk/lz4/lz4-java/$lz4_version/lz4-java-$lz4_version.jar --output $SPARK_JARS_DIR/lz4-java-$lz4_version.jar && \
    curl -k -L $MAVEN_REPO/io/vertx/vertx-core/$vertx_version/vertx-core-$vertx_version.jar --output $SPARK_JARS_DIR/vertx-core-$vertx_version.jar && \
    curl -k -L $MAVEN_REPO/io/vertx/vertx-web-client/$vertx_version/vertx-web-client-$vertx_version.jar --output $SPARK_JARS_DIR/vertx-web-client-$vertx_version.jar && \
    curl -k -L $MAVEN_REPO/io/vertx/vertx-web-common/$vertx_version/vertx-web-common-$vertx_version.jar --output $SPARK_JARS_DIR/vertx-web-common-$vertx_version.jar && \
    curl -k -L $MAVEN_REPO/io/vertx/vertx-auth-common/$vertx_version/vertx-auth-common-$vertx_version.jar --output $SPARK_JARS_DIR/vertx-auth-common-$vertx_version.jar && \
    curl -k -L $MAVEN_REPO/io/vertx/vertx-uri-template/$vertx_version/vertx-uri-template-$vertx_version.jar --output $SPARK_JARS_DIR/vertx-uri-template-$vertx_version.jar && \
    curl -k -L $MAVEN_REPO/org/apache/ws/xmlschema/xmlschema-core/$xmlschema_version/xmlschema-core-$xmlschema_version.jar --output $SPARK_JARS_DIR/xmlschema-core-$xmlschema_version.jar

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

RUN rm $SPARK_JARS_DIR/netty-all-4.2.13.Final.jar \
    $SPARK_JARS_DIR/netty-buffer-4.2.13.Final.jar \
    $SPARK_JARS_DIR/netty-codec-4.2.13.Final.jar \
    $SPARK_JARS_DIR/netty-codec-base-4.2.13.Final.jar \
    $SPARK_JARS_DIR/netty-codec-compression-4.2.13.Final.jar \
    $SPARK_JARS_DIR/netty-codec-dns-4.2.13.Final.jar \
    $SPARK_JARS_DIR/netty-codec-http2-4.2.13.Final.jar \
    $SPARK_JARS_DIR/netty-codec-http-4.2.13.Final.jar \
    $SPARK_JARS_DIR/netty-codec-socks-4.2.13.Final.jar \
    $SPARK_JARS_DIR/netty-common-4.2.13.Final.jar \
    $SPARK_JARS_DIR/netty-handler-4.2.13.Final.jar \
    $SPARK_JARS_DIR/netty-handler-proxy-4.2.13.Final.jar \
    $SPARK_JARS_DIR/netty-resolver-4.2.13.Final.jar \
    $SPARK_JARS_DIR/netty-resolver-dns-4.2.13.Final.jar \
    $SPARK_JARS_DIR/netty-transport-4.2.13.Final.jar \
    $SPARK_JARS_DIR/netty-transport-classes-epoll-4.2.13.Final.jar \
    $SPARK_JARS_DIR/netty-transport-classes-kqueue-4.2.13.Final.jar \
    $SPARK_JARS_DIR/netty-transport-native-epoll-4.2.13.Final-linux-aarch_64.jar \
    $SPARK_JARS_DIR/netty-transport-native-epoll-4.2.13.Final-linux-riscv64.jar \
    $SPARK_JARS_DIR/netty-transport-native-epoll-4.2.13.Final-linux-x86_64.jar \
    $SPARK_JARS_DIR/netty-transport-native-kqueue-4.2.13.Final-osx-aarch_64.jar \
    $SPARK_JARS_DIR/netty-transport-native-kqueue-4.2.13.Final-osx-x86_64.jar \
    $SPARK_JARS_DIR/netty-transport-native-unix-common-4.2.13.Final.jar \
    $SPARK_JARS_DIR/jackson-core-2.21.2.jar \
    $SPARK_JARS_DIR/jackson-databind-2.21.2.jar \
    $SPARK_JARS_DIR/jackson-dataformat-yaml-2.21.2.jar \
    $SPARK_JARS_DIR/jackson-datatype-jsr310-2.21.2.jar \
    $SPARK_JARS_DIR/jackson-module-scala_2.13-2.21.2.jar \
    $SPARK_JARS_DIR/netty-tcnative-boringssl-static-2.0.76.Final-linux-aarch_64.jar \
    $SPARK_JARS_DIR/netty-tcnative-boringssl-static-2.0.76.Final-linux-x86_64.jar \
    $SPARK_JARS_DIR/netty-tcnative-boringssl-static-2.0.76.Final-osx-aarch_64.jar \
    $SPARK_JARS_DIR/netty-tcnative-boringssl-static-2.0.76.Final-osx-x86_64.jar \
    $SPARK_JARS_DIR/netty-tcnative-boringssl-static-2.0.76.Final-windows-x86_64.jar \
    $SPARK_JARS_DIR/netty-tcnative-classes-2.0.76.Final.jar \
    $SPARK_JARS_DIR/zstd-jni-1.5.7-7.jar \
    $SPARK_JARS_DIR/snappy-java-1.1.10.8.jar \
    $SPARK_JARS_DIR/lz4-java-1.11.0.jar \
    $SPARK_JARS_DIR/vertx-core-4.5.26.jar \
    $SPARK_JARS_DIR/vertx-web-client-4.5.26.jar \
    $SPARK_JARS_DIR/vertx-web-common-4.5.26.jar \
    $SPARK_JARS_DIR/vertx-auth-common-4.5.26.jar \
    $SPARK_JARS_DIR/vertx-uri-template-4.5.26.jar \
    $SPARK_JARS_DIR/xmlschema-core-2.3.1.jar

COPY --from=unpacker --chmod=0644 $SPARK_JARS_DIR/ $SPARK_JARS_DIR/
COPY --chmod=0755 operator-entrypoint.sh /opt/spark/operator-entrypoint.sh

ENTRYPOINT ["/opt/spark/operator-entrypoint.sh"]
USER spark