#!/bin/sh

# ci_pre_xcodebuild.sh
# Runs before xcodebuild in Xcode Cloud
# Use this script for any pre-build setup

set -e

echo "🏗️ Pre-xcodebuild script started"

# Display build information
echo "📋 Build Configuration:"
echo "  CI_WORKFLOW: ${CI_WORKFLOW:-'Not set'}"
echo "  CI_XCODEBUILD_ACTION: ${CI_XCODEBUILD_ACTION:-'Not set'}"
echo "  CI_PRODUCT_PLATFORM: ${CI_PRODUCT_PLATFORM:-'Not set'}"
echo "  CI_BRANCH: ${CI_BRANCH:-'Not set'}"
echo "  CI_TAG: ${CI_TAG:-'Not set'}"
echo "  CI_COMMIT: ${CI_COMMIT:-'Not set'}"

# Verify test targets exist
if [ "$CI_XCODEBUILD_ACTION" = "test" ] || [ "$CI_XCODEBUILD_ACTION" = "build-for-testing" ]; then
    echo "🧪 Preparing for test run..."
fi

# Build number: Xcode Cloud stamps CFBundleVersion = the run number automatically
# (it overrides CURRENT_PROJECT_VERSION at archive time, so editing the project here
# has no effect). Run numbers only increase, so as long as no build is uploaded
# OUT of band with a higher number, CI build numbers stay monotonic. (A one-off
# local build 1.1(14) was uploaded earlier; run numbers are already past 14.)

echo "✅ Pre-xcodebuild script completed"
