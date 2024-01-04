# Use OpenShift golang builder image
# These images needs to be synced with the images in the Makefile.
ARG BUILDER_IMAGE=${BUILDER_IMAGE:-registry.access.redhat.com/ubi8/go-toolset:1.19.13-2.1698062273}
ARG TARGET_IMAGE=${TARGET_IMAGE:-registry.access.redhat.com/ubi9/ubi-minimal:latest}
FROM ${BUILDER_IMAGE} AS builder

WORKDIR /workspace

COPY Makefile Makefile
COPY hack hack/
COPY PROJECT PROJECT
COPY go.mod go.mod
COPY go.sum go.sum
COPY main.go main.go
COPY api api/
COPY config config/
COPY controllers controllers/

RUN go mod download
# needed for docker build but not for local builds
RUN go mod vendor

RUN make build

# Use OpenShift base image
FROM ${TARGET_IMAGE}
WORKDIR /
COPY --from=builder /workspace/bin/manager .
COPY --from=builder /workspace/config/peerpods /config/peerpods

USER 499:499
ENTRYPOINT ["/manager"]
