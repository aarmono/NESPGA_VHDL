FROM ghdl/ghdl:7.0.0-dev-llvm-ubuntu-22.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        make \
        python3-minimal && \
    rm -rf /var/lib/apt/lists/*

# The makefiles from ghdl gen-makefile depend on the prebuilt standard
# libraries, with a rule that fails if make thinks one needs rebuilding. Some
# images have the library sources newer than the libraries, so touch the
# libraries to keep make from trying to rebuild them
RUN find /opt/ghdl/lib/ghdl -path /opt/ghdl/lib/ghdl/src -prune -o \
        -type f -exec touch {} +
