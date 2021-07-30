import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/settings.dart';
import '../providers.dart';

class SettingsPage extends HookConsumerWidget {
  SettingsPage({Key? key}) : super(key: key);

  static const ffmpegContainers = <DropdownMenuItem<String>>[
    DropdownMenuItem(value: '.mp4', child: Text('.mp4')),
    DropdownMenuItem(value: '.webm', child: Text('.webm')),
    DropdownMenuItem(value: '.mkv', child: Text('.mkv'))
  ];

  final locales = AppLocalizations.supportedLocales
      .map((e) => DropdownMenuItem(value: e, child: Text(e.languageCode)))
      .toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intl = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: const PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: SettingsAppBar()),
      body: ListView(
        padding: const EdgeInsets.only(top: 10),
        children: [
          ListTile(
            title: Text(intl.darkMode),
            leading: Icon(settings.state.theme == ThemeSetting.dark
                ? Icons.brightness_2
                : Icons.wb_sunny),
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
            title: Text(intl.downloadDir),
            subtitle: Text(settings.state.downloadPath),
            onTap: () async {
              final result = await getDirectoryPath();
              if (result?.isEmpty ?? true) {
                return;
              }
              settings.state = settings.state.copyWith(downloadPath: result);
            },
          ),
          const Divider(
            height: 0,
          ),
          ListTile(
            title: Text(intl.ffmpegContainer),
            subtitle: Text(intl.ffmpegDescription),
            trailing: DropdownButton(
              value: settings.state.ffmpegContainer,
              onChanged: (String? value) => settings.state =
                  settings.state.copyWith(ffmpegContainer: value),
              items: ffmpegContainers,
            ),
            onTap: () => themeOnChanged(
                settings, settings.state.theme != ThemeSetting.dark),
          ),
          const Divider(
            height: 0,
          ),
          ListTile(
            title: Text(intl.language),
            trailing: DropdownButton(
              value: settings.state.locale,
              onChanged: (Locale? value) =>
                  settings.state = settings.state.copyWith(locale: value),
              items: locales,
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
                AppLocalizations.of(context)!.settings,
                style: Theme.of(context).textTheme.headline5,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
