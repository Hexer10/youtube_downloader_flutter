import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/settings.dart';
import '../providers.dart';

class SettingsPage extends HookWidget {
  const SettingsPage({Key? key}) : super(key: key);

  static const ffmpegContainers = <DropdownMenuItem<String>>[
    DropdownMenuItem(value: '.mp4', child: Text('.mp4')),
    DropdownMenuItem(value: '.webm', child: Text('.webm')),
    DropdownMenuItem(value: '.mkv', child: Text('.mkv'))
  ];

  @override
  Widget build(BuildContext context) {
    final settings = useProvider(settingsProvider);

    return Scaffold(
      appBar: const PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: SettingsAppBar()),
      body: ListView(
        padding: const EdgeInsets.only(top: 10),
        children: [
          ListTile(
            title: const Text('Dark Mode'),
            leading: const Icon(CupertinoIcons.moon),
            trailing: Switch(
              value: settings.state.theme == ThemeSetting.dark,
              onChanged: (bool value) => themeOnChanged(settings, value),
            ),
            onTap: () => themeOnChanged(
                settings, settings.state.theme != ThemeSetting.dark),
          ),
          const Divider(
            height: 0,
          ),
          ListTile(
            title: const Text('Download directory'),
            subtitle: Text(settings.state.downloadPath),
            onTap: () async {
              if (Platform.isWindows) {
                final file = DirectoryPicker()
                  ..title = 'Select download directory';

                final result = file.getDirectory();
                if (result == null) {
                  return;
                }
                settings.state =
                    settings.state.copyWith(downloadPath: result.path);
                return;
              } else {
                final result = await FilePicker.platform.getDirectoryPath();
                if (result == null) {
                  return;
                }
                if (result == '/') {
                  print('Invalid path!');
                  return;
                }
                settings.state = settings.state.copyWith(downloadPath: result);
              }
            },
          ),
          const Divider(
            height: 0,
          ),
          ListTile(
            title: const Text('ffmpeg container'),
            subtitle: const Text(
                'This is the output format when two tracks (audio + video) are merged.'),
            leading: const Icon(CupertinoIcons.moon),
            trailing: DropdownButton(
              value: settings.state.ffmpegContainer,
              onChanged: (String? value) => settings.state = settings.state.copyWith(ffmpegContainer: value),
              items: ffmpegContainers,
            ),
            onTap: () => themeOnChanged(
                settings, settings.state.theme != ThemeSetting.dark),
          ),
        ],
      ),
    );
  }

  // ignore: avoid_positional_boolean_parameters
  void themeOnChanged(StateController<Settings> settings, bool value) {
    if (value) {
      settings.state = settings.state.copyWith(theme: ThemeSetting.dark);
      return;
    }
    settings.state = settings.state.copyWith(theme: ThemeSetting.light);
  }
}

class SettingsAppBar extends HookWidget {
  const SettingsAppBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        elevation: 5,
        child: Container(
          padding: const EdgeInsets.only(left: 10),
          height: kToolbarHeight,
          child: Row(children: [
            IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop()),
            Center(
              child: Text(
                'Settings',
                style: Theme.of(context).textTheme.headline5,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
