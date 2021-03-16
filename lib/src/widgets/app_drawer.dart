import 'package:flutter/material.dart';

import 'settings_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(child: Text('Youtube Downloader')),
          ListTile(
            title: const Text('Settings'),
            leading: const Icon(Icons.settings),
            onTap: () {
              //Todo: Replace Route with named route or Navigator2
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
          )
        ],
      ),
    );
  }
}
