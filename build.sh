#!/bin/bash

version=${1:-latest}
docker build -t tgrosinger/code-server:${version} .
