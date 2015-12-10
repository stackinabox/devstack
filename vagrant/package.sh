#!/usr/bin/env sh

mkdir -p ../images
vagrant package --base stackinabox --output ../images/stackinabox.box
cp ../demo_key.priv images/

