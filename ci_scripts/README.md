# Xcode Cloud CI/CD Setup

This folder contains custom scripts for Xcode Cloud CI/CD integration.

## Setup Instructions

### 1. Enable Xcode Cloud in Xcode

1. Open the project in Xcode
2. Go to **Product → Xcode Cloud → Create Workflow...**
3. Sign in with your Apple ID if prompted
4. Connect your Git repository (GitHub, GitLab, Bitbucket, or Git server)

### 2. Create Workflows

#### Unit Tests Workflow
1. Click **+** to create a new workflow
2. Name: `Unit Tests`
3. **Start Conditions**: 
   - Branch changes: `main`, `develop`
   - Pull request: Open or update
4. **Environment**: 
   - Xcode: Latest Release
   - macOS: Latest Release
5. **Actions**: 
   - Add **Test** action
   - Scheme: `Baby Light`
   - Destination: `Any iOS Simulator`

#### UI Tests Workflow
1. Create another workflow
2. Name: `UI Tests`
3. **Start Conditions**: Same as Unit Tests
4. **Actions**:
   - Add **Test** action
   - Scheme: `Baby Light`
   - Destination: `iPhone 15 Pro Simulator` (or preferred device)

#### Release Build Workflow
1. Create another workflow
2. Name: `Release Build`
3. **Start Conditions**:
   - Tag: `v*` (triggers on version tags)
4. **Actions**:
   - Add **Build** action
   - Add **Archive** action (for App Store distribution)

### 3. Custom Scripts

The following scripts are executed automatically by Xcode Cloud:

| Script | Timing | Purpose |
|--------|--------|---------|
| `ci_post_clone.sh` | After clone | Install dependencies, environment setup |
| `ci_pre_xcodebuild.sh` | Before build | Pre-build configuration |
| `ci_post_xcodebuild.sh` | After build | Post-build actions, notifications |

### 4. Environment Variables

Xcode Cloud provides these built-in environment variables:

- `CI_WORKFLOW` - Name of the current workflow
- `CI_XCODEBUILD_ACTION` - Current action (build, test, archive)
- `CI_PRODUCT_PLATFORM` - Target platform
- `CI_BRANCH` - Current branch name
- `CI_TAG` - Git tag (if triggered by tag)
- `CI_COMMIT` - Git commit SHA
- `CI_XCODEBUILD_EXIT_CODE` - Build exit code (in post scripts)
- `CI_RESULT_BUNDLE_PATH` - Path to test results

### 5. Test Targets

The project includes:

- **Baby LightTests** - Unit tests using Swift Testing framework
- **Baby LightUITests** - UI tests using XCTest

### 6. Troubleshooting

- Ensure all scripts have execute permissions (`chmod +x *.sh`)
- Check Xcode Cloud logs in App Store Connect
- Verify scheme is shared and includes test targets
