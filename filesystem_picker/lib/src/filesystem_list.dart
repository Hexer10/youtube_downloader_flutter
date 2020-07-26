import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as Path;
import 'common.dart';
import 'filesystem_list_tile.dart';

class FilesystemList extends StatelessWidget {
  final bool isRoot;
  final Directory rootDirectory;
  final FilesystemType fsType;
  final List<String> allowedExtensions;
  final ValueChanged<Directory> onChange;
  final ValueSelected onSelect;
  final VoidCallback onError;

  FilesystemList({
    Key key,
    this.isRoot = false,
    @required this.rootDirectory,
    this.fsType = FilesystemType.all,
    this.allowedExtensions,
    @required this.onChange,
    @required this.onSelect,
    @required this.onError,
  }) : super(key: key);

  Future<List<FileSystemEntity>> _dirContents() {
    var files = <FileSystemEntity>[];
    var completer = new Completer<List<FileSystemEntity>>();
    var lister = this.rootDirectory.list(recursive: false);
    lister.listen(
      (file) {
        if ((fsType != FilesystemType.folder) || (file is Directory)) {
          if ((file is File) &&
              (allowedExtensions != null) &&
              (allowedExtensions.length > 0)) {
            if (!allowedExtensions.contains(Path.extension(file.path))) return;
          }
          files.add(file);
        }
      },
      onError: (e, s) {
        onError();
        completer.completeError(e, s);
      },
      cancelOnError: true,
      onDone: () {
        files.sort((a, b) => a.path.compareTo(b.path));
        completer.complete(files);
      },
    );
    return completer.future;
  }

  InkWell _topNavigation() {
    return InkWell(
      child: const ListTile(
        leading: Icon(Icons.arrow_upward, size: 32),
        title: Text("..", textScaleFactor: 1.5),
      ),
      onTap: () {
        final li = this.rootDirectory.path.split(Platform.pathSeparator)
          ..removeLast();
        onChange(Directory(li.join(Platform.pathSeparator)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _dirContents(),
      builder: (BuildContext context,
          AsyncSnapshot<List<FileSystemEntity>> snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: const CircularProgressIndicator(),
          );
        }
        if (snapshot.hasData) {
          return ListView.builder(
            shrinkWrap: true,
            itemCount: snapshot.data.length + (isRoot ? 0 : 1),
            itemBuilder: (BuildContext context, int index) {
              if (!isRoot && index == 0) {
                return _topNavigation();
              }

              final item = snapshot.data[index - (isRoot ? 0 : 1)];
              return FilesystemListTile(
                fsType: fsType,
                item: item,
                onChange: onChange,
                onSelect: onSelect,
              );
            },
          );
        } else {
          return const Center(
            child: const CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
