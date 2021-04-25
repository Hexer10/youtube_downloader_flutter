import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:path/path.dart' as path;


Future<String?> showFolderPicker(BuildContext context, String title, Directory startDir) {
  return Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (context) =>
          LinuxFolderPicker(
              startDir: startDir, title: title)
  ));
}

class LinuxFolderPicker extends HookWidget {
  final String title;
  final Directory startDir;

  const LinuxFolderPicker({Key? key, required this.title, required this.startDir})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FolderList(startDir: startDir),
    );
  }
}

class FolderList extends HookWidget {
  final Directory startDir;

  const FolderList({Key? key, required this.startDir}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentDirState = useState<Directory>(startDir);
    final currentDir = currentDirState.value;

    final isRoot = currentDir.path == currentDir.parent.path;

    final dirs = <DirSpec>[if (!isRoot) DirSpec('..', Directory(''))];
    var error = false;

    try {
      dirs.addAll(currentDir
          .listSync()
          .where((e) => e.statSync().type == FileSystemEntityType.directory)
          .map((e) {
        final pathSegments = e.uri.pathSegments;
        return DirSpec(
            pathSegments[pathSegments.length - 2], Directory(e.path));
      }));
    } on FileSystemException catch (e) {
      error = true;
      return Column(
        children: [
          ListTile(
            onTap: () {
              currentDirState.value = currentDir.parent;
            },
            title: const Text('..', style: TextStyle(fontSize: 20)),
            leading: const Icon(Icons.arrow_upward_rounded),
          ),
          Text(e.osError?.message ?? 'Error',
              style: Theme.of(context).textTheme.headline5),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
              itemCount: dirs.length,
              itemBuilder: (context, index) {
                final dir = dirs[index];
                return ListTile(
                  onTap: () {
                    if (dir.name == '..') {
                      currentDirState.value = currentDir.parent;
                      return;
                    }
                    currentDirState.value =
                        Directory(path.join(currentDir.path, dir.name));
                  },
                  title: Text(dir.name, style: const TextStyle(fontSize: 20)),
                  leading: Icon(dir.name == '..'
                      ? Icons.arrow_upward_rounded
                      : Icons.folder),
                );
              }),
        ),
        if (!error)
          ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.check,
                    size: 25,
                  ),
                  SizedBox(width: 5),
                  Text('Select current directory',
                      style: TextStyle(fontSize: 20)),
                ],
              ),
              onTap: () {
                Navigator.pop<String>(context, currentDir.path);
              })
      ],
    );
  }
}

class DirSpec {
  final String name;
  final Directory directory;

  DirSpec(this.name, this.directory);

  DirSpec.fromDirectory(this.directory)
      : name = directory.uri.pathSegments.last;
}
