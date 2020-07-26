import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as Path;
import 'package:permission_handler/permission_handler.dart';

import 'breadcrumbs.dart';
import 'common.dart';
import 'filesystem_list.dart';

class PathItem {
  final String text;
  final String path;

  PathItem({
    @required this.path,
    @required this.text,
  });

  @override
  String toString() {
    return '$text: $path';
  }
}

class FilesystemPicker extends StatefulWidget {
  /// Open FileSystemPicker dialog
  ///
  /// * [rootDirectory] specifies the root of the filesystem view.
  /// * [rootName] specifies the name of the filesystem view root in breadcrumbs, by default "Storage".
  /// * [fsType] specifies the type of filesystem view (folder and files, folder only or files only), by default `FilesystemType.all`.
  /// * [pickText] specifies the text for the folder selection button (only for [fsType] = FilesystemType.folder).
  /// * [permissionText] specifies the text of the message that there is no permission to access the storage, by default: "Access to the storage was not granted.".
  /// * [title] specifies the text of the dialog title.
  /// * [allowedExtensions] specifies a list of file extensions that will be displayed for selection, if empty - files with any extension are displayed. Example: `['.jpg', '.jpeg']`
  static Future<String> open({
    @required BuildContext context,
    @required Directory rootDirectory,
    String rootName = 'Storage',
    FilesystemType fsType = FilesystemType.all,
    String pickText,
    String permissionText,
    String title,
    List<String> allowedExtensions,
  }) async {
    final Completer<String> _completer = new Completer<String>();

    Navigator.of(context).push(
      MaterialPageRoute(builder: (BuildContext context) {
        return FilesystemPicker(
          rootDirectory: rootDirectory,
          rootName: rootName,
          fsType: fsType,
          pickText: pickText,
          permissionText: permissionText,
          title: title,
          allowedExtensions: allowedExtensions,
          onSelect: (String value) {
            _completer.complete(value);
            Navigator.of(context).pop();
          },
        );
      }),
    );

    return _completer.future;
  }

  // ---

  final String rootName;
  final Directory rootDirectory;
  final FilesystemType fsType;
  final ValueSelected onSelect;
  final String pickText;
  final String permissionText;
  final String title;
  final List<String> allowedExtensions;

  FilesystemPicker({
    Key key,
    this.rootName,
    @required this.rootDirectory,
    this.fsType = FilesystemType.all,
    this.pickText,
    this.permissionText,
    this.title,
    this.allowedExtensions,
    @required this.onSelect,
  }) : super(key: key);

  @override
  _FilesystemPickerState createState() => _FilesystemPickerState();
}

class _FilesystemPickerState extends State<FilesystemPicker> {
  bool permissionRequesting = true;
  bool permissionAllowed = false;

  Directory directory;
  Directory oldDirectory;
  String directoryName;
  List<PathItem> pathItems;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _setDirectory(widget.rootDirectory);
  }

  Future<void> _requestPermission() async {
    if (await Permission.storage.request().isGranted) {
      permissionAllowed = true;
    } else {
      // print('File permission is denied');
    }

    setState(() {
      permissionRequesting = false;
    });
  }

  void _setDirectory(Directory value) {
    oldDirectory = directory;
    directory = value;

    String dirPath = Path.relative(directory.path,
        from: Path.dirname(widget.rootDirectory.path));
    final List<String> items = dirPath.split(Platform.pathSeparator);
    pathItems = [];

    var segments = Path.split(directory.path);
    // pathItems.add(PathItem(path: rootPath, text: widget.rootName ?? rootItem));
    items.removeAt(0);

    String path = '/';
    pathItems.add(PathItem(path: '/', text: '/'));

    for (var item in segments.skip(1)) {
      path += Platform.pathSeparator + item;
      pathItems.add(PathItem(path: path, text: item));
    }

    for (var item in items) {
      path += Platform.pathSeparator + item;
      pathItems.add(PathItem(path: path, text: item));
    }

    directoryName = ((directory.path == widget.rootDirectory.path) &&
            (widget.rootName != null))
        ? widget.rootName
        : Path.basename(directory.path);
  }

  void _changeDirectory(Directory value, [bool force = false]) {
    if (force || directory != value) {
      setState(() {
        _setDirectory(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? directoryName),
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          Builder(builder: (context) {
            return IconButton(
              tooltip: 'Create new folder',
              icon: Icon(Icons.create_new_folder, color: Colors.white),
              onPressed: () async {
                var controller = TextEditingController();
                var value = await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                          actions: <Widget>[
                            IconButton(
                                icon: Icon(Icons.cancel, color: Colors.black),
                                onPressed: () => Navigator.pop(context, null)),
                            IconButton(
                              icon: Icon(
                                Icons.check_circle,
                                color: Colors.black,
                              ),
                              onPressed: () =>
                                  Navigator.pop(context, controller.value.text),
                            ),
                          ],
                          title: Text('Directory name.'),
                          content: TextField(
                              controller: controller,
                              decoration:
                                  InputDecoration(labelText: 'Directory')));
                    });
                if (value == null) {
                  return;
                }
                var newDir = Directory(Path.join(directory.path, value));
                if (newDir.existsSync()) {
                  Scaffold.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(
                          'A directory with the same name already exists!')));
                  return;
                }
                try {
                  newDir.createSync();
                  _changeDirectory(directory, true);
                } catch (e, s) {
                  print(e);
                  print(s);
                  Scaffold.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('An error occurred!')));
                }
              },
            );
          })
        ],
        bottom: PreferredSize(
          child: Theme(
            data: ThemeData(
              textTheme: TextTheme(
                button: TextStyle(
                    color: AppBarTheme.of(context)
                            .textTheme
                            ?.headline6
                            ?.color ??
                        Theme.of(context).primaryTextTheme?.headline6?.color),
              ),
            ),
            child: Breadcrumbs<String>(
              items: (!permissionRequesting && permissionAllowed)
                  ? pathItems
                      .map((path) => BreadcrumbItem<String>(
                          text: path.text, data: path.path))
                      .toList(growable: false)
                  : [],
              onSelect: (String value) {
                _changeDirectory(Directory(value));
              },
            ),
          ),
          preferredSize: const Size.fromHeight(50),
        ),
      ),
      body: permissionRequesting
          ? Center(child: CircularProgressIndicator())
          : (permissionAllowed
              ? Builder(
                  builder: (context) {
                    return FilesystemList(
                      isRoot: (directory.absolute.path ==
                          widget.rootDirectory.absolute.path),
                      rootDirectory: directory,
                      fsType: widget.fsType,
                      allowedExtensions: widget.allowedExtensions,
                      onChange: _changeDirectory,
                      onSelect: widget.onSelect,
                      onError: () {
                        Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text('Permissions denied!'),
                          backgroundColor: Colors.redAccent,
                        ));
                        _changeDirectory(oldDirectory);
                      },
                    );
                  },
                )
              : Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(20),
                  child: Text(
                      widget.permissionText ??
                          'Access to the storage was not granted.',
                      textScaleFactor: 1.2),
                )),
      bottomNavigationBar: (widget.fsType == FilesystemType.folder)
          ? Container(
              height: 50,
              child: BottomAppBar(
                color: Theme.of(context).primaryColor,
                child: Center(
                  child: FlatButton.icon(
                    textColor: AppBarTheme.of(context)
                            .textTheme
                            ?.headline6
                            ?.color ??
                        Theme.of(context).primaryTextTheme?.headline6?.color,
                    disabledTextColor:
                        (AppBarTheme.of(context).textTheme?.headline6?.color ??
                                Theme.of(context)
                                    .primaryTextTheme
                                    ?.headline6
                                    ?.color)
                            .withOpacity(0.5),
                    icon: Icon(Icons.check_circle),
                    label: (widget.pickText != null)
                        ? Text(widget.pickText)
                        : const SizedBox(),
                    onPressed: (!permissionRequesting && permissionAllowed)
                        ? () => widget.onSelect(directory.absolute.path)
                        : null,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
