import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path/path.dart' as path;

import '../providers.dart';
import '../shared.dart';

class StreamsList extends HookWidget {
  final Video video;

  const StreamsList(this.video);

  static const List<DropdownMenuItem<Filter>> items = [
    DropdownMenuItem(
      value: Filter.all,
      child: Text('All'),
    ),
    DropdownMenuItem(
      value: Filter.videoAudio,
      child: Text('Video + Audio'),
    ),
    DropdownMenuItem(
      value: Filter.video,
      child: Text('Video Only'),
    ),
    DropdownMenuItem(
      value: Filter.audio,
      child: Text('Audio Only'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final yt = useProvider(ytProvider);
    final settings = useProvider(settingsProvider).state;

    final filter = useState(Filter.all);
    final manifest = useMemoFuture(
        () => yt.videos.streamsClient.getManifest(video.id),
        initialData: null,
        keys: [video.id.value]);

    if (!manifest.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredList = filterStream(manifest.data!, filter.value);

    return AlertDialog(
      contentPadding: const EdgeInsets.only(top: 9),
      title: Text(
        video.title,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        softWrap: false,
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: double.maxFinite,
        child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final stream = filteredList[index];
              if (stream is MuxedStreamInfo) {
                return MaterialButton(
                  onPressed: () {
                    downloadStream(yt, video, stream, settings.downloadPath);
                  },
                  child: ListTile(
                    subtitle: Text(
                        '${stream.videoQualityLabel} - ${stream.videoCodec} | ${stream.audioCodec}'),
                    title: Text(
                        'Video + Audio (.${stream.container}) - ${bytesToString(stream.size.totalBytes)}'),
                  ),
                );
              }
              if (stream is VideoOnlyStreamInfo) {
                return MaterialButton(
                  onPressed: () {
                    downloadStream(yt, video, stream, settings.downloadPath);
                  },
                  child: ListTile(
                    subtitle: Text(
                        '${stream.videoQualityLabel} - ${stream.videoCodec}'),
                    title: Text(
                        'Video Only (.${stream.container}) - ${bytesToString(stream.size.totalBytes)}'),
                  ),
                );
              }
              if (stream is AudioOnlyStreamInfo) {
                return MaterialButton(
                  onPressed: () {
                    downloadStream(yt, video, stream, settings.downloadPath);
                  },
                  child: ListTile(
                    subtitle: Text(
                        '${stream.audioCodec} | Bitrate: ${stream.bitrate}'),
                    title: Text(
                        'Audio Only (.${stream.container}) - ${bytesToString(stream.size.totalBytes)}'),
                  ),
                );
              }
              return ListTile(
                  title: Text('${stream.container} ${stream.runtimeType}'));
            }),
      ),
      actions: <Widget>[
        DropdownButton<Filter>(
          value: filter.value,
          items: items,
          onChanged: (newFilter) {
            filter.value = newFilter!;
          },
        )
      ],
    );
  }

  List<StreamInfo> filterStream(StreamManifest manifest, Filter filter) {
    switch (filter) {
      case Filter.all:
        return manifest.streams.toList(growable: false);
      case Filter.videoAudio:
        return manifest.muxed.toList(growable: false);
      case Filter.audio:
        return manifest.audioOnly.toList(growable: false);
      case Filter.video:
        return manifest.videoOnly.toList(growable: false);
    }
  }

  String bytesToString(int bytes) {
    final totalKiloBytes = bytes / 1024;
    final totalMegaBytes = totalKiloBytes / 1024;
    final totalGigaBytes = totalMegaBytes / 1024;

    String getLargestSymbol() {
      if (totalGigaBytes.abs() >= 1) {
        return 'GB';
      }
      if (totalMegaBytes.abs() >= 1) {
        return 'MB';
      }
      if (totalKiloBytes.abs() >= 1) {
        return 'KB';
      }
      return 'B';
    }

    num getLargestValue() {
      if (totalGigaBytes.abs() >= 1) {
        return totalGigaBytes;
      }
      if (totalMegaBytes.abs() >= 1) {
        return totalMegaBytes;
      }
      if (totalKiloBytes.abs() >= 1) {
        return totalKiloBytes;
      }
      return bytes;
    }

    return '${getLargestValue().toStringAsFixed(2)} ${getLargestSymbol()}';
  }

  static final invalidChars = RegExp(r'([{0}]*\.+$)|([{0}]+)');

  Future<void> downloadStream(
      YoutubeExplode yt, Video video, StreamInfo stream, String saveDir) async {
    final downloadPath =
        '${path.join(saveDir, video.title.replaceAll(invalidChars, '_'))}${'.${stream.container.name}'}';
    print('Saving to: $downloadPath');

    final file = File(downloadPath);
    final sink = file.openWrite();
    var totalBytes = 0;
    final dataStream = yt.videos.streamsClient.get(stream);
    var progress = -1;
    dataStream.listen((bytes) {
      sink.add(bytes);
      totalBytes += bytes.length;
      final newProgress = (totalBytes / stream.size.totalBytes * 100).floor();
      if (newProgress == progress) {
        return;
      }
      progress = newProgress;
      print(
          'Progress: ${bytesToString(totalBytes)} / ${bytesToString(stream.size.totalBytes)} ($progress)');
    }, onDone: () {
      sink.close();
      print('Done!');
    });
  }
}

enum Filter {
  all,
  videoAudio,
  audio,
  video,
}
