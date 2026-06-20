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

# --- Deterministic, collision-free build number ------------------------------
# By default Xcode Cloud stamps the build number = the run number (CI_BUILD_NUMBER).
# A one-off local build 1.1(14) already exists in App Store Connect, so set the
# build number to the run number + 1 to stay ahead and avoid a duplicate
# version+build pair. CURRENT_PROJECT_VERSION feeds CFBundleVersion because the
# targets use a generated Info.plist (GENERATE_INFOPLIST_FILE = YES).
if [ -n "$CI_BUILD_NUMBER" ] && [ -n "$CI_PRIMARY_REPOSITORY_PATH" ]; then
    NEW_BUILD=$(( CI_BUILD_NUMBER + 1 ))
    PBXPROJ="${CI_PRIMARY_REPOSITORY_PATH}/Baby Light.xcodeproj/project.pbxproj"
    echo "🔢 Setting CURRENT_PROJECT_VERSION to ${NEW_BUILD} (CI run ${CI_BUILD_NUMBER} + 1)"
    /usr/bin/sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = ${NEW_BUILD};/g" "$PBXPROJ"
    echo "🔢 CURRENT_PROJECT_VERSION now set in $(grep -c "CURRENT_PROJECT_VERSION = ${NEW_BUILD};" "$PBXPROJ") configs"
fi

echo "✅ Pre-xcodebuild script completed"
