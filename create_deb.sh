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

# Check if rosdep is initialized
if ! rosdep db 2>/dev/null; then
    echo "rosdep not initialized. Initializing..."
    rosdep init || { echo "Failed to initialize rosdep"; exit 1; }
else
    echo "rosdep already initialized."
fi

# Update rosdep database
echo "Updating rosdep database..."
rosdep update || { echo "Failed to update rosdep"; exit 1; }

# create debs
bloom-generate rosdebian --os-name ubuntu --os-version $(lsb_release -sc) --ros-distro $ROS_DISTRO
fakeroot debian/rules binary


