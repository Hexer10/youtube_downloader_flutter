import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:youtube_downloader_flutter/src/search_bar.dart';

import 'app_drawer.dart';


@immutable
class HomePage extends HookWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Here goes the logo(?)')),
      drawer: AppDrawer(),
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight), child: SearchBar()),
    );
  }
}
