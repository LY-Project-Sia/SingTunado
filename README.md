# SingTunado

Karaoke app for Android and Windows PC, built with Flutter (one codebase).

## What it does
- Song library from audio files you add (mp3, m4a, wav, flac, ogg, aac)
- Synced lyrics from standard `.lrc` files (see `sample.lrc`)
- Sing along with the mic, record your voice, and see a live level meter
- "Voice activity score" after each take (measures singing during lyric lines, not pitch)
- Branded with your logo: `assets/icon.png`, gradient theme in `lib/theme.dart`

## Setup (one time)
1. Install Flutter: https://docs.flutter.dev/get-started/install
   - For Windows builds also install Visual Studio with "Desktop development with C++"
   - For Android builds also install Android Studio (SDK)
2. In this folder run `setup.bat` (Windows) or `./setup.sh` (macOS/Linux).
   It generates the android/ and windows/ folders, adds the microphone permission,
   and creates the app icons from your logo.

## Run
    flutter run -d windows
    flutter run -d <your-android-device>

## Build to install
    flutter build apk --release          # build/app/outputs/flutter-apk/app-release.apk
    flutter build windows --release      # build/windows/x64/runner/Release/ (run on a Windows PC)

## Project layout
    lib/main.dart                     app entry
    lib/theme.dart                    brand colors + gradient text
    lib/models/lrc.dart               .lrc parser and current-line lookup
    lib/models/song.dart              song model
    lib/services/library_store.dart   add/rename/remove songs, attach lyrics
    lib/screens/library_screen.dart   song list + search
    lib/screens/player_screen.dart    playback, synced lyrics, recording, score

Recordings are saved in the app's documents folder under `SingTunado/recordings`
(.m4a on Android, .wav on Windows).

## Content note
Add only music you own or have a license to use (your own backing tracks,
royalty-free, or Creative Commons). The app ships with no songs.

## Ideas for next steps
Real pitch scoring (FFT/autocorrelation on mic input), echo/reverb effects,
mixing your vocal with the backing track, playlists, queue, online catalog via a
licensed music API.

## Get installable files without installing Flutter (GitHub Actions)
1. Create a free GitHub repository and upload this whole folder (branch `main`).
2. Open the repo's **Actions** tab, choose **Build SingTunado**, click **Run workflow**.
3. After a few minutes download the artifacts:
   - `SingTunado-android-apk` -> `app-release.apk`: copy to your phone, open it, allow "install unknown apps" when asked.
   - `SingTunado-windows` -> unzip and run `singtunado.exe` (keep all files in that folder together).
