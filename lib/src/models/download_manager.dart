import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path/path.dart' as path;

part 'download_manager.g.dart';

class DownloadManager {
  const DownloadManager();

  void downloadStream(YoutubeExplode yt, Video video, StreamInfo stream,
      String saveDir, TextStyle? style) =>
      throw UnimplementedError();

  Future<void> removeVideo(DownloadVideo video) => throw UnimplementedError();

  List<DownloadVideo> get videos => throw UnimplementedError();
}

class DownloadManagerImpl implements DownloadManager {
  final SharedPreferences _prefs;

  @override
  final List<DownloadVideo> videos;
  final List<String> videoIds;

  final Map<int, bool> cancelTokens = {};

  int _nextId;

  int get nextId {
    _prefs.setInt('next_id', ++_nextId);
    return _nextId;
  }

  DownloadManagerImpl._(this._prefs, this._nextId, this.videoIds, this.videos);

  static final invalidChars = RegExp(r'[\\\/:*?"<>|]');

  void addVideo(DownloadVideo video) {
    final id = 'video_${video.id}';
    videoIds.add(id);

    _prefs.setStringList('video_list', videoIds);
    _prefs.setString(id, json.encode(video));
  }

  @override
  Future<void> removeVideo(DownloadVideo video) async {
    final id = 'video_${video.id}';
    videoIds.remove(id);
    videos.remove(video);
    _prefs.setStringList('video_list', videoIds);
    _prefs.remove(id);

    final file = File(video.path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> downloadStream(YoutubeExplode yt, Video video, StreamInfo stream,
      String saveDir, TextStyle? style) async {
    final id = nextId;

    final downloadPath =
        '${path.join(
        saveDir, video.title.replaceAll(invalidChars, '_'))}${'.${stream
        .container.name}'}';
    final tempPath = path.join(saveDir, 'Unconfirmed $id.ytdownload');

    print('Saving to: $downloadPath ($tempPath)');

    final file = File(tempPath);
    final sink = file.openWrite();
    var totalBytes = 0;
    final dataStream = yt.videos.streamsClient.get(stream);
    var progress = -1;

    final downloadVideo = DownloadVideo(
        id, downloadPath, video.title, bytesToString(stream.size.totalBytes),
        prefs: _prefs);

    addVideo(downloadVideo);
    videos.add(downloadVideo);

    final sub = dataStream.listen(
            (bytes) {
          sink.add(bytes);
          totalBytes += bytes.length;
          final newProgress =
          (totalBytes / stream.size.totalBytes * 100).floor();
          if (newProgress == progress) {
            return;
          }
          downloadVideo.downloadPerc = progress + 1;
          progress = newProgress;
          print(
              'Progress: ${bytesToString(totalBytes)} / ${bytesToString(
                  stream.size.totalBytes)} ($progress)');
        },
        cancelOnError: true,
        onError: (error, stack) async {
          showSnackbar(
              Text('${video.title} download failed!', style: style));
          print('Error occurred: $error\n$stack');
          await sink.flush();
          await sink.close();
          await file.delete();
          downloadVideo.downloadStatus = DownloadStatus.failed;
        },
        onDone: () async {
          print('Done!');

          await sink.flush();
          await sink.close();
          await file.rename(downloadPath);
          downloadVideo.downloadStatus = DownloadStatus.success;
          showSnackbar(
              Text('${video.title} download finished!', style: style));
        });
    downloadVideo._cancelCallback = () async {
      print('Video canceled');
      await sink.flush();
      await sink.close();
      await file.delete();
      downloadVideo.downloadStatus = DownloadStatus.failed;
      sub.cancel();
    };

    showSnackbar(
        Text('Started downloading: ${video.title}', style: style));
    }

  factory DownloadManagerImpl.init(SharedPreferences prefs) {
    var videoIds = prefs.getStringList('video_list');
    var nextId = prefs.getInt('next_id');
    if (videoIds == null) {
      prefs.setStringList('video_list', const []);
      videoIds = <String>[];
    }
    if (nextId == null) {
      prefs.setInt('next_id', 0);
      nextId = 1;
    }
    final videos = <DownloadVideo>[];
    for (final id in videoIds) {
      final jsonVideo = prefs.getString(id)!;
      videos.add(DownloadVideo.fromJson(
          json.decode(jsonVideo) as Map<String, dynamic>));
    }
    return DownloadManagerImpl._(prefs, nextId, videoIds, videos);
  }
}

@JsonSerializable()
class DownloadVideo extends Listenable {
  final int id;
  final String path;
  final String title;
  final String size;

  int _downloadPerc = 0;
  DownloadStatus _downloadStatus = DownloadStatus.downloading;

  int get downloadPerc => _downloadPerc;

  DownloadStatus get downloadStatus => _downloadStatus;

  set downloadPerc(int value) {
    _downloadPerc = value;
    _prefs?.setString('video_$id', json.encode(this));

    for (final e in listeners) {
      e();
    }
  }

  set downloadStatus(DownloadStatus value) {
    _downloadStatus = value;
    _prefs?.setString('video_$id', json.encode(this));

    for (final e in listeners) {
      e();
    }
  }

  @JsonKey(ignore: true)
  VoidCallback? _cancelCallback;

  @JsonKey(ignore: true)
  final SharedPreferences? _prefs;

  @JsonKey(ignore: true)
  final List<VoidCallback> listeners = [];

  DownloadVideo(this.id, this.path, this.title, this.size,
      {SharedPreferences? prefs})
      : _prefs = prefs;

  factory DownloadVideo.fromJson(Map<String, dynamic> json) =>
      _$DownloadVideoFromJson(json);

  Map<String, dynamic> toJson() => _$DownloadVideoToJson(this);

  void cancelDownload() {
    if (_cancelCallback == null) {
      print('Tried to cancel an uncancellable video');
      return;
    }
    _cancelCallback!();
  }

  @override
  void addListener(VoidCallback listener) {
    listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners.remove(listener);
  }
}

enum DownloadStatus { downloading, success, failed }

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

void showSnackbar(Widget message) {
  //TODO: Implement this
}
