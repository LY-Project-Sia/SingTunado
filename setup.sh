#!/usr/bin/env bash
# Run once from this folder (macOS/Linux/Git Bash). Needs Flutter installed.
set -e
flutter create --platforms=android,windows --project-name singtunado --org com.singtunado .
MANIFEST=android/app/src/main/AndroidManifest.xml
if ! grep -q RECORD_AUDIO "$MANIFEST"; then
  sed -i.bak 's#<application#<uses-permission android:name="android.permission.RECORD_AUDIO"/>\n    <application#' "$MANIFEST"
  rm -f "$MANIFEST.bak"
fi
sed -i.bak 's#android:label="[^"]*"#android:label="SingTunado"#' "$MANIFEST" && rm -f "$MANIFEST.bak"
flutter pub get
dart run flutter_launcher_icons
echo "Done. Run:  flutter run -d windows   or   flutter run -d <android-device>"
