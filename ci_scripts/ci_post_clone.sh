#!/bin/sh

# ci_post_clone.sh
# Runs after the repository is cloned in Xcode Cloud
# Use this script to install dependencies or set up the environment

set -e

echo "📦 Post-clone script started"

# Print environment info
echo "🔧 Xcode version:"
xcodebuild -version

echo "📱 Available simulators:"
xcrun simctl list devices available | head -20

echo "✅ Post-clone script completed"
