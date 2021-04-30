

import 'dart:io';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  final dir = Directory('/var/log/private/');
  print(dir.listSync());
}