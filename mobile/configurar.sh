#!/usr/bin/env bash
# MoveTech Mobile - configuracao inicial (Linux / macOS / GitHub Actions)
# Equivalente ao configurar.ps1.
set -euo pipefail
cd "$(dirname "$0")"

MANIFESTO="android/app/src/main/AndroidManifest.xml"

if [ ! -f "$MANIFESTO" ]; then
  echo "1/3 - Gerando pastas nativas..."
  flutter create --org br.com.movetech --project-name movetech_mobile --platforms android,ios .
else
  echo "1/3 - Pastas nativas ja existem."
fi

echo "2/3 - Ajustando AndroidManifest.xml..."
if ! grep -q "android.permission.INTERNET" "$MANIFESTO"; then
  sed -i.bak 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\
    <application#' "$MANIFESTO"
fi
if ! grep -q "usesCleartextTraffic" "$MANIFESTO"; then
  sed -i.bak 's#<application#<application android:usesCleartextTraffic="true"#' "$MANIFESTO"
fi
sed -i.bak 's#android:label="movetech_mobile"#android:label="MoveTech"#' "$MANIFESTO"
rm -f "$MANIFESTO.bak"

echo "3/3 - Baixando dependencias..."
flutter pub get
echo "Pronto."
