FROM ubuntu:18.04

RUN apt-get update && apt-get install -y \
    autoconf \
    bison \
    build-essential \
    gawk \
    git \
    libprotobuf-c-dev \
    protobuf-c-compiler \
    python \
    python3-protobuf \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /graphene
COPY . /graphene
WORKDIR /graphene

# Build Linux version
RUN make -j$(nproc)

# Build Linux-SGX version
# No need to actually build the gsgx driver. We will be using the module
# installed at host. We just need to generate relavent headers.
RUN git clone https://github.com/intel/linux-sgx-driver /sgx-driver
RUN cd Pal/src/host/Linux-SGX/sgx-driver \
    && (echo "/sgx-driver"; echo "2.6") | make || true
RUN make SGX=1 -j$(nproc)

# Generate default signing key
RUN cd Pal/src/host/Linux-SGX/signer && openssl genrsa -3 -out enclave-key.pem 3072
