#!/bin/bash
set -e

docker run -d --net=gpdb -h monitor -p "9000:9000" harbor.inventec.com/development/gpdbmasterha:latest