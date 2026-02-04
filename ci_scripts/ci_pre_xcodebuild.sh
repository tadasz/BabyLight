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

echo "✅ Pre-xcodebuild script completed"
