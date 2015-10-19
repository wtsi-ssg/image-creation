#!/bin/bash

echo scripts/compiler_tools.sh
#sleep 999999
apt-get update
apt-get -y install alien quilt kernel-package fakeroot subversion autotools-dev   module-assistant cvs  automake libtool linux-headers-$(uname -r)  git

# Install kernel packages for binary builds
apt-get -y install linux-image-3.2.0-75-generic linux-headers-3.2.0-75-generic linux-tools-3.2.0-75 linux-image-3.8.0-44-generic linux-headers-3.8.0-44-generic linux-tools-3.8.0-44

# needed for AWS instance
apt-get -y install dkms

