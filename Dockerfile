FROM jupyter/tensorflow-notebook:1af3089901bb

USER root

# Set WORKDIR
WORKDIR /

# These apt-get packages are the only unpinned dependencies, so they are presumably
# the only elements in the image build process that introduce the risk of
# non-reproducibility. That is, they could in theory change in a way that
# caused subsequent builds of the docker image to function differently.

# Install related packages and set LLVM 3.8 as the compiler
# Some of these packages are needed for swift-tensorflow,not just plain old swift and iSwift
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

# RUN apt-get update && \
# apt-get -y install build-essential

# Install ZMQ, needed to build and run the the iSwift kernel
RUN cd /tmp/ \
    && curl -L -O https://github.com/zeromq/zeromq4-1/releases/download/v4.1.4/zeromq-4.1.4.tar.gz \
    && tar xf /tmp/zeromq-4.1.4.tar.gz \
    && cd /tmp/zeromq-4.1.4 \
    && ./configure --without-libsodium \
    && make \
    && make install \
    && ldconfig

#
# Fetch, build, and install the Swift 4.1 release, which we need
# to build iSwift
#

# Everything up to here should cache nicely between Swift versions, assuming dev dependencies change little
ARG SWIFT_PLATFORM=ubuntu16.04
ARG SWIFT_BRANCH=swift-4.1-release
ARG SWIFT_VERSION=swift-4.1-RELEASE

ENV SWIFT_PLATFORM=$SWIFT_PLATFORM \
    SWIFT_BRANCH=$SWIFT_BRANCH \
    SWIFT_VERSION=$SWIFT_VERSION

# Download GPG keys, signature and Swift package, then unpack, cleanup and execute permissions for foundation libs
RUN SWIFT_URL=https://swift.org/builds/$SWIFT_BRANCH/$(echo "$SWIFT_PLATFORM" | tr -d .)/$SWIFT_VERSION/$SWIFT_VERSION-$SWIFT_PLATFORM.tar.gz \
    && curl -fSsL $SWIFT_URL -o swift.tar.gz \
    && curl -fSsL $SWIFT_URL.sig -o swift.tar.gz.sig \
    && export GNUPGHOME="$(mktemp -d)" \
    && set -e; \
        for key in \
      # pub   rsa4096 2017-11-07 [SC] [expires: 2019-11-07]
      # 8513444E2DA36B7C1659AF4D7638F1FB2B2B08C4
      # uid           [ unknown] Swift Automatic Signing Key #2 <swift-infrastructure@swift.org>
          8513444E2DA36B7C1659AF4D7638F1FB2B2B08C4 \
      # pub   4096R/91D306C6 2016-05-31 [expires: 2018-05-31]
      #       Key fingerprint = A3BA FD35 56A5 9079 C068  94BD 63BC 1CFE 91D3 06C6
      # uid                  Swift 3.x Release Signing Key <swift-infrastructure@swift.org>
          A3BAFD3556A59079C06894BD63BC1CFE91D306C6 \
      # pub   4096R/71E1B235 2016-05-31 [expires: 2019-06-14]
      #       Key fingerprint = 5E4D F843 FB06 5D7F 7E24  FBA2 EF54 30F0 71E1 B235
      # uid                  Swift 4.x Release Signing Key <swift-infrastructure@swift.org>
          5E4DF843FB065D7F7E24FBA2EF5430F071E1B235 \
        ; do \
          gpg --quiet --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
        done \
    && gpg --batch --verify --quiet swift.tar.gz.sig swift.tar.gz \
    && tar -xzf swift.tar.gz --directory / --strip-components=1 \
    && rm -r "$GNUPGHOME" swift.tar.gz.sig swift.tar.gz \
    && chmod -R o+r /usr/lib/swift

# Print Installed Swift Version
RUN swift --version


#
# Fetch, and build swift-tensorflow, the version for
# fancy interop with tensorflow
#
USER root
RUN mkdir -p /swiftdev
WORKDIR /swiftdev
RUN mkdir -p swift-tensorflow-toolchain/usr

ENV SWIFT_TF_PLATFORM=ubuntu16.04
ENV SWIFT_TF_VERSION=swift-tensorflow-DEVELOPMENT-2018-06-01-a

ENV SWIFT_TF_URL=https://storage.googleapis.com/swift-tensorflow/$SWIFT_TF_PLATFORM/$SWIFT_TF_VERSION-$SWIFT_TF_PLATFORM.tar.gz 
RUN SWIFT_TF_URL=https://storage.googleapis.com/swift-tensorflow/$SWIFT_TF_PLATFORM/$SWIFT_TF_VERSION-$SWIFT_TF_PLATFORM.tar.gz 
RUN curl -fSsL $SWIFT_TF_URL -o swift.tar.gz 
RUN tar -xzvf swift.tar.gz --directory swift-tensorflow-toolchain
#RUN rm -r  swift.tar.gz 
RUN chmod -R o+r swift-tensorflow-toolchain/usr
RUN chown -R ${NB_USER} /swiftdev

RUN echo  "swift-tensorflow bin at: /swiftdev/swift-tensorflow-toolchain/usr/bin" 

#
# Fetch and install swift-sdk for Watson APIs 
# not installed for Swift-TensorFlow Kernel
#
WORKDIR /
RUN git clone https://github.com/watson-developer-cloud/swift-sdk.git
WORKDIR /swift-sdk
RUN swift package update
RUN swift build -Xswiftc -O
RUN cp -R .build/x86_64-unknown-linux/debug/* /usr/lib/swift/linux/x86_64/

WORKDIR /
# Print Installed Swift Version
RUN swift --version

# Build iSwift
RUN mkdir -p /kernels/iSwift
# copy only the Swift package itself and iSwiftKernel, so that we don't
# trigger image rebuilds when we edit docs or pieces of the Dockerfile
# itself which are irrelevant to the image
COPY Includes /kernels/iSwift/Includes/
COPY Package.swift /kernels/iSwift/
COPY Sources /kernels/iSwift/Sources/
COPY iSwiftKernel /kernels/iSwift/iSwiftKernel/
COPY iSwiftTensorFlowKernel /kernels/iSwift/iSwiftTensorFlowKernel/
WORKDIR /kernels/iSwift
RUN swift package update
RUN swift build -Xswiftc -O

# install the iSwift kernelspec into jupyter as the NB_USER
# install the iSwiftTensorFlow kernelspec into jupyter as the NB_USER
USER ${NB_USER}
RUN jupyter kernelspec install --user /kernels/iSwift/iSwiftKernel
RUN jupyter kernelspec install --user /kernels/iSwift/iSwiftTensorFlowKernel

# Change the Swift kernel executable to be onwed by NB_USER, so we can run it
USER root
RUN chown -R ${NB_USER} /kernels/iSwift
#RUN conda create -n py27 python=2.7 anaconda 
#RUN /bin/bash -c "source activate py27 && pip install ipykernel && conda install numpy && python -m ipykernel install"


USER $NB_USER

RUN mkdir /home/${NB_USER}/workspace
WORKDIR /home/${NB_USER}/workspace
