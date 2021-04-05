import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_downloader_flutter/src/models/download_manager.dart';
import 'package:youtube_downloader_flutter/src/providers.dart';

class DownloadTile extends HookWidget {
  final DownloadVideo video;

  const DownloadTile(this.video, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final video = useListenable(this.video);
    return ListTile(
        onTap: video.downloadStatus == DownloadStatus.success
            ? () async {
                final url = 'file:${video.path}';
                if (await canLaunch(url)) {
                  launch(url);
                } else {
                  print('Cannot Launch');
                }
              }
            : null,
        title: Text(video.title),
        subtitle: Text(video.path),
        trailing: TrailingIcon(video),
        leading: LeadingIcon(video));
  }
}

class LeadingIcon extends HookWidget {
  final DownloadVideo video;

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
  final DownloadVideo video;

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
              //TODO: Remove video from list.
            });
      case DownloadStatus.success:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: () async {
                  final url = 'file:${path.dirname(video.path)}';
                  if (await canLaunch(url)) {
                    launch(url);
                  } else {
                    print('Cannot Launch');
                  }
                }),
            IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: () async {
                  downloadManager.removeVideo(video);
                }),
          ],
        );
      case DownloadStatus.failed:
        return Text(video.error);
      case DownloadStatus.muxing:
        return const Text('Merging!');
      case DownloadStatus.canceled:
        return const Text('Canceled!');
    }
  }
}
