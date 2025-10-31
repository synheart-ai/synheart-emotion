#!/bin/bash
# Copy models from root/models to SDK-specific locations
# This script ensures all SDKs have access to the latest model files

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODELS_DIR="${ROOT_DIR}/models"

echo "📦 Copying models to SDK locations..."

# Flutter SDK - copy to assets
FLUTTER_ASSETS_DIR="${ROOT_DIR}/sdks/flutter/assets/ml"
if [ -d "${FLUTTER_ASSETS_DIR}" ]; then
    echo "  → Flutter: copying to assets/ml/"
    mkdir -p "${FLUTTER_ASSETS_DIR}"
    cp "${MODELS_DIR}"/*.json "${FLUTTER_ASSETS_DIR}/" 2>/dev/null || true
fi

# Python SDK - copy to data directory
PYTHON_DATA_DIR="${ROOT_DIR}/sdks/python/src/synheart_emotion/data"
if [ -d "${ROOT_DIR}/sdks/python/src/synheart_emotion" ]; then
    echo "  → Python: copying to src/synheart_emotion/data/"
    mkdir -p "${PYTHON_DATA_DIR}"
    cp "${MODELS_DIR}"/*.json "${PYTHON_DATA_DIR}/" 2>/dev/null || true
fi

# Android SDK - copy to assets/res/raw (if needed)
ANDROID_ASSETS_DIR="${ROOT_DIR}/sdks/android/src/main/res/raw"
if [ -d "${ROOT_DIR}/sdks/android" ]; then
    echo "  → Android: models embedded in code (or copy to res/raw/ if using JSON loading)"
    # Note: Android currently uses embedded models, but we can copy here if needed
    # mkdir -p "${ANDROID_ASSETS_DIR}"
    # cp "${MODELS_DIR}"/*.json "${ANDROID_ASSETS_DIR}/" 2>/dev/null || true
fi

# iOS SDK - copy to Resources (if needed)
IOS_RESOURCES_DIR="${ROOT_DIR}/sdks/ios/Sources/SynheartEmotion/Resources"
if [ -d "${ROOT_DIR}/sdks/ios/Sources/SynheartEmotion" ]; then
    echo "  → iOS: models embedded in code (or copy to Resources/ if using JSON loading)"
    # Note: iOS currently uses embedded models, but we can copy here if needed
    # mkdir -p "${IOS_RESOURCES_DIR}"
    # cp "${MODELS_DIR}"/*.json "${IOS_RESOURCES_DIR}/" 2>/dev/null || true
fi

echo "✅ Model copying complete!"

