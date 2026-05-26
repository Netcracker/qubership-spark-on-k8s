FROM python:3.12-slim AS unpacker


SHELL ["/bin/bash", "-o", "pipefail", "-c"]


RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mkdir -p chart/helm/spark-on-k8s/charts && \
    curl -s -L https://github.com/kubeflow/spark-operator/releases/download/v2.5.0/spark-operator-2.5.0.tgz | \
    tar xvz -C chart/helm/spark-on-k8s/charts

COPY chart /app/chart
COPY spark-history-server/chart/helm /app/chart/helm/spark-on-k8s/charts
COPY spark-service-integration-tests/chart/helm /app/chart/helm/spark-on-k8s/charts
COPY spark-thrift-server/chart/helm /app/chart/helm/spark-on-k8s/charts
COPY docker-transfer/sync_util.py /app/sync_util.py
COPY docker-transfer/update_charts.py /app/update_charts.py
COPY docker-transfer/values.schema.json /app/chart/helm/spark-on-k8s/charts/spark-operator
COPY docker-transfer/sync_schema_defs.py /app/sync_schema_defs.py
COPY docker-transfer/validation.py /app/validation.py
COPY docker-transfer/commondefs.json /app/commondefs.json

RUN pip install --no-cache-dir ruamel.yaml==0.17.32, pyyaml && \
    python sync_schema_defs.py && \
    python validation.py chart/helm/spark-on-k8s/values.yaml chart/helm/spark-on-k8s/values.schema.json && \
    python validation.py chart/helm/spark-on-k8s/charts/spark-history-server/values.yaml chart/helm/spark-on-k8s/charts/spark-history-server/values.schema.json && \
    python validation.py chart/helm/spark-on-k8s/charts/spark-thrift-server/values.yaml chart/helm/spark-on-k8s/charts/spark-thrift-server/values.schema.json && \
    python validation.py chart/helm/spark-on-k8s/charts/spark-integration-tests/values.yaml chart/helm/spark-on-k8s/charts/spark-integration-tests/values.schema.json && \
    python validation.py chart/helm/spark-on-k8s/charts/spark-operator/values.yaml chart/helm/spark-on-k8s/charts/spark-operator/values.schema.json && \
    python sync_util.py images chart/helm/spark-on-k8s/release-images.yaml chart/helm/spark-on-k8s/values.yaml && \
    python sync_util.py images chart/helm/spark-on-k8s/release-images.yaml chart/helm/spark-on-k8s/charts/spark-history-server/values.yaml && \
    python sync_util.py images chart/helm/spark-on-k8s/release-images.yaml chart/helm/spark-on-k8s/charts/spark-thrift-server/values.yaml && \
    python sync_util.py images chart/helm/spark-on-k8s/release-images.yaml chart/helm/spark-on-k8s/charts/spark-integration-tests/values.yaml && \
    python sync_util.py qubership-spark-operator chart/helm/spark-on-k8s/release-images.yaml chart/helm/spark-on-k8s/charts/spark-operator/values.yaml && \
    python update_charts.py

FROM scratch

COPY --from=unpacker --chmod=0777 /app/chart /chart
