# TODO

## Segregate Swift project dir from the repo root

This will stop the build process from mistakenly capturing all changes
in this repo

## Integrate tensorflow

Plan:

1. base Dockerfile on tensorflow-notebook
2. Use instructions at
   https://github.com/tensorflow/swift/blob/master/Installation.md to
   grab swift-tensorflow instead of plain old swift
3. etc

# Log

## 2018-05-01T0609 packaging for dockerhub

## 2018-05-01T1028 trying to switch to base tensorflow

something in the Dockerfile base tensorflow breaks import of tensorflow even for Py3 notebooks

done

## 2018-05-01T1103 downloading and installing swift-tensorflow

trying to build image with swift-ternsorflow

building project iSwiftKernel with swift-tensorflow fails







