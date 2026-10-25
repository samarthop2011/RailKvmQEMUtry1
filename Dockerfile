
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/root \
    SHELL=/bin/bash \
    LANG=C.UTF-8 \
    PORT=7860

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git git-lfs openssh-client sudo \
    bash-completion nano vim-tiny less unzip zip xz-utils jq procps \
    python3 python3-pip python3-venv python3-dev \
    build-essential gcc g++ make cmake pkg-config \
    nodejs npm \
    qemu-system-x86 qemu-utils ovmf \
    iproute2 iputils-ping net-tools dnsutils socat \
    && git lfs install \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://code-server.dev/install.sh | sh

RUN mkdir -p /workspace/isos /workspace/vms \
    /root/.config/code-server

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY start-vm.sh /usr/local/bin/start-vm

RUN chmod +x /usr/local/bin/entrypoint.sh \
    /usr/local/bin/start-vm

WORKDIR /workspace

EXPOSE 7860

USER root
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
