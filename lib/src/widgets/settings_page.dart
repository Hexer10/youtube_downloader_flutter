import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:youtube_downloader_flutter/src/models/settings.dart';
import 'package:youtube_downloader_flutter/src/providers.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends HookWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = useProvider(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: 'Section',
            tiles: [
              SettingsTile.switchTile(
                title: 'Dark Mode',
                leading: const Icon(CupertinoIcons.moon),
                switchValue: settings.state.theme == ThemeSetting.dark,
                onToggle: (bool value) {
                  if (value) {
                    settings.state =
                        settings.state.copyWith(theme: ThemeSetting.dark);
                    return;
                  }
                  settings.state =
                      settings.state.copyWith(theme: ThemeSetting.light);
                },
              ),
              SettingsTile(
                title: 'Download directory',
                subtitle: settings.state.downloadPath,
                onPressed: (context) async {
                  if (Platform.isWindows) {
                    final file = DirectoryPicker()
                      ..title = 'Select download directory';

                    final result = file.getDirectory();
                    if (result != null) {
                      print('Path: $result');
                    }
                  } else {
                    final result = await FilePicker.platform.getDirectoryPath();
                    print('Path: $result');
                  }
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}
