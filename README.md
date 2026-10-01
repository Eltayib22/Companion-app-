# Salah Companion

A native Android and iPhone app (built with Flutter) for:

- **Prayer times** calculated on the phone, with 11 calculation methods, Standard or Ḥanafī ʿAṣr, high-latitude rules, per-prayer minute adjustments, Hijri date and Qibla compass.
- **Alerts that keep going until you check the prayer off.** An alert fires at each prayer time with an "I've prayed" button. If you don't tap it, it repeats (every 10 minutes by default) until the time for that prayer ends, with a final warning before the end. Checking a prayer off, in the app or on the notification, stops its alerts.
- **A prayer tracker**: on time, late, missed or excused; streaks; a monthly calendar; and a make-up (qaḍāʾ) counter that fills automatically when a prayer's time ends unmarked.
- **Dhikr**: a tasbih counter with targets and vibration, and guided morning, evening and after-prayer adhkar with sources.
- **Tajweed**: 14 short lessons with quizzes, the alphabet with letter forms, articulation points, and a colour key.
- **Qurʾān**: Al-Fātiḥah and surahs 95–114 in Arabic, tajweed colour-coded transliteration (tap any colour to see its rule) and English meaning, with bookmarks, resume and a memorise mode.
- Excused mode (menstruation and postnatal bleeding), travel mode, Ramaḍān mode, dark mode, backup and restore.

Everything stays on the phone. There are no accounts, servers or ads.

---

## What you need

| | Android | iPhone |
|---|---|---|
| Computer | Windows, Mac or Linux | A Mac |
| Software | Flutter 3.38.1 or newer, Android Studio | Flutter 3.38.1 or newer, Xcode |
| Phone | Android 7 or newer, and a USB cable | iOS 13 or newer, and a cable |
| Account | None | A free Apple ID works, but the app expires after 7 days and must be re-installed. A paid Apple Developer account ($99 a year) lasts a year. |

Install Flutter by following https://docs.flutter.dev/get-started/install, then run `flutter doctor` in a terminal until the Android (or Xcode) line has a tick.

---

## Build it for Android

The first build takes a while because tools are downloaded. Later builds are quick.

1. **Unzip** this folder somewhere simple, for example `Documents/salah_companion`.
2. **Open a terminal in that folder** (in Windows Explorer, type `cmd` in the address bar and press Enter).
3. **Generate the Android and iOS project files:**
   ```
   flutter create --platforms=android,ios --project-name salah_companion --org com.yourname .
   ```
   Change `com.yourname` to anything unique, such as `com.aisha`. The full stop at the end matters. This does not overwrite the app's own files.
4. *(Optional)* **Add your own adhan sound**: put a short `adhan.mp3` in the `adhan` folder. See "Using your own adhan sound" below.
5. **Patch the native projects** for alerts, location and sound:
   ```
   dart run tool/setup_native.dart
   ```
   It lists what it changed. Lines marked CHECK need a look.
6. **Download the packages:**
   ```
   flutter pub get
   ```
7. *(Optional)* **Run the checks** for prayer-time maths and the Qurʾān data:
   ```
   flutter test
   ```
8. **Install on your phone.** On the phone, turn on Developer options (Settings > About phone > tap "Build number" seven times), then turn on USB debugging. Connect the cable and run:
   ```
   flutter run --release
   ```
   Or build an installable file to copy to the phone:
   ```
   flutter build apk --release
   ```
   The file is at `build/app/outputs/flutter-apk/app-release.apk`. Open it on the phone and allow installing from this source.
9. **In the app**, follow the three setup screens, and allow notifications. Then go to Settings > Alerts > **Send a test alert**.
10. **Stop Android from silencing the app.** Go to the phone's Settings > Apps > Salah Companion > Battery and choose **Unrestricted** (or turn off battery optimisation). Samsung, Xiaomi, Huawei, OnePlus and Oppo phones have extra settings that stop background alarms; https://dontkillmyapp.com has steps for each brand.

## Build it for iPhone

1. Follow steps 1 to 7 above on a Mac.
2. Open `ios/Runner.xcworkspace` in Xcode.
3. Select **Runner** > **Signing & Capabilities**. Choose your Team (your Apple ID) and make the Bundle Identifier unique, such as `com.aisha.salahcompanion`.
4. On the iPhone, turn on Settings > Privacy & Security > **Developer Mode**, and connect it to the Mac.
5. Run `flutter run --release` in the terminal, or press Run in Xcode.
6. The first time, the iPhone may ask you to trust the developer: Settings > General > VPN & Device Management.
7. If you use a Focus or Sleep mode around Fajr, add Salah Companion to its allowed apps.

---

## How the alerts work, and their limits

- **At prayer time:** "It's time for Asr", with an **I've prayed** button.
- **Then every 10 minutes** (you can choose 5 to 30): "Asr isn't checked off yet. Reminder 3. The time for Asr ends at 6:41 pm."
- **20 minutes before the time ends** (adjustable or off): a final warning.
- **When the time ends** without a check-off, alerts stop and the prayer is recorded as missed and added to your make-up count. You can change any day's record in History.
- ʿIshāʾ reminders stop at Islamic midnight by default, so they don't run all night. You can change this to Fajr.
- **Excused mode** pauses all prayer alerts and records prayers as excused instead of missed.

Phones only run an app's code when it is open, so alerts are **planned in advance** and re-planned every time you open the app:

- **Android** plans a few days ahead, and keeps alerts after a restart.
- **iPhone** allows only 64 waiting notifications per app. The app always keeps the start-of-prayer alerts and final warnings for the next two days, and fills the rest with the soonest repeats (several hours' worth). Tapping "I've prayed" opens the app for a moment, which tops the plan up again. If you go a long time without opening it, a notification asks you to open the app so repeats continue.

Alerts follow the phone's sound settings. In silent mode they vibrate or show silently.

## Using your own adhan sound

**Android:** before step 5, put `adhan.mp3` in the `adhan` folder (or later, copy it to `android/app/src/main/res/raw/adhan.mp3`), then build and install again. In the app, turn on Settings > Alerts > **Use my adhan recording**. Keep it short; the opening takbīr works well. If the setting is on but the file isn't in the build, the normal sound is used and Settings says so.

**iPhone:** iOS plays at most 30 seconds. Convert the file on the Mac:
```
afconvert adhan.mp3 adhan.caf -d ima4 -f caff -v
```
Drag `adhan.caf` into the **Runner** folder in Xcode (tick "Copy items if needed" and the Runner target), rebuild, then turn the setting on.

Only use recordings you have permission to use.

## Matching your mosque's timetable

1. Settings > Prayer times > **Calculation method**. The app suggests the one most used in your region; many UK mosques use the Moonsighting Committee or their own timetable.
2. Choose Standard or Ḥanafī **ʿAṣr**.
3. Use **Adjust by minutes** to nudge any prayer so it matches your mosque exactly.

## About the Qurʾān and tajweed content

The Qurʾān section covers Al-Fātiḥah and surahs 95 to 114. The transliteration follows the reading of Ḥafṣ ʿan ʿĀṣim and is written as you would read when stopping at the end of each ayah. Every tajweed colour was placed by hand. Please check it against a printed muṣḥaf and, ideally, a qualified teacher; if you find anything wrong, it is a one-line fix in `lib/data/quran.dart`.

To add another surah, add a `Surah(...)` entry to `lib/data/quran.dart`. In the transliteration, wrap the letters a rule applies to in braces with the rule code, for example `aḥa{Q:d}` for qalqalah. The codes are listed in `lib/ui/tajweed.dart`. `flutter test` checks that every code is valid.

The English lines are plain renderings of the meaning, not a translation to rely on for rulings.

---

## Project layout

```
lib/
  main.dart                 Starts the app; refreshes records and alerts whenever it opens
  core/
    prayer_calc.dart        Prayer-time astronomy, Hijri date, Qibla bearing
    app_state.dart          Settings, prayer log, make-up counts, progress; saved on the phone
    notifications.dart      Plans and schedules the repeating alerts
    format.dart             Date and time formatting
  data/
    quran.dart              Surahs with Arabic, tajweed transliteration and meaning
    adhkar.dart             Morning, evening and after-prayer adhkar with sources
    lessons.dart            Tajweed lessons, quizzes, alphabet, articulation points
    cities.dart             Cities for choosing a location without GPS
  ui/                       Screens (Today, History, Qibla, Dhikr, Learn, Qurʾān, Settings)
test/                       Checks for prayer times, Hijri dates, Qibla and the Qurʾān data
tool/setup_native.dart      Patches the generated Android and iOS projects
adhan/                      Put your optional adhan recording here
```

## Troubleshooting

- **The build complains about "desugaring" or Java versions.** Run `dart run tool/setup_native.dart` again and read any CHECK lines. In `android/app/build.gradle.kts`, `compileOptions` should contain `isCoreLibraryDesugaringEnabled = true`, and there should be a `dependencies` block with `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`.
- **A package version error during `flutter pub get`.** Run `flutter upgrade`, then try again. The notifications package needs Flutter 3.38.1 or newer.
- **No alerts arrive.** Send a test alert from Settings. If that fails, allow notifications for the app in the phone's settings. On Android, check the "Allow exact alarms" line in Settings and the battery settings in step 10.
- **Arabic looks plain the first time.** The Amiri and Figtree fonts download the first time the app opens with internet, and are then kept on the phone.
- **Publishing to the Play Store.** The app uses Android's `USE_EXACT_ALARM` permission so alerts arrive on time. Google only allows that for alarm and calendar apps; for a Play Store release you may need to switch to `SCHEDULE_EXACT_ALARM` (users grant it in Settings, and the app already shows a prompt for it).
