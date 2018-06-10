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
# Fetch, and build swift-tensorflow, the version for
# fancy interop with tensorflow
#
ENV SWIFT_TF_PLATFORM=ubuntu16.04
ENV SWIFT_TF_VERSION=swift-tensorflow-DEVELOPMENT-2018-06-01-a

ENV SWIFT_TF_URL=https://storage.googleapis.com/swift-tensorflow/$SWIFT_TF_PLATFORM/$SWIFT_TF_VERSION-$SWIFT_TF_PLATFORM.tar.gz 
RUN SWIFT_TF_URL=https://storage.googleapis.com/swift-tensorflow/$SWIFT_TF_PLATFORM/$SWIFT_TF_VERSION-$SWIFT_TF_PLATFORM.tar.gz 
RUN curl -fSsL $SWIFT_TF_URL -o swift.tar.gz 
WORKDIR /
RUN tar -xzvf swift.tar.gz --directory / 
RUN ls -al /usr/lib
#RUN rm -r  swift.tar.gz 
RUN chmod -R o+r /usr/lib/swift

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

COPY iSwiftTensorFlowKernel /kernels/iSwift/iSwiftTensorFlowKernel/
WORKDIR /kernels/iSwift
RUN swift package update
RUN swift build -Xswiftc -O

# install the iSwift kernelspec into jupyter as the NB_USER
# install the iSwiftTensorFlow kernelspec into jupyter as the NB_USER
USER ${NB_USER}

RUN jupyter kernelspec install --user /kernels/iSwift/iSwiftTensorFlowKernel

# Change the Swift kernel executable to be onwed by NB_USER, so we can run it
USER root
RUN chown -R ${NB_USER} /kernels/iSwift
#RUN conda create -n py27 python=2.7 anaconda 
#RUN /bin/bash -c "source activate py27 && pip install ipykernel && conda install numpy && python -m ipykernel install"


USER $NB_USER

RUN mkdir /home/${NB_USER}/workspace
WORKDIR /home/${NB_USER}/workspace
