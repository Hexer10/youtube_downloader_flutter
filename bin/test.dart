import 'package:path/path.dart' as path;

Future<void> main() async {
  final basename = path
      .withoutExtension(r'D:\Tools\Hello\Paolo.exe')
      .replaceFirst(RegExp(r'\([0-9]+\)'), '');
  final basename2 = path
      .withoutExtension(r'D:\Tools\Hello\Paolo (1).exe')
      .replaceFirst(RegExp(r'\([0-9]+\)$'), '');
  final basename3 = path
      .withoutExtension(r'D:\Tools\Hello\Paolo (2) (2).exe')
      .replaceFirst(RegExp(r'\([0-9]+\)$'), '');
  print(basename);
  print(basename2);
  print(basename3);
}
