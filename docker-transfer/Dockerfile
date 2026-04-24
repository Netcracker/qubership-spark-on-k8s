FROM python:3.12-slim AS unpacker


SHELL ["/bin/bash", "-o", "pipefail", "-c"]


RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mkdir -p chart/helm/spark-on-k8s/charts && \
    curl -s -L https://github.com/kubeflow/spark-operator/releases/download/v2.5.0/spark-operator-2.5.0.tgz | \
    tar xvz -C chart/helm/spark-on-k8s/charts && \
    mv chart/helm/spark-on-k8s/charts/spark-operator chart/helm/spark-on-k8s/charts/spark-operator && \
    sed -i 's/^name: spark-operator/name: spark-operator/' chart/helm/spark-on-k8s/charts/spark-operator/Chart.yaml

COPY chart /app/chart
COPY spark-history-server/chart/helm /app/chart/helm/spark-on-k8s/charts
COPY spark-service-integration-tests/chart/helm /app/chart/helm/spark-on-k8s/charts
COPY spark-thrift-server/chart/helm /app/chart/helm/spark-on-k8s/charts
COPY docker-transfer/sync_util.py /app/sync_util.py
COPY docker-transfer/update_charts.py /app/update_charts.py

RUN pip install --no-cache-dir ruamel.yaml==0.17.32 && \
    python sync_util.py images chart/helm/spark-on-k8s/release-images.yaml chart/helm/spark-on-k8s/values.yaml && \
    python sync_util.py images chart/helm/spark-on-k8s/release-images.yaml chart/helm/spark-on-k8s/charts/spark-history-server/values.yaml && \
    python sync_util.py images chart/helm/spark-on-k8s/release-images.yaml chart/helm/spark-on-k8s/charts/spark-thrift-server/values.yaml && \
    python sync_util.py images chart/helm/spark-on-k8s/release-images.yaml chart/helm/spark-on-k8s/charts/spark-integration-tests/values.yaml && \
    python sync_util.py qubership-spark-operator chart/helm/spark-on-k8s/release-images.yaml chart/helm/spark-on-k8s/charts/spark-operator/values.yaml && \
    python update_charts.py

FROM scratch

COPY --from=unpacker --chmod=0777 /app/chart /chart
