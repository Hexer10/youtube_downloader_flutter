import 'dart:convert';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
Future<void> main() async {

  print('Merging!');
  final process = await Process.run('asdasd', [], runInShell: true);
  print('OUT: ${process.stdout}');
  print('ERR: ${process.stderr}');
}
