// Patches the Android and iOS folders that `flutter create` generates, so
// scheduled alerts, notification buttons, location and the optional adhan
// sound work. Safe to run more than once: it only adds what is missing.
//
// Run from the project folder:
//   dart run tool/setup_native.dart

import 'dart:io';

final List<String> done = [];
final List<String> warnings = [];

void main() {
  if (!File('pubspec.yaml').existsSync() || !Directory('lib').existsSync()) {
    stderr.writeln('Run this from the salah_companion folder (the one with pubspec.yaml).');
    exit(1);
  }
  final hasAndroid = Directory('android').existsSync();
  final hasIos = Directory('ios').existsSync();
  if (!hasAndroid && !hasIos) {
    stderr.writeln('There is no android or ios folder yet. Run this first:\n'
        '  flutter create --platforms=android,ios --project-name salah_companion .');
    exit(1);
  }
  if (hasAndroid) _android();
  if (hasIos) _ios();

  stdout.writeln('\nSetup finished.');
  for (final d in done) {
    stdout.writeln('  done: $d');
  }
  for (final w in warnings) {
    stdout.writeln('  CHECK: $w');
  }
  stdout.writeln('\nNext: flutter pub get, then flutter run (with your phone connected).');
}

String _read(String path) => File(path).readAsStringSync();
void _write(String path, String content) => File(path).writeAsStringSync(content);

// ------------------------------------------------------------------ Android

void _android() {
  _androidManifest();
  _androidGradle();
  _androidSettingsGradle();
  _androidWrapper();
  _androidResources();
}

void _androidManifest() {
  const path = 'android/app/src/main/AndroidManifest.xml';
  if (!File(path).existsSync()) {
    warnings.add('$path not found; add permissions and receivers by hand (see README).');
    return;
  }
  var xml = _read(path);
  final original = xml;

  const permissions = <String, String>{
    'android.permission.INTERNET': '<uses-permission android:name="android.permission.INTERNET"/>',
    'android.permission.POST_NOTIFICATIONS':
        '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>',
    'android.permission.VIBRATE': '<uses-permission android:name="android.permission.VIBRATE"/>',
    'android.permission.RECEIVE_BOOT_COMPLETED':
        '<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>',
    'android.permission.SCHEDULE_EXACT_ALARM':
        '<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" android:maxSdkVersion="32"/>',
    'android.permission.USE_EXACT_ALARM':
        '<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>',
    'android.permission.ACCESS_COARSE_LOCATION':
        '<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>',
    'android.permission.ACCESS_FINE_LOCATION':
        '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>',
  };
  final manifestTag = RegExp(r'<manifest[^>]*>').firstMatch(xml);
  if (manifestTag == null) {
    warnings.add('Could not find the <manifest> tag in $path.');
    return;
  }
  final toAdd = StringBuffer();
  permissions.forEach((name, line) {
    if (!xml.contains('"$name"')) toAdd.write('\n    $line');
  });
  if (toAdd.isNotEmpty) {
    xml = xml.replaceRange(manifestTag.end, manifestTag.end, toAdd.toString());
  }

  if (!xml.contains('ScheduledNotificationReceiver')) {
    const receivers = '''
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
''';
    final at = xml.lastIndexOf('</application>');
    if (at < 0) {
      warnings.add('Could not find </application> in $path.');
    } else {
      xml = xml.replaceRange(at, at, '$receivers    ');
    }
  }

  // Lets the app open quran.com in the browser.
  if (!xml.contains('android:scheme="https"')) {
    const intent = '''
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
''';
    if (xml.contains('<queries>')) {
      xml = xml.replaceFirst('<queries>', '<queries>\n$intent');
    } else {
      final end = xml.lastIndexOf('</manifest>');
      if (end >= 0) xml = xml.replaceRange(end, end, '    <queries>\n$intent    </queries>\n');
    }
  }

  xml = xml.replaceFirst('android:label="salah_companion"', 'android:label="Salah Companion"');

  if (xml != original) {
    _write(path, xml);
    done.add('AndroidManifest.xml: permissions, alert receivers, browser link support, app name');
  }
}

void _androidGradle() {
  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');
  final isKts = kts.existsSync();
  final file = isKts ? kts : groovy;
  if (!file.existsSync()) {
    warnings.add('android/app/build.gradle(.kts) not found; enable core library desugaring by hand (see README).');
    return;
  }
  var g = file.readAsStringSync();
  final original = g;

  // Java 17, as the notifications plugin requires.
  g = g
      .replaceAll('VERSION_1_8', 'VERSION_17')
      .replaceAll('VERSION_11', 'VERSION_17')
      .replaceAll('JvmTarget.JVM_11', 'JvmTarget.JVM_17')
      .replaceAll("jvmTarget = '1.8'", "jvmTarget = '17'");

  if (isKts) {
    if (!g.contains('isCoreLibraryDesugaringEnabled')) {
      g = g.replaceFirst('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true');
    }
    g = g.replaceAll('compileSdk = flutter.compileSdkVersion', 'compileSdk = maxOf(36, flutter.compileSdkVersion)');
    g = g.replaceAll('minSdk = flutter.minSdkVersion', 'minSdk = maxOf(24, flutter.minSdkVersion)');
    if (!g.contains('desugar_jdk_libs')) {
      g = '${g.trimRight()}\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n';
    }
  } else {
    if (!g.contains('coreLibraryDesugaringEnabled')) {
      g = g.replaceFirst('compileOptions {', 'compileOptions {\n        coreLibraryDesugaringEnabled true');
    }
    g = g
        .replaceAll(RegExp(r'compileSdk(Version)? flutter\.compileSdkVersion'),
            'compileSdk Math.max(36, flutter.compileSdkVersion)')
        .replaceAll(RegExp(r'minSdk(Version)? flutter\.minSdkVersion'),
            'minSdkVersion Math.max(24, flutter.minSdkVersion)');
    if (!g.contains('desugar_jdk_libs')) {
      g = "${g.trimRight()}\n\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n";
    }
  }
  if (!g.contains(isKts ? 'isCoreLibraryDesugaringEnabled' : 'coreLibraryDesugaringEnabled')) {
    warnings.add('Could not find compileOptions in ${file.path}; enable core library desugaring by hand.');
  }
  if (g != original) {
    file.writeAsStringSync(g);
    done.add('${file.path}: desugaring, Java 17, compileSdk 36+, minSdk 24+');
  }
}

int _compareVersions(String a, String b) {
  final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

/// The notifications plugin is built with Android Gradle Plugin 8.11.1.
void _androidSettingsGradle() {
  for (final path in ['android/settings.gradle.kts', 'android/settings.gradle']) {
    final f = File(path);
    if (!f.existsSync()) continue;
    var s = f.readAsStringSync();
    final re = RegExp(r'''(id\(?\s*["']com\.android\.application["']\s*\)?\s+version\s+["'])([\d.]+)(["'])''');
    final m = re.firstMatch(s);
    if (m == null) return;
    if (_compareVersions(m.group(2)!, '8.11.1') < 0) {
      s = s.replaceRange(m.start, m.end, '${m.group(1)}8.11.1${m.group(3)}');
      f.writeAsStringSync(s);
      done.add('$path: Android Gradle Plugin ${m.group(2)} -> 8.11.1');
    }
    return;
  }
}

/// AGP 8.11 needs Gradle 8.13 or newer.
void _androidWrapper() {
  const path = 'android/gradle/wrapper/gradle-wrapper.properties';
  final f = File(path);
  if (!f.existsSync()) return;
  var s = f.readAsStringSync();
  final m = RegExp(r'gradle-([\d.]+)-(all|bin)\.zip').firstMatch(s);
  if (m == null) return;
  if (_compareVersions(m.group(1)!, '8.13') < 0) {
    s = s.replaceRange(m.start, m.end, 'gradle-8.13-${m.group(2)}.zip');
    f.writeAsStringSync(s);
    done.add('$path: Gradle ${m.group(1)} -> 8.13');
  }
}

void _androidResources() {
  const rawDir = 'android/app/src/main/res/raw';
  Directory(rawDir).createSync(recursive: true);
  const keepPath = '$rawDir/keep.xml';
  if (!File(keepPath).existsSync()) {
    _write(keepPath, '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources xmlns:tools="http://schemas.android.com/tools"\n'
        '    tools:keep="@mipmap/ic_launcher,@raw/*" />\n');
    done.add('$keepPath: keeps the notification icon and sound in release builds');
  }
  final adhan = File('adhan/adhan.mp3');
  if (adhan.existsSync()) {
    adhan.copySync('$rawDir/adhan.mp3');
    done.add('Copied adhan/adhan.mp3 into the Android app');
  }
}

// ---------------------------------------------------------------------- iOS

void _ios() {
  const plistPath = 'ios/Runner/Info.plist';
  if (File(plistPath).existsSync()) {
    var p = _read(plistPath);
    if (!p.contains('NSLocationWhenInUseUsageDescription')) {
      final at = p.lastIndexOf('</dict>');
      if (at >= 0) {
        p = p.replaceRange(at, at,
            '\t<key>NSLocationWhenInUseUsageDescription</key>\n'
            '\t<string>Your location is used on this phone to calculate prayer times and the Qibla direction. It is not sent anywhere.</string>\n');
        _write(plistPath, p);
        done.add('Info.plist: location permission message');
      }
    }
  } else {
    warnings.add('$plistPath not found.');
  }

  const delegatePath = 'ios/Runner/AppDelegate.swift';
  if (!File(delegatePath).existsSync()) {
    warnings.add('$delegatePath not found; see README for the one line to add.');
    return;
  }
  var d = _read(delegatePath);
  if (d.contains('UNUserNotificationCenter.current().delegate')) return;
  const line =
      '    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate\n';
  final ret = d.indexOf('return super.application(');
  if (ret < 0) {
    warnings.add('Could not find didFinishLaunchingWithOptions in AppDelegate.swift. Add this line inside it:\n'
        '    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate');
    return;
  }
  final lineStart = d.lastIndexOf('\n', ret) + 1;
  d = d.replaceRange(lineStart, lineStart, line);
  if (!d.contains('import UserNotifications')) {
    d = d.replaceFirst('import Flutter', 'import Flutter\nimport UserNotifications');
  }
  _write(delegatePath, d);
  done.add('AppDelegate.swift: notifications show and respond while the app is open');
  if (File('adhan/adhan.caf').existsSync()) {
    warnings.add('Found adhan/adhan.caf. In Xcode, drag it into Runner (tick "Copy items if needed" and the Runner target).');
  }
}
