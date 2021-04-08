import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:youtube_downloader_flutter/src/models/download_manager.dart';
import 'package:youtube_downloader_flutter/src/providers.dart';

class DownloadTile extends HookWidget {
  final SingleTrack video;

  const DownloadTile(this.video, {Key? key}) : super(key: key);

  String? getFileType(SingleTrack video) {
    final path = video.path;
    switch (video.streamType) {
      case StreamType.audio:
        {
          if (path.endsWith('.mp4')) {
            return 'audio/mpeg';
          } else if (path.endsWith('.webm')) {
            return 'audio/webm';
          }
          return null;
        }
      case StreamType.video:
        {
          if (path.endsWith('.mp4')) {
            return 'video/mpeg';
          } else if (path.endsWith('.webm')) {
            return 'video/webm';
          } else if (path.endsWith('.mkv')) {
            return 'video/x-matroska';
          }
          return null;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = useListenable(this.video);
    return ListTile(
        onTap: video.downloadStatus == DownloadStatus.success
            ? () async {
                final res =
                    await OpenFile.open(video.path, type: getFileType(video));
                print('R: ${res.type} | M: ${res.message}');
              }
            : null,
        title: Text(video.title,
            style: video.downloadStatus == DownloadStatus.canceled ||
                    video.downloadStatus == DownloadStatus.failed
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null),
        subtitle: video.downloadStatus == DownloadStatus.failed
            ? Text(video.error)
            : Text(video.path,
                style: video.downloadStatus == DownloadStatus.canceled ||
                        video.downloadStatus == DownloadStatus.failed
                    ? const TextStyle(decoration: TextDecoration.lineThrough)
                    : null),
        trailing: TrailingIcon(video),
        leading: LeadingIcon(video));
  }
}

class LeadingIcon extends HookWidget {
  final SingleTrack video;

  const LeadingIcon(this.video, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (video.downloadStatus) {
      case DownloadStatus.downloading:
        return Text('${video.downloadPerc}%');
      case DownloadStatus.success:
        return const Icon(Icons.done);
      case DownloadStatus.failed:
        return const Icon(Icons.error);
      case DownloadStatus.muxing:
        return const CircularProgressIndicator();
      case DownloadStatus.canceled:
        return const Icon(Icons.cancel);
    }
  }
}

class TrailingIcon extends HookWidget {
  final SingleTrack video;

  const TrailingIcon(this.video, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final downloadManager = useProvider(downloadProvider).state;

    switch (video.downloadStatus) {
      case DownloadStatus.downloading:
        return IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: () async {
              video.cancelDownload();
            });
      case DownloadStatus.success:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: () async {
                  final res = await OpenFile.open(path.dirname(video.path));
                  print('R: ${res.type} | M: ${res.message}');
                }),
            IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: () async {
                  downloadManager.removeVideo(video);
                }),
          ],
        );
      case DownloadStatus.muxing:
        return IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: () async {
              video.cancelDownload();
            });
      case DownloadStatus.failed:
      case DownloadStatus.canceled:
        return IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              downloadManager.removeVideo(video);
            });
    }
  }
}
