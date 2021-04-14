import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This is used before the Settings are loaded
@immutable
class Settings {
  const Settings();

  SettingsImpl copyWith(
          {String? downloadPath,
          ThemeSetting? theme,
          String? ffmpegContainer,
          Locale? locale}) =>
      throw UnimplementedError();

  String get ffmpegContainer => throw UnimplementedError();

  String get downloadPath => throw UnimplementedError();

  ThemeSetting get theme => throw UnimplementedError();

  Locale get locale => throw UnimplementedError();
}

@immutable
class SettingsImpl implements Settings {
  final SharedPreferences _prefs;

  @override
  final String downloadPath;

  @override
  final ThemeSetting theme;

  @override
  final String ffmpegContainer;

  @override
  final Locale locale;

  const SettingsImpl._(this._prefs, this.downloadPath, this.theme,
      this.ffmpegContainer, this.locale);

  @override
  SettingsImpl copyWith(
      {String? downloadPath,
      ThemeSetting? theme,
      String? ffmpegContainer,
      Locale? locale}) {
    if (downloadPath != null) {
      _prefs.setString('download_path', downloadPath);
    }
    if (theme != null) {
      _prefs.setInt('theme_id', theme.id);
    }
    if (ffmpegContainer != null) {
      _prefs.setString('ffmpeg_container', ffmpegContainer);
    }
    if (locale != null) {
      _prefs.setString('locale', locale.languageCode);
    }

    return SettingsImpl._(
        _prefs,
        downloadPath ?? this.downloadPath,
        theme ?? this.theme,
        ffmpegContainer ?? this.ffmpegContainer,
        locale ?? this.locale);
  }

  static Future<SettingsImpl> init(SharedPreferences prefs) async {
    var path = prefs.getString('download_path');
    if (path == null) {
      path = (await getDefaultDownloadDir()).path;
      prefs.setString('download_path', path);
    }
    var themeId = prefs.getInt('theme_id');
    if (themeId == null) {
      themeId = 0;
      prefs.setInt('theme_id', 0);
    }
    var ffmpegContainer = prefs.getString('ffmpeg_container');
    if (ffmpegContainer == null) {
      ffmpegContainer = '.mp4';
      prefs.setString('ffmpeg_container', '.mp4');
    }

    var langCode = prefs.getString('locale');
    if (langCode == null) {
      final defaultLang = WidgetsBinding.instance!.window.locales.first;
      langCode = defaultLang.languageCode;
      prefs.setString('locale', defaultLang.languageCode);
    }
    return SettingsImpl._(prefs, path, ThemeSetting.fromId(themeId),
        ffmpegContainer, Locale(langCode));
  }
}

class ThemeSetting {
  final int id;
  final ThemeData themeData;

  static final ThemeSetting light = ThemeSetting._(
      0,
      ThemeData.light().copyWith(
          scaffoldBackgroundColor: Colors.white,
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: Colors.white70,
            contentTextStyle: TextStyle(color: Colors.black),
          )));

  static final ThemeSetting dark = ThemeSetting._(
      1,
      ThemeData.dark().copyWith(
          snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey[700],
        contentTextStyle: const TextStyle(color: Colors.white70),
      )));

  const ThemeSetting._(this.id, this.themeData);

  factory ThemeSetting.fromId(int id) {
    if (id == 0) {
      return light;
    }
    if (id == 1) {
      return dark;
    }
    throw UnsupportedError('Unsupported theme: $id');
  }

  @override
  bool operator ==(Object other) {
    if (other is ThemeSetting) {
      return other.id == id;
    }
    if (other is int) {
      return other == id;
    }
    return false;
  }

  @override
  int get hashCode => id.hashCode;
}

Future<Directory> getDefaultDownloadDir() async {
  if (Platform.isAndroid) {
    final paths =
        await getExternalStorageDirectories(type: StorageDirectory.music);
    return paths!.first;
  }
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    final path = await getDownloadsDirectory();
    return path!;
  }
  throw UnsupportedError(
      'Platform: ${Platform.operatingSystem} is not supported!');
}
