#!/bin/bash

# Install Flutter on Netlify
echo "Installing Flutter SDK..."

# Download Flutter SDK
cd /opt/buildhome
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# Add Flutter to PATH
export PATH="$PATH:/opt/buildhome/flutter/bin"

# Pre-download dependencies
flutter doctor
flutter precache --web

# Navigate back to build directory
cd $NETLIFY_BUILD_BASE

echo "Flutter installation complete!"
