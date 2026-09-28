ARG GO_IMAGE=golang:1.25-bookworm
FROM ${GO_IMAGE} AS builder
ARG SOURCE_REPOSITORY
ARG SOURCE_COMMIT
ARG TARGETARCH
RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates git \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
# BuildKit network access is used only in this controlled build stage. The commit is
# checked explicitly so a moved branch/tag cannot silently change the artifact.
RUN git clone --filter=blob:none "${SOURCE_REPOSITORY}" source \
    && cd source \
    && git checkout --detach "${SOURCE_COMMIT}" \
    && test "$(git rev-parse HEAD)" = "${SOURCE_COMMIT}"
WORKDIR /src/source
ENV CGO_ENABLED=0 GOOS=linux
RUN GOARCH="${TARGETARCH}" go build -trimpath -buildvcs=true -ldflags='-s -w' -o /out/binary .
