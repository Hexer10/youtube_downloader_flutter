import 'dart:io';

import 'package:android_path_provider/android_path_provider.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:youtube_downloader/src/blocs/settings_bloc.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    checkSavePath();
    super.initState();
  }

  Future<void> checkSavePath() async {
    // ignore: close_sinks
    var bloc = BlocProvider.of<SettingsBloc>(context);
    if (bloc.state.savePath == null) {
      var dir = await AndroidPathProvider.downloadsPath;
      bloc.add(SetSavePath(dir));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: BlocBuilder<SettingsBloc, SettingsModel>(
        builder: (context, state) {
          return SettingsList(
            sections: [
              SettingsSection(
                title: 'Application',
                tiles: [
                  SettingsTile.switchTile(
                    title: 'Dark mode',
                    leading: Icon(Icons.edit_attributes),
                    switchValue: state.darkMode,
                    onToggle: (bool value) {
                      BlocProvider.of<SettingsBloc>(context)
                          .add(ToggleDarkMode(value));
                    },
                  ),
                  SettingsTile(
                      subtitle: state.savePath ?? 'Loading...',
                      title: 'Save path',
                      leading: Icon(Icons.save_alt),
                      onTap: () async {
                        final status = await Permission.storage.request();
                        if (status.isDenied ||
                            status.isRestricted ||
                            status.isPermanentlyDenied ||
                            status.isUndetermined) {
                          print('Permission not granted: $status');
                          return;
                        }

                        var directory = state.savePath;
                        if (directory == null) {
                          return;
                        }

                        String path = await FilesystemPicker.open(
                            rootName: directory,
                            title: 'Choose a directory',
                            context: context,
                            rootDirectory: Directory(directory),
                            fsType: FilesystemType.folder,
                            pickText: 'Select this directory');
                        BlocProvider.of<SettingsBloc>(context)
                            .add(SetSavePath(path));
                      }),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
