#!/bin/bash

set -e

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Define the lock file
LOCK_FILE="$SCRIPT_DIR/deployer.lock"

# Check if the lock file exists
if [ -f "$LOCK_FILE" ]; then
  echo "Error: Script is already running" >&2
  exit 1
fi

# Create the lock file
touch "$LOCK_FILE"

# Define a function to remove the cloned directory
cleanup() {
  #  if [ -d "$NEW_VERSION" ]; then
  #    rm -rf "$NEW_VERSION"
  #  fi
  if [ -f "$LOCK_FILE" ]; then
    rm "$LOCK_FILE"
  fi
}

# Register the cleanup function to be executed when the script exits
trap cleanup EXIT

# Read the variables from the yaml file
#-----------------------------------------------------------------

# Read the current version number from the YAML file
if ! CURRENT_VERSION=$(yq e '.version' version.yaml); then
  echo "Error: Failed to read version number from version.yaml" >>error.log 2>&1
  exit 1
else
  echo "Current version: $CURRENT_VERSION"
fi

# Use semver to increment the version number (e.g. from "1.0.0" to "1.0.1")
if ! NEW_VERSION=$(semver -c -i patch "$CURRENT_VERSION"); then
  echo "Error: Failed to increment version number with semver" >>error.log 2>&1
  exit 1
else
  echo "New version: $NEW_VERSION"
fi

# Read the Docker image name from the YAML file
if ! IMAGE_NAME=$(yq e '.image' version.yaml); then
  echo "Error: Failed to read image name from version.yaml" >>error.log 2>&1
  exit 1
else
  echo "Image: $IMAGE_NAME:$NEW_VERSION"
fi

# Read the Git Repository  from the YAML file
if ! GIT_REPO=$(yq e '.git.url' version.yaml); then
  echo "Error: Failed to read git repo from version.yaml" >>error.log 2>&1
  exit 1
else
  echo "GIT Repo: $GIT_REPO"
fi

# Read the default Git branch  from the YAML file else fall back to develop
if ! GIT_BRANCH=$(yq e '.git.defaultBranch' version.yaml); then
  echo "Info\t: Using develop branch as default"
  GIT_BRANCH='develop'
fi

# Parse command line arguments
while getopts "r:b:" opt; do
  case "${opt}" in
  b) GIT_BRANCH="${OPTARG}" ;;
  *) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done
echo "GIT Branch: $GIT_BRANCH"

# Clone the git to current repository
# ---------------------------------------------------------------

if ! git clone -b "$GIT_BRANCH" "$GIT_REPO" "$NEW_VERSION"; then
  echo "Error: Failed to clone Git repository." >>error.log 2>&1
  if [ -d "$NEW_VERSION" ]; then
    echo "Folder already exists." >>error.log 2>&1
  else
    exit 1
  fi
else
  echo "Cloned successfully"
fi

# Copy dependencies to the application
# ---------------------------------------------------------------
cp -r shared "$NEW_VERSION"
echo "Copied shared files"

cd "$NEW_VERSION"

# Build docker image
# ----------------------------------------------------------------

# Build the Docker image
if ! docker build -t "$IMAGE_NAME:$NEW_VERSION" .; then
  echo "Error: Failed to build Docker image"
  exit 1
else
  echo "Image built successfully"
fi

# Tag the Docker image as "latest"
if ! docker tag "$IMAGE_NAME:$NEW_VERSION" "$IMAGE_NAME:latest"; then
  echo "Error: Failed to tag Docker image as latest"
  exit 1
else
  echo "Image tagged as latest successfully"
fi

# Push the Docker image to a registry
if ! docker push "$IMAGE_NAME:$NEW_VERSION"; then
  echo "Error: Failed to push Docker image to registry"
  exit 1
else
  echo "Image pushed to DockerHub successfully"
fi

if ! docker push "$IMAGE_NAME:latest"; then
  echo "Error: Failed to push latest Docker image to registry"
  exit 1
else
  echo "Image pushed to DockerHub with tag latest successfully"
fi

# Clean Up
# ------------------------------------------------------------------

cd ../
# Update the version number in the YAML file
if ! yq e -i '.version = "'$(echo $NEW_VERSION)'"' version.yaml; then
  echo "Error: Failed to update version number in version.yaml"
  exit 1
fi

if [ -f error.log ]; then
  rm error.log
fi

echo "Script completed successfully."
