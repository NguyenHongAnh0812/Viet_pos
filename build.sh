#!/bin/bash

# Build script for Vercel deployment
echo "Starting Flutter build for Vercel..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for web with all assets
flutter build web --release

# Verify assets are included
echo "Checking if assets are included in build..."
if [ -d "build/web/assets" ]; then
    echo "✅ Assets directory found in build/web/"
    ls -la build/web/assets/
else
    echo "❌ Assets directory not found in build/web/"
    exit 1
fi

# Check for specific asset files
if [ -f "build/web/assets/assets/icons/add.svg" ]; then
    echo "✅ SVG icons found"
else
    echo "❌ SVG icons not found"
fi

if [ -f "build/web/assets/assets/images/logo.png" ]; then
    echo "✅ Logo image found"
else
    echo "❌ Logo image not found"
fi

echo "Build completed successfully!" 