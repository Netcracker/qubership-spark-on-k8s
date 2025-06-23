FROM alpine:latest AS unpacker

RUN apk add curl
RUN mkdir -p /chart/helm/spark-on-k8s/charts && \
    curl -s -L https://github.com/kubeflow/spark-operator/releases/download/v2.2.0/spark-operator-2.2.0.tgz | tar xvz -C /chart/helm/spark-on-k8s/charts


# Transfer
COPY chart /chart
COPY spark-history-server/chart/helm /chart/helm/spark-on-k8s/charts
COPY spark-service-integration-tests/chart/helm /chart/helm/spark-on-k8s/charts
COPY spark-thrift-server/chart/helm /chart/helm/spark-on-k8s/charts

FROM scratch

COPY --from=unpacker --chmod=0777 /chart/ /chart/