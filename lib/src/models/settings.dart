import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This is used before the Settings are loaded
class Settings {
  const Settings();

  SettingsImpl copyWith({String? downloadPath, ThemeSetting? theme}) =>
      throw UnimplementedError();

  String get downloadPath => throw UnimplementedError();

  ThemeSetting get theme => throw UnimplementedError();
}

class SettingsImpl implements Settings {
  final SharedPreferences _prefs;

  @override
  final String downloadPath;

  @override
  final ThemeSetting theme;

  SettingsImpl._(this._prefs, this.downloadPath, this.theme);

  @override
  SettingsImpl copyWith({String? downloadPath, ThemeSetting? theme}) {
    if (downloadPath != null) {
      _prefs.setString('download_path', downloadPath);
    }
    if (theme != null) {
      _prefs.setInt('theme_id', theme.id);
    }
    return SettingsImpl._(
        _prefs, downloadPath ?? this.downloadPath, theme ?? this.theme);
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
    return SettingsImpl._(prefs, path, ThemeSetting.fromId(themeId));
  }
}

class ThemeSetting {
  final int id;
  final ThemeData themeData;

  static final ThemeSetting light = ThemeSetting._(0, ThemeData.light().copyWith(scaffoldBackgroundColor: Colors.white));
  static final ThemeSetting dark = ThemeSetting._(1, ThemeData.dark());

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
