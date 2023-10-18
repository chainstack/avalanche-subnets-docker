ARG AVALANCHE_REPO="https://github.com/ava-labs/avalanchego.git"
ARG AVALANCHE_RELEASE="v1.10.11"

ARG AVALANCHE_SUBNETS_REPO="https://github.com/ava-labs/subnet-evm"
ARG AVALANCHE_SUBNETS_RELEASE="v0.5.6"

ARG AVALANCHE_SUBNETS_NETWORKS_REPO="https://github.com/ava-labs/public-chain-assets"
ARG AVALANCHE_SUBNETS_NETWORKS_RELEASE="main"

ARG HUBBLE_BLOCKCHAIN_ID="2qR64ZGVHTJjTZTzEnQTDoD1oMVQMYFVaBtN5tDoYaDKfVY5Xz"
ARG HUBBLE_VM_ID="jvrKsTB9MfYGnAXtxbzFYpXKceXr9J8J8ej6uWGrYM5tXswhJ"
ARG HUBBLE_SUBNET_ID="t2WSjSsoE3geV9ARu5r7gzTc5UayePy3NxDrSTx7hadLYvqbg"

FROM golang:1.20.8 AS builder

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
