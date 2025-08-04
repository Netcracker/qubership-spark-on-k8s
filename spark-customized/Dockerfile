FROM alpine:latest AS unpacker
ENV HADOOP_VERSION=3.4.1
ENV SPARK_JARS_DIR=/opt/spark/jars
ENV MAVEN_REPO=https://repo1.maven.org/maven2
RUN apk add curl
RUN mkdir -p /opt/spark/jars/ && \
    curl -k -L $MAVEN_REPO/software/amazon/awssdk/bundle/2.32.13/bundle-2.32.13.jar --output $SPARK_JARS_DIR/bundle-2.32.13.jar && \
    curl -k -L $MAVEN_REPO/org/apache/hadoop/hadoop-aws/$HADOOP_VERSION/hadoop-aws-$HADOOP_VERSION.jar --output $SPARK_JARS_DIR/hadoop-aws-$HADOOP_VERSION.jar

FROM spark:4.0.0-java21
ENV SPARK_JARS_DIR=/opt/spark/jars

USER root


    # Change permissions to run examples
    # Still need to add property     "spark.jars.ivy": "/tmp/.ivy" when running in openshift
RUN chmod 777 /opt/spark/work-dir \
    # Add permissions to add certs
    && chown spark ${JAVA_HOME}/lib/security/cacerts && chgrp root ${JAVA_HOME}/lib/security/cacerts \
    && chmod ug+rw ${JAVA_HOME}/lib/security/cacerts

# Use noble ubuntu repo to upgrade curl to 8.5.0, since jammy ubuntu curl version is 7.81
RUN echo 'deb [arch=amd64] http://archive.ubuntu.com/ubuntu noble main' >> /etc/apt/sources.list \
    && echo 'deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports noble main' >> /etc/apt/sources.list \
    && apt-get update && apt-get --only-upgrade install -y curl=8.5.0-2ubuntu10 --no-install-recommends


COPY --chmod=0777 ./entrypoint.sh /opt/
COPY --chmod=0777 ./thrift-server-entrypoint.sh /opt/

COPY --from=unpacker --chmod=0777 $SPARK_JARS_DIR/ $SPARK_JARS_DIR/


USER spark
