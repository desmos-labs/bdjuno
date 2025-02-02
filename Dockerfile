# To build the DJuno image, just run:
# > docker build -t bdjuno .
#
# In order to work properly, this Docker container needs to have a volume that:
# - as source points to a directory which contains a config.yaml file
# - as destination it points to the /home folder
#
# Simple usage with a mounted data directory (considering ~/.bdjuno/config as the configuration folder):
# > docker run -it -v ~/.bdjuno/config:/home djuno djuno parse
#
# If you want to run this container as a daemon, you can do so by executing
# > docker run -td -v ~/.bdjuno/config:/home --name bdjuno bdjuno
#
# Once you have done so, you can enter the container shell by executing
# > docker exec -it bdjuno bash
#
# To exit the bash, just execute
# > exit
FROM golang:1.20-alpine as builder
ARG arch=x86_64

# Set up dependencies
ENV PACKAGES curl make git libc-dev bash gcc linux-headers eudev-dev python3 ca-certificates build-base
RUN set -eux; apk add --no-cache $PACKAGES;

# Set working directory for the build
WORKDIR /code

# Add source files
COPY . /code/

# See https://github.com/CosmWasm/wasmvm/releases
ADD https://github.com/CosmWasm/wasmvm/releases/download/v1.3.0/libwasmvm_muslc.aarch64.a /lib/libwasmvm_muslc.aarch64.a
RUN sha256sum /lib/libwasmvm_muslc.aarch64.a | grep b1610f9c8ad8bdebf5b8f819f71d238466f83521c74a2deb799078932e862722

ADD https://github.com/CosmWasm/wasmvm/releases/download/v1.3.0/libwasmvm_muslc.x86_64.a /lib/libwasmvm_muslc.x86_64.a
RUN sha256sum /lib/libwasmvm_muslc.x86_64.a | grep b4aad4480f9b4c46635b4943beedbb72c929eab1d1b9467fe3b43e6dbf617e32

# Copy the library you want to the final location that will be found by the linker flag `-lwasmvm_muslc`
RUN cp /lib/libwasmvm_muslc.${arch}.a /usr/local/lib/libwasmvm_muslc.a

# force it to use static lib (from above) not standard libgo_cosmwasm.so file
RUN BUILD_TAGS=muslc GOOS=linux GOARCH=amd64 LINK_STATICALLY=true make build
RUN echo "Ensuring binary is statically linked ..." && (file /code/build/bdjuno | grep "statically linked")

FROM alpine:latest

# Set up dependencies
RUN apk update && apk add --no-cache ca-certificates build-base

# Copy the binary
COPY --from=builder /code/build/bdjuno /usr/bin/bdjuno

CMD ["bdjuno"]