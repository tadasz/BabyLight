#!/bin/sh

# ci_post_xcodebuild.sh
# Runs after xcodebuild in Xcode Cloud
# Use this script for post-build actions like notifications or cleanup

set -e

echo "🎉 Post-xcodebuild script started"

# Report build status
if [ "$CI_XCODEBUILD_EXIT_CODE" = "0" ]; then
    echo "✅ Build succeeded!"
else
    echo "❌ Build failed with exit code: $CI_XCODEBUILD_EXIT_CODE"
fi

# Display test results summary if this was a test action
if [ "$CI_XCODEBUILD_ACTION" = "test" ]; then
    echo "🧪 Test action completed"
    
    # Check if test results exist
    if [ -d "$CI_RESULT_BUNDLE_PATH" ]; then
        echo "📊 Test results available at: $CI_RESULT_BUNDLE_PATH"
    fi
fi

echo "✅ Post-xcodebuild script completed"
