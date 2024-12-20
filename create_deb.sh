#!/bin/bash

# Exit immediatly on a failed step
set -xe

echo "[+] Creating deb files"
apt-get update
apt-get -y install python3-pip python3-bloom
apt-get -y install fakeroot dpkg-dev debhelper

# location specified in container build script
cd /project
lsb_release -sc

bloom-generate rosdebian --os-name ubuntu --os-version $(lsb_release -sc) --ros-distro $ROS_DISTRO

fakeroot debian/rules binary


