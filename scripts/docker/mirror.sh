#!/bin/bash

cat >> /etc/default/docker <<EOF
DOCKER_OPTS="-H tcp://192.168.27.100:2375 -H unix:///var/run/docker.sock -D --dns 8.8.8.8 --dns 8.8.4.4 --userland-proxy=false --registry-mirror=http://192.168.27.100:4000 --insecure-registry=192.168.27.100:4000 --disable-legacy-registry"
EOF
service docker restart