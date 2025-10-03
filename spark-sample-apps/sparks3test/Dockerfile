ARG base_img_py=ghcr.io/netcracker/qubership-spark-customized-py:main
FROM $base_img_py

USER root

WORKDIR /opt/spark/examples/

COPY --chmod=0777 s3_read_test.py /opt/spark/examples/

COPY --chmod=0755 entrypoint.sh /opt/spark/entrypoint.sh

USER spark

ENTRYPOINT ["/opt/spark/entrypoint.sh"]
