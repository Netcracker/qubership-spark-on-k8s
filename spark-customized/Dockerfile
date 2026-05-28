FROM alpine:latest AS unpacker
ENV HADOOP_VERSION=3.4.1
ENV SPARK_JARS_DIR=/opt/spark/jars
ENV MAVEN_REPO=https://repo1.maven.org/maven2
RUN apk add curl
RUN mkdir -p /opt/spark/jars/ && \
    curl -k -L $MAVEN_REPO/software/amazon/awssdk/bundle/2.44.14/bundle-2.44.14.jar --output $SPARK_JARS_DIR/bundle-2.44.14.jar && \
    curl -k -L $MAVEN_REPO/org/apache/hadoop/hadoop-aws/$HADOOP_VERSION/hadoop-aws-$HADOOP_VERSION.jar --output $SPARK_JARS_DIR/hadoop-aws-$HADOOP_VERSION.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-all/4.2.13.Final/netty-all-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-all-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-buffer/4.2.13.Final/netty-buffer-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-buffer-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec/4.2.13.Final/netty-codec-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-codec-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-base/4.2.13.Final/netty-codec-base-4.2.13.Final.jar --output ${SPARK_JARS_DIR}/netty-codec-base-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-classes-quic/4.2.13.Final/netty-codec-classes-quic-4.2.13.Final.jar --output ${SPARK_JARS_DIR}/netty-codec-classes-quic-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-compression/4.2.13.Final/netty-codec-compression-4.2.13.Final.jar --output ${SPARK_JARS_DIR}/netty-codec-compression-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-dns/4.2.13.Final/netty-codec-dns-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-codec-dns-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-http2/4.2.13.Final/netty-codec-http2-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-codec-http2-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-http3/4.2.13.Final/netty-codec-http3-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-codec-http3-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-http/4.2.13.Final/netty-codec-http-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-codec-http-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-marshalling/4.2.13.Final/netty-codec-marshalling-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-codec-marshalling-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-native-quic/4.2.13.Final/netty-codec-native-quic-4.2.13.Final-linux-aarch_64.jar --output $SPARK_JARS_DIR/netty-codec-native-quic-4.2.13.Final-linux-aarch_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-native-quic/4.2.13.Final/netty-codec-native-quic-4.2.13.Final-linux-x86_64.jar --output $SPARK_JARS_DIR/netty-codec-native-quic-4.2.13.Final-linux-x86_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-native-quic/4.2.13.Final/netty-codec-native-quic-4.2.13.Final-osx-aarch_64.jar --output $SPARK_JARS_DIR/netty-codec-native-quic-4.2.13.Final-osx-aarch_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-native-quic/4.2.13.Final/netty-codec-native-quic-4.2.13.Final-osx-x86_64.jar --output $SPARK_JARS_DIR/netty-codec-native-quic-4.2.13.Final-osx-x86_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-native-quic/4.2.13.Final/netty-codec-native-quic-4.2.13.Final-windows-x86_64.jar --output $SPARK_JARS_DIR/netty-codec-native-quic-4.2.13.Final-windows-x86_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-protobuf/4.2.13.Final/netty-codec-protobuf-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-codec-protobuf-4.2.13.Final.jar && \     
    curl -k -L $MAVEN_REPO/io/netty/netty-codec-socks/4.2.13.Final/netty-codec-socks-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-codec-socks-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-common/4.2.13.Final/netty-common-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-common-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-handler/4.2.13.Final/netty-handler-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-handler-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-handler-proxy/4.2.13.Final/netty-handler-proxy-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-handler-proxy-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-resolver/4.2.13.Final/netty-resolver-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-resolver-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-resolver-dns/4.2.13.Final/netty-resolver-dns-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-resolver-dns-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport/4.2.13.Final/netty-transport-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-transport-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-classes-epoll/4.2.13.Final/netty-transport-classes-epoll-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-transport-classes-epoll-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-classes-io_uring/4.2.13.Final/netty-transport-classes-io_uring-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-transport-classes-io_uring-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-classes-kqueue/4.2.13.Final/netty-transport-classes-kqueue-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-transport-classes-kqueue-4.2.13.Final.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-epoll/4.2.13.Final/netty-transport-native-epoll-4.2.13.Final-linux-aarch_64.jar --output $SPARK_JARS_DIR/netty-transport-native-epoll-4.2.13.Final-linux-aarch_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-epoll/4.2.13.Final/netty-transport-native-epoll-4.2.13.Final-linux-riscv64.jar --output $SPARK_JARS_DIR/netty-transport-native-epoll-4.2.13.Final-linux-riscv64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-epoll/4.2.13.Final/netty-transport-native-epoll-4.2.13.Final-linux-x86_64.jar --output $SPARK_JARS_DIR/netty-transport-native-epoll-4.2.13.Final-linux-x86_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-io_uring/4.2.13.Final/netty-transport-native-io_uring-4.2.13.Final-linux-aarch_64.jar --output $SPARK_JARS_DIR/netty-transport-native-io_uring-4.2.13.Final-linux-aarch_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-io_uring/4.2.13.Final/netty-transport-native-io_uring-4.2.13.Final-linux-riscv64.jar --output $SPARK_JARS_DIR/netty-transport-native-io_uring-4.2.13.Final-linux-riscv64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-io_uring/4.2.13.Final/netty-transport-native-io_uring-4.2.13.Final-linux-x86_64.jar --output $SPARK_JARS_DIR/netty-transport-native-io_uring-4.2.13.Final-linux-x86_64.jar && \  
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-kqueue/4.2.13.Final/netty-transport-native-kqueue-4.2.13.Final-osx-aarch_64.jar --output $SPARK_JARS_DIR/netty-transport-native-kqueue-4.2.13.Final-osx-aarch_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-kqueue/4.2.13.Final/netty-transport-native-kqueue-4.2.13.Final-osx-x86_64.jar --output $SPARK_JARS_DIR/netty-transport-native-kqueue-4.2.13.Final-osx-x86_64.jar && \
    curl -k -L $MAVEN_REPO/io/netty/netty-transport-native-unix-common/4.2.13.Final/netty-transport-native-unix-common-4.2.13.Final.jar --output $SPARK_JARS_DIR/netty-transport-native-unix-common-4.2.13.Final.jar 

FROM apache/spark:4.1.2
ENV SPARK_JARS_DIR=/opt/spark/jars

USER root


    # Change permissions to run examples
    # Still need to add property     "spark.jars.ivy": "/tmp/.ivy" when running in openshift
RUN chmod 777 /opt/spark/work-dir \
    # Create the writable volume for the copy
    && mkdir -p /java-security \
    && mkdir -p /opt/spark/secrets \
    && chown spark:spark /java-security \
    && chown spark:spark /opt/spark/secrets \
    && chmod 775 /java-security


# Use noble ubuntu repo to upgrade curl to 8.5.0, since jammy ubuntu curl version is 7.81
RUN echo 'deb [arch=amd64] http://archive.ubuntu.com/ubuntu noble main' >> /etc/apt/sources.list \
    && echo 'deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports noble main' >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get --only-upgrade install -y curl=8.5.0-2ubuntu10 --no-install-recommends \
    \
    && curl -fsSL -o /usr/local/bin/gosu https://github.com/tianon/gosu/releases/download/1.19/gosu-amd64 \
    && chmod +x /usr/local/bin/gosu \
    && rm /usr/sbin/gosu \
    \
    && apt-get clean && rm -rf /var/lib/apt/lists/*



COPY --chmod=0777 ./entrypoint.sh /opt/
COPY --chmod=0777 ./thrift-server-entrypoint.sh /opt/

RUN rm $SPARK_JARS_DIR/netty-all-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-buffer-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-codec-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-codec-base-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-codec-classes-quic-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-codec-compression-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-codec-dns-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-codec-http2-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-codec-http3-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-codec-http-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-codec-marshalling-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-codec-native-quic-4.2.7.Final-linux-aarch_64.jar \
    $SPARK_JARS_DIR/netty-codec-native-quic-4.2.7.Final-linux-x86_64.jar \
    $SPARK_JARS_DIR/netty-codec-native-quic-4.2.7.Final-osx-aarch_64.jar \
    $SPARK_JARS_DIR/netty-codec-native-quic-4.2.7.Final-osx-x86_64.jar \
    $SPARK_JARS_DIR/netty-codec-native-quic-4.2.7.Final-windows-x86_64.jar \
    $SPARK_JARS_DIR/netty-codec-protobuf-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-codec-socks-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-common-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-handler-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-handler-proxy-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-resolver-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-resolver-dns-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-transport-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-transport-classes-epoll-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-transport-classes-io_uring-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-transport-classes-kqueue-4.2.7.Final.jar \
    $SPARK_JARS_DIR/netty-transport-native-epoll-4.2.7.Final-linux-aarch_64.jar \
    $SPARK_JARS_DIR/netty-transport-native-epoll-4.2.7.Final-linux-riscv64.jar \
    $SPARK_JARS_DIR/netty-transport-native-epoll-4.2.7.Final-linux-x86_64.jar \
    $SPARK_JARS_DIR/netty-transport-native-io_uring-4.2.7.Final-linux-aarch_64.jar \
    $SPARK_JARS_DIR/netty-transport-native-io_uring-4.2.7.Final-linux-riscv64.jar \
    $SPARK_JARS_DIR/netty-transport-native-io_uring-4.2.7.Final-linux-x86_64.jar \
    $SPARK_JARS_DIR/netty-transport-native-kqueue-4.2.7.Final-osx-aarch_64.jar \
    $SPARK_JARS_DIR/netty-transport-native-kqueue-4.2.7.Final-osx-x86_64.jar \
    $SPARK_JARS_DIR/netty-transport-native-unix-common-4.2.7.Final.jar

COPY --from=unpacker --chmod=0777 $SPARK_JARS_DIR/ $SPARK_JARS_DIR/



USER spark
