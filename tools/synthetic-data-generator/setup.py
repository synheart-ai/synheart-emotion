"""Setup for synthetic biosignal data generator."""
from setuptools import setup, find_packages

setup(
    name="syndata",
    version="0.1.0",
    description="Synthetic biosignal data generator for testing Emotion SDKs",
    author="Synheart",
    packages=find_packages(),
    python_requires=">=3.8",
    install_requires=[],  # No required dependencies
    extras_require={
        "numpy": ["numpy>=1.21.0"],  # Optional for advanced features
    },
    entry_points={
        "console_scripts": [
            "syndata=cli:main",
        ],
    },
)
