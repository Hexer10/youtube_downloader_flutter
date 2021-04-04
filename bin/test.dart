import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<void> main() async {
  final yt = YoutubeExplode();

  final manifest = await yt.videos.streamsClient.getManifest('9bZkp7q19f0');
  final stream = manifest.videoOnly.first;
  final size = stream.size.totalBytes;
  var downloadBytes = 0;
  var lastPerc = -1;
  print(stream.size);
  final sub = yt.videos.streamsClient.get(stream).listen((event) {
    downloadBytes += event.length;
    final currentPerc = (downloadBytes / size * 100).toInt();
    if (currentPerc == lastPerc) {
      return;
    }
    lastPerc = currentPerc;
    print('Progress: $currentPerc');
  }, onError: (a, b) {
    print('Error! $a\n$b');
  }, onDone: () {
    print('Done!');
    yt.close();
  });
  Future<void>.delayed(const Duration(seconds: 3)).then((value) {
    print('Canceled!');
    sub.cancel();
  });
}
