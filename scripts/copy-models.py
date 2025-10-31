#!/usr/bin/env python3
"""Copy models from root/models to SDK-specific locations.

This script ensures all SDKs have access to the latest model files
from the centralized models directory.
"""
import shutil
from pathlib import Path

def copy_models():
    """Copy model files from root/models to SDK locations."""
    root_dir = Path(__file__).parent.parent
    models_dir = root_dir / "models"
    
    if not models_dir.exists():
        print(f"❌ Error: Models directory not found at {models_dir}")
        return False
    
    model_files = list(models_dir.glob("*.json"))
    if not model_files:
        print(f"⚠️  Warning: No JSON model files found in {models_dir}")
        return False
    
    print(f"📦 Copying {len(model_files)} model file(s) to SDK locations...")
    
    # Flutter SDK - copy to assets
    flutter_assets = root_dir / "sdks" / "flutter" / "assets" / "ml"
    if flutter_assets.parent.exists():
        flutter_assets.mkdir(parents=True, exist_ok=True)
        for model_file in model_files:
            shutil.copy2(model_file, flutter_assets / model_file.name)
        print(f"  ✅ Flutter: copied to assets/ml/")
    
    # Python SDK - copy to data directory
    python_data = root_dir / "sdks" / "python" / "src" / "synheart_emotion" / "data"
    if python_data.parent.parent.exists():
        python_data.mkdir(parents=True, exist_ok=True)
        for model_file in model_files:
            shutil.copy2(model_file, python_data / model_file.name)
        print(f"  ✅ Python: copied to src/synheart_emotion/data/")
    
    # Android SDK - currently uses embedded models, but we can copy if needed
    # android_assets = root_dir / "sdks" / "android" / "src" / "main" / "res" / "raw"
    # if android_assets.parent.parent.exists():
    #     android_assets.mkdir(parents=True, exist_ok=True)
    #     for model_file in model_files:
    #         shutil.copy2(model_file, android_assets / model_file.name)
    #     print(f"  ✅ Android: copied to res/raw/")
    
    # iOS SDK - currently uses embedded models, but we can copy if needed
    # ios_resources = root_dir / "sdks" / "ios" / "Sources" / "SynheartEmotion" / "Resources"
    # if ios_resources.parent.exists():
    #     ios_resources.mkdir(parents=True, exist_ok=True)
    #     for model_file in model_files:
    #         shutil.copy2(model_file, ios_resources / model_file.name)
    #     print(f"  ✅ iOS: copied to Resources/")
    
    print(f"✅ Successfully copied {len(model_files)} model file(s)!")
    return True

if __name__ == "__main__":
    import sys
    success = copy_models()
    sys.exit(0 if success else 1)

