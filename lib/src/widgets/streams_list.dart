import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:youtube_downloader_flutter/src/models/download_manager.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../providers.dart';
import '../shared.dart';

class StreamsList extends HookWidget {
  final Video video;

  StreamsList(this.video);

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

  final mergeTracks = StreamMerge();

  @override
  Widget build(BuildContext context) {
    final yt = useProvider(ytProvider);
    final settings = useProvider(settingsProvider).state;
    final downloadManager = useProvider(downloadProvider).state;

    final filter = useState(Filter.all);
    final merger = useListenable(mergeTracks);

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
                    downloadManager.downloadStream(yt, video, settings,
                        StreamType.video, AppLocalizations.of(context)!,
                        singleStream: stream);
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
                  onLongPress: () {
                    merger.video = stream;
                  },
                  onPressed: () {
                    downloadManager.downloadStream(yt, video, settings,
                        StreamType.video, AppLocalizations.of(context)!,
                        singleStream: stream);
                  },
                  child: ListTile(
                    subtitle: Text(
                        '${stream.videoQualityLabel} - ${stream.videoCodec}'),
                    title: Text(
                        'Video Only (.${stream.container}) - ${bytesToString(stream.size.totalBytes)}'),
                    trailing:
                        stream == merger.video ? const Icon(Icons.done) : null,
                  ),
                );
              }
              if (stream is AudioOnlyStreamInfo) {
                return MaterialButton(
                  onLongPress: () {
                    merger.audio = stream;
                  },
                  onPressed: () {
                    downloadManager.downloadStream(yt, video, settings,
                        StreamType.audio, AppLocalizations.of(context)!,
                        singleStream: stream);
                  },
                  child: ListTile(
                    subtitle: Text(
                        '${stream.audioCodec} | Bitrate: ${stream.bitrate}'),
                    title: Text(
                        'Audio Only (.${stream.container}) - ${bytesToString(stream.size.totalBytes)}'),
                    trailing:
                        stream == merger.audio ? const Icon(Icons.done) : null,
                  ),
                );
              }
              return ListTile(
                  title: Text('${stream.container} ${stream.runtimeType}'));
            }),
      ),
      actions: <Widget>[
        if (merger.audio != null && merger.video != null)
          OutlinedButton(
              style: ButtonStyle(
                  padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.all(20))),
              onPressed: () {
                downloadManager.downloadStream(yt, video, settings,
                    StreamType.video, AppLocalizations.of(context)!,
                    merger: merger, ffmpegContainer: settings.ffmpegContainer);
              },
              child: const Text('Download & Merge tracks!')),
        DropdownButton<Filter>(
          value: filter.value,
          items: items,
          onChanged: (newFilter) {
            filter.value = newFilter!;
          },
        ),
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
}

enum Filter {
  all,
  videoAudio,
  audio,
  video,
}
