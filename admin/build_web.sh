#!/usr/bin/env bash
set -e

echo "=== Ashtavakra Admin Web Build (admin/ scope) ==="

if ! command -v flutter &> /dev/null; then
  echo "Flutter not detected. Cloning Flutter stable into cache..."
  if [ ! -d "$HOME/flutter" ]; then
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
  fi
  export PATH="$PATH:$HOME/flutter/bin"
fi

flutter --version

flutter pub get
flutter build web --release --no-tree-shake-icons

echo "/*    /index.html   200" > build/web/_redirects

echo "=== Build finished successfully! Output at build/web ==="
