ARG AVALANCHE_REPO="https://github.com/ava-labs/avalanchego.git"
ARG AVALANCHE_RELEASE="v1.10.19"

ARG AVALANCHE_SUBNETS_REPO="https://github.com/hubble-exchange/hubblenet"
ARG AVALANCHE_SUBNETS_RELEASE="v0.9.1"

ARG AVALANCHE_SUBNETS_NETWORKS_REPO="https://github.com/ava-labs/public-chain-assets"
ARG AVALANCHE_SUBNETS_NETWORKS_RELEASE="main"

ARG HUBBLE_BLOCKCHAIN_ID="2jfjkB7NkK4v8zoaoWmh5eaABNW6ynjQvemPFZpgPQ7ugrmUXv"
ARG HUBBLE_VM_ID="o1Fg94YujMqL75Ebrdkos95MTVjZpPpdeAp5ocEsp2X9c2FSz"
ARG HUBBLE_SUBNET_ID="2mxZY7A2t1tuRMALW4BcBUPVGNR3LH1DXhftdbLAHm1QtDkFp8"

FROM golang:1.20.12 AS builder

ARG AVALANCHE_REPO
ARG AVALANCHE_RELEASE

ARG AVALANCHE_SUBNETS_REPO
ARG AVALANCHE_SUBNETS_RELEASE

ARG AVALANCHE_SUBNETS_NETWORKS_REPO
ARG AVALANCHE_SUBNETS_NETWORKS_RELEASE

ARG HUBBLE_VM_ID

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
RUN ./scripts/build.sh /avalanchego/build/plugins/${HUBBLE_VM_ID}

RUN git clone --depth 1 -b ${AVALANCHE_SUBNETS_NETWORKS_RELEASE} ${AVALANCHE_SUBNETS_NETWORKS_REPO}

FROM debian:bookworm-slim as execution

ARG HUBBLE_BLOCKCHAIN_ID
ARG HUBBLE_SUBNET_ID

WORKDIR /avalanchego/build

COPY --from=builder /avalanchego/build/ .

ENTRYPOINT ["./avalanchego"]
