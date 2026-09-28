ARG GO_IMAGE=golang:1.25-bookworm

FROM ${GO_IMAGE} AS builder

ARG SOURCE_REPOSITORY
ARG SOURCE_COMMIT
ARG TARGETARCH
ARG SOURCE_RELEASE

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# BuildKit network access is used only in this controlled build stage.
# SOURCE_COMMIT must be an immutable full Git SHA. Verify the checkout so a
# moved branch or tag cannot silently change the generated artifact.
RUN git clone --filter=blob:none "${SOURCE_REPOSITORY}" source \
    && cd source \
    && git checkout --detach "${SOURCE_COMMIT}" \
    && test "$(git rev-parse HEAD)" = "${SOURCE_COMMIT}"

WORKDIR /src/source

ENV CGO_ENABLED=0 \
    GOOS=linux \
    MINIO_RELEASE="${SOURCE_RELEASE}" \
    MC_RELEASE="${SOURCE_RELEASE}"

# MinIO and mc provide gen-ldflags.go to generate their own version metadata.
# Generate the flags for the native build host before setting GOARCH for the
# cross-compiled target binary.
RUN LDFLAGS="$(go run buildscripts/gen-ldflags.go)" \
    && GOARCH="${TARGETARCH}" go build \
        -trimpath \
        -buildvcs=true \
        -ldflags="${LDFLAGS}" \
        -o /out/binary \
        .