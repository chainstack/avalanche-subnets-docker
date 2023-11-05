ARG AVALANCHE_REPO="https://github.com/ava-labs/avalanchego.git"
ARG AVALANCHE_RELEASE="v1.10.14"

ARG AVALANCHE_SUBNETS_REPO="https://github.com/ava-labs/subnet-evm"
ARG AVALANCHE_SUBNETS_RELEASE="v0.5.8"

ARG AVALANCHE_SUBNETS_NETWORKS_REPO="https://github.com/ava-labs/public-chain-assets"
ARG AVALANCHE_SUBNETS_NETWORKS_RELEASE="main"

ARG DFK_ETH_CHAIN_ID="53935"
ARG DFK_VM_ID="mDV3QWRXfwgKUWb9sggkv4vQxAQR4y2CyKrt5pLZ5SzQ7EHBv"
ARG DFK_BLOCKCHAIN_ID="q2aTwKuyzgs8pynF7UXBZCU7DejbZbZ6EUyHr3JQzYgwNPUPi"

ARG SWIMMER_ETH_CHAIN_ID="73772"
ARG SWIMMER_VM_ID="srSGD5JeYhL8GLx4RUw53VN5TcoBbax6EeCYmy5S3DiteJhdF"
ARG SWIMMER_BLOCKCHAIN_ID="2K33xS9AyP9oCDiHYKVrHe7F54h2La5D8erpTChaAhdzeSu2RX"

ARG SHRAPNEL_VM_ID="spwf44sL7fXJDwxthqSH9S255fgLRZP9eTFpuAGaE8Q7PyZjL"

FROM golang:1.20.10 AS builder

ARG AVALANCHE_REPO
ARG AVALANCHE_RELEASE

ARG AVALANCHE_SUBNETS_REPO
ARG AVALANCHE_SUBNETS_RELEASE

ARG AVALANCHE_SUBNETS_NETWORKS_REPO
ARG AVALANCHE_SUBNETS_NETWORKS_RELEASE

ARG DFK_VM_ID
ARG SWIMMER_VM_ID
ARG SHRAPNEL_VM_ID

RUN apt-get update && \
    apt-get install -y --no-install-recommends musl-dev=1.2.3-1

# Build Avalanche
WORKDIR /avalanchego

RUN git clone --depth 1 -b ${AVALANCHE_RELEASE} ${AVALANCHE_REPO} .

RUN go mod download

RUN ./scripts/build.sh

# Build subnets
WORKDIR /subnet-evm

RUN git clone --depth 1 -b ${AVALANCHE_SUBNETS_RELEASE} ${AVALANCHE_SUBNETS_REPO} .

RUN ./scripts/build.sh /avalanchego/build/plugins/${DFK_VM_ID}
RUN ./scripts/build.sh /avalanchego/build/plugins/${SWIMMER_VM_ID}
RUN cp /avalanchego/build/plugins/${SWIMMER_VM_ID} /avalanchego/build/plugins/${SHRAPNEL_VM_ID}

RUN git clone --depth 1 -b ${AVALANCHE_SUBNETS_NETWORKS_RELEASE} ${AVALANCHE_SUBNETS_NETWORKS_REPO}

FROM debian:bookworm-slim as execution

ARG DFK_ETH_CHAIN_ID
ARG DFK_BLOCKCHAIN_ID

ARG SWIMMER_ETH_CHAIN_ID
ARG SWIMMER_BLOCKCHAIN_ID

WORKDIR /avalanchego/build

COPY --from=builder /avalanchego/build/ .

# Copy upgrade.json
COPY --from=builder /subnet-evm/public-chain-assets/chains/${DFK_ETH_CHAIN_ID}/upgrade.json /home/${DFK_BLOCKCHAIN_ID}/upgrade.json
COPY --from=builder /subnet-evm/public-chain-assets/chains/${SWIMMER_ETH_CHAIN_ID}/upgrade.json /home/${SWIMMER_BLOCKCHAIN_ID}/upgrade.json

ENTRYPOINT ["./avalanchego"]
