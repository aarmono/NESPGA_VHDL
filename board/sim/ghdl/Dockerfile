FROM ghdl/ghdl:7.0.0-dev-llvm-ubuntu-22.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        make \
        python3-minimal && \
    rm -rf /var/lib/apt/lists/*
