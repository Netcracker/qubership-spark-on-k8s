ARG base_img=ghcr.io/netcracker/qubership-spark-customized:main

FROM $base_img

USER root

RUN set -ex; \
    apt-get update; \
    mkdir tempdebs; \
    cd tempdebs; \
    curl -sLO https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu/pool/main/p/python3.14/libpython3.14_3.14.10-1+jammy1_amd64.deb; \
    curl -sLO https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu/pool/main/p/python3.14/libpython3.14-stdlib_3.14.10-1+jammy1_amd64.deb; \
    curl -sLO https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu/pool/main/p/python3.14/python3.14_3.14.10-1+jammy1_amd64.deb; \
    curl -sLO https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu/pool/main/p/python3.14/python3.14-venv_3.14.10-1+jammy1_amd64.deb; \
    cd ..; \
    apt-get install -y mailcap mime-support; \
    dpkg -R --install tempdebs/; \
    rm -r tempdebs; \
    python3.14 -m ensurepip --upgrade; \
    rm -rf /var/lib/apt/lists/*; \
    ln -sf python3.14 /usr/bin/python3

USER spark
