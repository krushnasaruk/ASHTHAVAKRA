#!/usr/bin/env bash
set -e

echo "=== Ashtavakra Admin Web Build ==="

# Check if Flutter is present in environment, if not clone stable
if ! command -v flutter &> /dev/null; then
  echo "Flutter not detected. Cloning Flutter stable into cache..."
  if [ ! -d "$HOME/flutter" ]; then
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
  fi
  export PATH="$PATH:$HOME/flutter/bin"
fi

echo "Using Flutter:"
flutter --version

# Navigate to admin directory if at root
if [ -d "admin" ]; then
  cd admin
fi

echo "Running flutter pub get..."
flutter pub get

echo "Building Flutter Web release..."
flutter build web --release --no-tree-shake-icons

# Ensure SPA redirects exist in build output
echo "/*    /index.html   200" > build/web/_redirects

echo "=== Build finished successfully! Output at build/web ==="
