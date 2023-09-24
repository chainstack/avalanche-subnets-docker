ARG AVALANCHE_REPO="https://github.com/ava-labs/avalanchego.git"
ARG AVALANCHE_RELEASE="v1.10.10"

ARG AVALANCHE_SUBNETS_REPO="https://github.com/ava-labs/subnet-evm"
ARG AVALANCHE_SUBNETS_RELEASE="v0.5.4"

ARG AVALANCHE_SUBNETS_NETWORKS_REPO="https://github.com/ava-labs/public-chain-assets"
ARG AVALANCHE_SUBNETS_NETWORKS_RELEASE="main"

ARG PLAYA3ULL_BLOCKCHAIN_ID="k2SFEZ2MZr9UGXiycnA1DdaLqZTKDaHK7WUXVLhJk5F9DD8r1"
ARG PLAYA3ULL_VM_ID="cN6t22ptqzNhvvB66z25f2eZXK92PR62fxoVYRzDw1hWsMZt2"
ARG PLAYA3ULL_SUBNET_ID="2wLe8Ma7YcUmxMJ57JVWETMSHz1mjXmJc5gmssvKm3Pw8GkcFq"

FROM golang:1.20.8 AS builder

ARG AVALANCHE_REPO
ARG AVALANCHE_RELEASE

ARG AVALANCHE_SUBNETS_REPO
ARG AVALANCHE_SUBNETS_RELEASE

ARG AVALANCHE_SUBNETS_NETWORKS_REPO
ARG AVALANCHE_SUBNETS_NETWORKS_RELEASE

ARG PLAYA3ULL_VM_ID

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
RUN ./scripts/build.sh /avalanchego/build/plugins/${PLAYA3ULL_VM_ID}
RUN git clone --depth 1 -b ${AVALANCHE_SUBNETS_NETWORKS_RELEASE} ${AVALANCHE_SUBNETS_NETWORKS_REPO}

FROM debian:bookworm-slim as execution

ARG PLAYA3ULL_BLOCKCHAIN_ID
ARG PLAYA3ULL_SUBNET_ID

WORKDIR /avalanchego/build

COPY --from=builder /avalanchego/build/ .

ENTRYPOINT ["./avalanchego"]
