ARG base_img_py=ghcr.io/netcracker/qubership-spark-customized-py:main

FROM maven:3-eclipse-temurin-17-alpine AS dependency-resolver
WORKDIR /tmp/resolve

COPY pom.xml .
RUN mvn dependency:copy-dependencies -DoutputDirectory=/opt/spark/hivejars

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