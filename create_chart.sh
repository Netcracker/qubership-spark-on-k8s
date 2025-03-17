#!/bin/bash

mkdir -p ./target/chart
cp -R chart/helm/* ./target/chart
mkdir ./target/chart/spark-on-k8s/charts
curl -s -L https://github.com/kubeflow/spark-operator/releases/download/v2.1.0/spark-operator-2.1.0.tgz | tar xvz -C ./target/chart/spark-on-k8s/charts
cp -R spark-history-server/chart/helm/* ./target/chart/spark-on-k8s/charts
cp -R spark-service-integration-tests/chart/helm/* ./target/chart/spark-on-k8s/charts
cp -R spark-thrift-server/chart/helm/* ./target/chart/spark-on-k8s/charts