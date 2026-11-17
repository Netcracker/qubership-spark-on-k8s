ARG base_img=ghcr.io/netcracker/qubership-spark-customized:main

FROM $base_img

USER root

RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        mailcap \
        mime-support \
        tzdata \
        zlib1g \
        libbz2-1.0 \
        libdb5.3 \
        libexpat1 \
        libffi8 \
        liblzma5 \
        libncursesw6 \
        libreadline8 \
        libsqlite3-0 \
        libssl3 \
        libtinfo6 \
        libuuid1 \
        libzstd1; \
    mkdir tempdebs; \
    cd tempdebs; \
    curl -fsSLO https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu/pool/main/p/python3.14/libpython3.14_3.14.10-1+jammy1_amd64.deb; \
    curl -fsSLO https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu/pool/main/p/python3.14/libpython3.14-stdlib_3.14.10-1+jammy1_amd64.deb; \
    curl -fsSLO https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu/pool/main/p/python3.14/python3.14_3.14.10-1+jammy1_amd64.deb; \
    curl -fsSLO https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu/pool/main/p/python3.14/python3.14-venv_3.14.10-1+jammy1_amd64.deb; \
    cd ..; \
    dpkg -R --install tempdebs/; \
    rm -r tempdebs; \
    python3.14 -m ensurepip --upgrade; \
    rm -rf /var/lib/apt/lists/*; \
    ln -sf python3.14 /usr/bin/python3

USER spark
