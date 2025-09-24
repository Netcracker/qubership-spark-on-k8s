ARG base_img_py=ghcr.io/netcracker/qubership-spark-customized-py:main

FROM maven:3-eclipse-temurin-17-alpine AS dependency-resolver
WORKDIR /tmp/resolve

RUN echo '<project xmlns="http://maven.apache.org/POM/4.0.0"><modelVersion>4.0.0</modelVersion>\
    <groupId>com.test</groupId><artifactId>resolver</artifactId><version>1</version>\
    <dependencies>\
        <dependency>\
            <groupId>org.apache.hive</groupId><artifactId>hive-exec</artifactId><version>4.0.1</version>\
            <exclusions>\
                <exclusion><groupId>org.apache.logging.log4j</groupId><artifactId>log4j-slf4j-impl</artifactId></exclusion>\
                <exclusion><groupId>org.slf4j</groupId><artifactId>slf4j-log4j12</artifactId></exclusion>\
            </exclusions>\
        </dependency>\
        <dependency><groupId>org.apache.hive</groupId><artifactId>hive-standalone-metastore-common</artifactId><version>4.0.1</version></dependency>\
        <dependency>\
            <groupId>org.apache.spark</groupId><artifactId>spark-hadoop-cloud_2.13</artifactId><version>4.0.0</version>\
        </dependency>\
        <dependency>\
            <groupId>org.apache.hadoop</groupId><artifactId>hadoop-aws</artifactId><version>3.4.0</version>\
        </dependency>\
    </dependencies></project>' > pom.xml && \
    mvn dependency:copy-dependencies -DoutputDirectory=/opt/spark/hivejars

FROM $base_img_py

ENV SPARK_DIST_CLASSPATH="/opt/spark/hivejars/*"

USER root

RUN mkdir -p /opt/spark/hivejars /opt/spark/examples && \
    chown -R spark:spark /opt/spark/hivejars /opt/spark/examples

WORKDIR /opt/spark/examples/

COPY --from=dependency-resolver --chown=spark:spark /opt/spark/hivejars /opt/spark/hivejars

RUN mv /opt/spark/hivejars/spark-hadoop-cloud*.jar /opt/spark/jars/

RUN rm -f /opt/spark/hivejars/log4j-slf4j-impl-*.jar \
           /opt/spark/hivejars/slf4j-log4j12-*.jar \
           /opt/spark/hivejars/log4j-1.2-api-*.jar \
           /opt/spark/hivejars/bundle-*.jar           

COPY --chown=spark:spark spark_hive_test.py delete_s3.py ./
RUN chmod 755 *.py

RUN python3 -m pip install --no-cache-dir boto3==1.39.3

USER spark