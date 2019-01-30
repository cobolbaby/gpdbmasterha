#!/bin/bash
set -e
cd `dirname $0`

REGISTRY=harbor.inventec.com

docker build --rm -f Dockerfile -t ${REGISTRY}/development/gpdbmasterha:latest --build-arg http_proxy=${PROXY} --build-arg https_proxy=${PROXY} .
docker push ${REGISTRY}/development/gpdbmasterha:latest