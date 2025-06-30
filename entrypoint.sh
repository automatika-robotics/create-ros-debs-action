#!/bin/bash

set -e  # Exit on failure
set -u  # Exit on undefined behavior

echo "[+] Starting create ROS debs action"

# Check if in a git repository
if [ -d .git ]
then
    echo '[+] Found source repo: '$(pwd)
else
    echo "::error:: Source repository not found"
    echo "::error:: You can checkout the source repository using a github action in the previous step of this workflow as follow:"
    echo "::error:: uses: actions/checkout@v4"
    exit 1
fi

get_versions_with_future_eol() {
    # Make the web call and store the response in a variable
    local response=$(curl -s "https://endoflife.date/api/ros-2.json")

    # Check if the curl request was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to retrieve ROS2 versions from external API. Please run the action again. If failure persists, please open an issue."
        exit 1
    fi

    # Get today's date in YYYY-MM-DD format
    local today=$(date +%Y-%m-%d)

    # Use jq to filter and process the JSON response
    local cycles=$(echo "$response" | jq --arg today "$today" '
        .[] | select(.eol > $today) | .cycle
    ')
}

# Read the second argument as the source directory with package.xml
SOURCE_DIR="$1"
# Read the third argument as the target directory
TARGET_DIR="$2"

# Check if the versions argument is provided, otherwise use the function
if [ -z "$3" ]; then
    ROS2_VERSIONS=$(get_versions_with_future_eol)
else
    IFS=' ' read -r -a ROS2_VERSIONS <<< "$2"
fi

echo "[+] Source Directory: $SOURCE_DIR"
echo "[+] Target Directory: $TARGET_DIR"
echo "[+] ROS2 Versions: ${ROS2_VERSIONS[@]}"


# Move to source folder
cd "$(dirname "$SOURCE_DIR")"

# Make target dir
echo "[+] Creating folder: $TARGET_DIR"
mkdir -p $TARGET_DIR

# Loop through each ROS2 version
for version in "${ROS2_VERSIONS[@]}"; do

  ## Build ##
  echo "[+] Starting build container for ROS2 version: $version"
  docker run -v "/var/run/docker.sock":"/var/run/docker.sock" -i -d -e ROS_DISTRO=$version --name ros-build-$version ros:$version-ros-base

  echo "[+] Copying project files"
  docker cp . ros-build-$version:/project

  echo "[+] Copying deb creation script"
  docker cp /create_deb.sh ros-build-$version:/create_deb.sh

  echo "[+] Running deb creation script"
  docker exec -i ros-build-$version /bin/sh "/create_deb.sh"

  # Get deb file name
  DEB_NAME=$(docker exec ros-build-$version /bin/sh -c 'ls *.deb')

  echo "[+] Copying created deb"
  docker cp ros-build-$version:$DEB_NAME ./debs/

  echo "[+] Deleting build container for ROS2 version: $version"
  docker stop ros-build-$version
  docker rm ros-build-$version

  ## Test ##
  echo "[+] Starting test container for ROS2 version: $version"
  docker run -v "/var/run/docker.sock":"/var/run/docker.sock" -i -d -e ROS_DISTRO=$version --name ros-test-$version ros:$version-ros-base

  echo "[+] Copying deb for testing"
  docker cp debs/$DEB_NAME ros-test-$version:/

  # Install package
  docker exec ros-test-$version /bin/sh -c "apt update && apt install -y python3-pip"
  docker exec ros-test-$version /bin/sh -c "rosdep update --include-eol-distros"
  docker exec ros-test-$version /bin/sh -c "apt install -y ./$DEB_NAME"

  # TODO: Add provision for running tests

  echo "[+] Deleting test container for ROS2 version: $version"
  docker stop ros-test-$version
  docker rm ros-test-$version

done
