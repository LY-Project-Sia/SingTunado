@echo off
REM Run once from this folder on Windows. Needs Flutter installed.
call flutter create --platforms=android,windows --project-name singtunado --org com.singtunado .
powershell -NoProfile -Command "$f='android\app\src\main\AndroidManifest.xml'; $t=Get-Content $f -Raw; if($t -notmatch 'RECORD_AUDIO'){ $t=$t -replace '<application','<uses-permission android:name=\"android.permission.RECORD_AUDIO\"/>`n    <application' }; $t=$t -replace 'android:label=\"[^\"]*\"','android:label=\"SingTunado\"'; Set-Content $f $t"
call flutter pub get
call dart run flutter_launcher_icons
echo Done. Run:  flutter run -d windows   or   flutter run -d ^<android-device^>
