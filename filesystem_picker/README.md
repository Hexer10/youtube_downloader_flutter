# FileSystem Picker

FileSystem file or folder picker dialog.

Allows the user to browse the file system and pick a folder or file.

## Getting Started

In your flutter project add the dependency:

```dart
dependencies:
  ...
  filesystem_picker: ^1.0.0
```

Import package:
```dart
import 'package:filesystem_picker/filesystem_picker.dart';
```

## Usage

To open the dialog, use the asynchronous `FilesystemPicker.open` method. The method returns the path to the selected folder or file as a string.
The method takes the following parameters:
* **context** - widget tree context, required parameter;
* **rootDirectory** - the root path to view the filesystem, required parameter;
* **rootName** - specifies the name of the filesystem view root in breadcrumbs, by default "Storage";
* **fsType** - specifies the type of filesystem view (folder and files, folder only or files only), by default `FilesystemType.all`;
* **pickText** - specifies the text for the folder selection button (only for `fsType` = `FilesystemType.folder`);
* **permissionText** - specifies the text of the message that there is no permission to access the storage, by default: "Access to the storage was not granted.";
* **title** - specifies the text of the dialog title;
* **allowedExtensions** - specifies a list of file extensions that will be displayed for selection, if empty - files with any extension are displayed. Example: `['.jpg', '.jpeg']`.

### Android permissions

To access the filesystem in Android, you must specify access permissions in the `AndroidManifest.xml` file, for example:
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_INTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

## Folder pick example

```dart
String path = await FilesystemPicker.open(
  title: 'Save to folder',
  context: context,
  rootDirectory: rootPath,
  fsType: FilesystemType.folder,
  pickText: 'Save file to this folder',
);
```
![](https://github.com/andyduke/filesystem_picker/blob/master/screenshots/folder_pick.png)

## File pick example

```dart
String path = await FilesystemPicker.open(
  title: 'Open file',
  context: context,
  rootDirectory: rootPath,
  fsType: FilesystemType.file,
  allowedExtensions: ['.txt'],
);
```
![](https://github.com/andyduke/filesystem_picker/blob/master/screenshots/file_pick.png)
