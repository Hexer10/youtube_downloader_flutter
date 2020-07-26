import 'dart:io';
import 'package:flutter/material.dart';
import 'common.dart';
import 'package:path/path.dart' as Path;

class FilesystemListTile extends StatelessWidget {
  static double iconSize = 32;

  final FilesystemType fsType;
  final FileSystemEntity item;
  final ValueChanged<Directory> onChange;
  final ValueSelected onSelect;

  FilesystemListTile({
    Key key,
    this.fsType = FilesystemType.all,
    @required this.item,
    @required this.onChange,
    @required this.onSelect,
  }) : super(key: key);

  Widget _leading(BuildContext context) {
    if (item is Directory) {
      return Icon(
        Icons.folder,
        color: (Theme.of(context).brightness == Brightness.dark)
            ? Theme.of(context).primaryIconTheme.color
            : Theme.of(context).primaryColor,
        size: iconSize,
      );
    } else {
      return _fileIcon(item.path, Theme.of(context).unselectedWidgetColor);
    }
  }

  /// Set the icon for a file
  Icon _fileIcon(String filename, Color color) {
    IconData icon = Icons.description;

    final _extension = filename.split(".").last;
    if (_extension == "db" ||
        _extension == "sqlite" ||
        _extension == "sqlite3") {
      icon = Icons.dns;
    } else if (_extension == "jpg" ||
        _extension == "jpeg" ||
        _extension == "png") {
      icon = Icons.image;
    }
    // default
    return Icon(
      icon,
      color: color,
      size: iconSize,
    );
  }

  Widget _trailing(BuildContext context) {
    if ((fsType == FilesystemType.all) ||
        ((fsType == FilesystemType.file) && (item is File))) {
      return InkResponse(
        child: Icon(
          Icons.check_circle,
          color: Theme.of(context).disabledColor,
        ),
        onTap: () => onSelect(item.absolute.path),
      );
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key(item.absolute.path),
      leading: _leading(context),
      trailing: _trailing(context),
      title: Text(Path.basename(item.path), textScaleFactor: 1.2),
      onTap: () {
        if (item is Directory) {
          onChange(item);
        }
      },
    );
  }
}
