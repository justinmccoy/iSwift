#!/bin/sh
exec docker run --rm --privileged -v /Users/ibm/Desktop/demo/:/home/jovyan/workspace --cap-add=SYS_PTRACE --security-opt seccomp:unconfined -p 8888:8888 sholmes/swift-tensorflow-notebook
