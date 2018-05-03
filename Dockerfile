FROM jupyter/tensorflow-notebook:1af3089901bb
#FROM jupyter/minimal-notebook:1af3089901bb

USER root

# Set WORKDIR
WORKDIR /root

# These apt-get packages are the only unpinned dependencies, so they are presumably
# the only elements in the image build process that introduce the risk of
# non-reproducibility. That is, they could in theory change in a way that
# broke backward compatibility, and caused subsequent builds of the docker image
# to function differently.

# Install related packages and set LLVM 3.8 as the compiler
RUN apt-get -q update && \
    apt-get -q install -y \
    make \
    libc6-dev \
    clang-3.8 \
    curl \
    libedit-dev \
    libpython2.7 \
    libicu-dev \
    libssl-dev \
    libxml2 \
    tzdata \
    git \
    libcurl4-openssl-dev \
    pkg-config \
    libpython-dev \
    libncurses5-dev \
    && update-alternatives --quiet --install /usr/bin/clang clang /usr/bin/clang-3.8 100 \
    && update-alternatives --quiet --install /usr/bin/clang++ clang++ /usr/bin/clang++-3.8 100 \
    && rm -r /var/lib/apt/lists/*

# Everything up to here should cache nicely between Swift versions, assuming dev dependencies change little
ARG SWIFT_PLATFORM=ubuntu16.04
ARG SWIFT_BRANCH=swift-4.1-release
ARG SWIFT_VERSION=swift-tensorflow-DEVELOPMENT-2018-04-26-a

ENV SWIFT_PLATFORM=$SWIFT_PLATFORM \
    SWIFT_BRANCH=$SWIFT_BRANCH \
    SWIFT_VERSION=$SWIFT_VERSION

RUN mkdir -p swift-tensorflow-toolchain/usr

# Download GPG keys, signature and Swift package, then unpack, cleanup and execute permissions for foundation libs
ENV SWIFT_URL=https://storage.googleapis.com/swift-tensorflow/$SWIFT_PLATFORM/$SWIFT_VERSION-$SWIFT_PLATFORM.tar.gz
RUN echo "SWIFT_URL=$SWIFT_URL"
# installing this dev toolchain directly into /usr. Would be tidier to put it in its own dir, but then
# we'd need to update PATH etc as well. Seeing if this is good enough for a container.
# This may be a mistake b/c it's introducing an incompatible mix of llvm and lldb libraries
RUN SWIFT_URL=https://storage.googleapis.com/swift-tensorflow/$SWIFT_PLATFORM/$SWIFT_VERSION-$SWIFT_PLATFORM.tar.gz \
    && curl -fSsL $SWIFT_URL -o swift.tar.gz \
    && tar -xzf swift.tar.gz --directory=swift-tensorflow-toolchain/usr --strip-components=1 \
    && rm -r  swift.tar.gz \
    && chmod -R o+r swift-tensorflow-toolchain/usr

ENV PATH="/root/swift-tensorflow-toolchain/usr/bin:${PATH}"

RUN echo "PATH=$PATH"

# Print Installed Swift Version
RUN swift --version

# RUN apt-get update && \
# apt-get -y install build-essential

# Install ZMQ
RUN cd /tmp/ \
    && curl -L -O https://github.com/zeromq/zeromq4-1/releases/download/v4.1.4/zeromq-4.1.4.tar.gz \
    && tar xf /tmp/zeromq-4.1.4.tar.gz \
    && cd /tmp/zeromq-4.1.4 \
    && ./configure --without-libsodium \
    && make \
    && make install \
    && ldconfig

# Build swift kernel executable as root in /kernels/iSwift
RUN mkdir -p /kernels/iSwift
# copy only the Swift package itself and iSwiftKernel, so that we don't
# trigger image rebuilds when we edit docs or pieces of the Dockerfile
# itself which are irrelevant to the image
COPY Includes /kernels/iSwift/Includes/
COPY Package.swift /kernels/iSwift/
COPY Sources /kernels/iSwift/Sources/
COPY iSwiftKernel /kernels/iSwift/iSwiftKernel/
WORKDIR /kernels/iSwift
RUN swift package update
RUN swift build

# But install the kernelspec into jupyter as the NB_USER
USER ${NB_USER}
RUN jupyter kernelspec install --user /kernels/iSwift/iSwiftKernel

# Change the Swift kernel executable to be onwed by NB_USER, so we can run it
USER root
RUN chown -R ${NB_USER} /kernels/iSwift
USER $NB_USER

USER ${NB_USER}
WORKDIR /home/${NB_USER}
