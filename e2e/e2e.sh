#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAESTRO_DIR="$SCRIPT_DIR/maestro"

APP_NAME="expophotose2e"
DEVICE_NAME="iPhone 17"
BUNDLE_IDENTIFIER="com.hortemo.expoPhotosE2E"
DERIVED_DATA_DIR="$SCRIPT_DIR/build/ios"
XCODEBUILD_LOG="$SCRIPT_DIR/build/xcodebuild.log"
APP_PATH="$DERIVED_DATA_DIR/Build/Products/Release-iphonesimulator/${APP_NAME}.app"
VIDEO_PID=""

export EXPO_NO_TELEMETRY="${EXPO_NO_TELEMETRY:-1}"
export PATH="$HOME/.maestro/bin:$PATH"

# End video recording on exit
cleanup() {
  if [ -n "$VIDEO_PID" ] && kill -0 "$VIDEO_PID" 2>/dev/null; then
    kill -INT "$VIDEO_PID" 2>/dev/null || true
    wait "$VIDEO_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

pushd "$SCRIPT_DIR" >/dev/null

mkdir -p "$DERIVED_DATA_DIR" "$(dirname "$XCODEBUILD_LOG")"
: >"$XCODEBUILD_LOG"

echo "Booting simulator $DEVICE_NAME"
xcrun simctl boot "$DEVICE_NAME" >/dev/null 2>&1 || true

echo "Installing npm dependencies"
(cd "$SCRIPT_DIR/.." && npm ci)
(cd "$SCRIPT_DIR" && npm ci)

echo "Creating ios folder"
npx expo prebuild --platform ios --no-install

echo "Installing pods"
npx pod-install ios

echo "Building app (logging to $XCODEBUILD_LOG)"
xcodebuild \
  -workspace "ios/${APP_NAME}.xcworkspace" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=${DEVICE_NAME}" \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  >"$XCODEBUILD_LOG" 2>&1

echo "Waiting for simulator to finish booting"
xcrun simctl bootstatus "$DEVICE_NAME" -b

echo "Starting simulator video recording"
xcrun simctl io "$DEVICE_NAME" recordVideo --codec=h264 "$MAESTRO_DIR/e2e-recording.mp4" >/dev/null 2>&1 &
VIDEO_PID=$!

echo "Seeding Photos library with fixture media"
xcrun simctl addmedia "$DEVICE_NAME" "$MAESTRO_DIR/4k60.mov"
xcrun simctl launch "$DEVICE_NAME" com.apple.mobileslideshow

echo "Installing app"
xcrun simctl install "$DEVICE_NAME" "$APP_PATH"

echo "Granting photo permissions"
xcrun simctl privacy "$DEVICE_NAME" grant photos "$BUNDLE_IDENTIFIER"
xcrun simctl privacy "$DEVICE_NAME" grant photos-add "$BUNDLE_IDENTIFIER"

echo "Running Maestro tests"
maestro test --env "APP_PATH=$APP_PATH" "$MAESTRO_DIR/e2e.yaml"

popd >/dev/null
