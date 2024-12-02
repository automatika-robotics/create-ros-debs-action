#!/bin/bash

# Exit immediatly on a failed step
set -xe

# Define ROS2 versions to pull
ROS2_VERSIONS=("humble" "iron" "jazzy" "rolling")
TARGET_DIR=debs

# Make target dir
echo "Creating folder: $TARGET_DIR"
mkdir -p $TARGET_DIR

# Loop through each ROS2 version
for version in "${ROS2_VERSIONS[@]}"; do

  ## Build ##
  echo "Starting build container for ROS2 version: $version"
  docker run -v "/var/run/docker.sock":"/var/run/docker.sock" -i -d -e ROS_DISTRO=$version --name ros-build-$version ros:$version-ros-base

  echo "Copying project files"
  docker cp . ros-build-$version:/project

  echo "Copying deb creation script"
  docker cp /create_deb.sh ros-build-$version:/create_deb.sh

  echo "Running deb creation script"
  docker exec -i ros-build-$version /bin/sh "/create_deb.sh"
  # Get deb file name
  DEB_NAME=$(docker exec ros-build-$version /bin/sh -c 'ls *.deb')

  echo "Copying created deb"
  docker cp ros-build-$version:$DEB_NAME ./debs/

  echo "Deleting build container for ROS2 version: $version"
  docker stop ros-build-$version
  docker rm ros-build-$version

  ## Test ##
  echo "Starting test container for ROS2 version: $version"
  docker run -v "/var/run/docker.sock":"/var/run/docker.sock" -i -d -e ROS_DISTRO=$version --name ros-test-$version ros:$version-ros-base

  echo "Copying deb for testing"
  docker cp debs/$DEB_NAME ros-test-$version:/

  # Install package
  docker exec ros-test-$version /bin/sh -c "apt update && apt install -y ./$DEB_NAME"

  # TODO: Add provision for running tests

  echo "Deleting test container for ROS2 version: $version"
  docker stop ros-test-$version
  docker rm ros-test-$version

done

