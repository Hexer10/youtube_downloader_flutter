import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'settings_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final intl = AppLocalizations.of(context)!;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(child: Text(intl.title)),
          ListTile(
            title: Text(intl.settings),
            leading: const Icon(Icons.settings),
            onTap: () {
              //Todo: Replace Route with named route or Navigator2
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SettingsPage()));
            },
          )
        ],
      ),
    );
  }
}
