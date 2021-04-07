import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_downloader_flutter/main.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'settings.dart';

part 'download_manager.g.dart';

class DownloadManager extends ChangeNotifier {
  DownloadManager();

  Future<void> downloadStream(YoutubeExplode yt, Video video, Settings settings,
          AppLocalizations localizations,
          {StreamInfo? singleStream,
          StreamMerge? merger,
          String? ffmpegContainer}) =>
      throw UnimplementedError();

  Future<void> removeVideo(DownloadVideo video) => throw UnimplementedError();

  List<DownloadVideo> get videos => throw UnimplementedError();
}

class DownloadManagerImpl extends ChangeNotifier implements DownloadManager {
  static final invalidChars = RegExp(r'[\\\/:*?"<>|]');

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

  void addVideo(DownloadVideo video) {
    final id = 'video_${video.id}';
    videoIds.add(id);

    _prefs.setStringList('video_list', videoIds);
    _prefs.setString(id, json.encode(video));

    notifyListeners();
  }

  @override
  Future<void> removeVideo(DownloadVideo video) async {
    final id = 'video_${video.id}';

    videoIds.remove(id);
    videos.removeWhere((e) => e.id == video.id);

    _prefs.setStringList('video_list', videoIds);
    _prefs.remove(id);

    final file = File(video.path);
    if (await file.exists()) {
      await file.delete();
    }

    notifyListeners();
  }

  Future<String> getValidPath(String strPath) async {
    final file = File(strPath);
    if (!(await file.exists())) {
      return strPath;
    }
    final basename = path
        .withoutExtension(strPath)
        .replaceFirst(RegExp(r' \([0-9]+\)$'), '');
    final ext = path.extension(strPath);

    var count = 0;

    while (true) {
      final newPath = '$basename (${++count})$ext';
      final file = File(newPath);
      if (await file.exists()) {
        continue;
      }
      return newPath;
    }
  }

  @override
  Future<void> downloadStream(YoutubeExplode yt, Video video, Settings settings,
      AppLocalizations localizations,
      {StreamInfo? singleStream,
      StreamMerge? merger,
      String? ffmpegContainer}) async {
    assert(singleStream != null || merger != null);
    assert(merger == null ||
        merger.video != null &&
            merger.audio != null &&
            ffmpegContainer != null);

    final isMerging = singleStream == null;
    final stream = singleStream ?? merger!.video!;
    final id = nextId;
    final saveDir = settings.downloadPath;

    if (isMerging) {
      final process = await Process.run('ffmpeg', [], runInShell: true);
      if ((process.stderr as String)
          .startsWith("'ffmpeg'  is not recognized as an internal")) {
        //TODO: Show dialog/snackbar
        print('ffmpeg not found');
        return;
      }
      merger!;

      final downloadPath = await getValidPath(
          '${path.join(settings.downloadPath, video.title.replaceAll(invalidChars, '_'))}$ffmpegContainer');

      final audioTrack = processTrack(yt, merger.audio!, saveDir,
          stream.container.name, video, localizations);
      final videoTrack = processTrack(yt, merger.video!, saveDir,
          stream.container.name, video, localizations);
      final muxedTrack = DownloadVideoTracks(
          id,
          downloadPath,
          video.title,
          bytesToString(videoTrack.totalSize + audioTrack.totalSize),
          videoTrack.totalSize + audioTrack.totalSize,
          audioTrack,
          videoTrack,
          prefs: _prefs);
      muxedTrack._cancelCallback = () {
        audioTrack._cancelCallback!();
        videoTrack._cancelCallback!();

        muxedTrack.downloadStatus = DownloadStatus.canceled;
      };

      Future<void> downloadListener() async {
        muxedTrack.downloadPerc =
            (muxedTrack.downloadedBytes / muxedTrack.totalSize).round();
        if (audioTrack.downloadStatus == DownloadStatus.success &&
            videoTrack.downloadStatus == DownloadStatus.success) {
          muxedTrack.downloadStatus = DownloadStatus.muxing;
          final path = await getValidPath(muxedTrack.path);
          muxedTrack.path = path;
          final process = await Process.start('ffmpeg',
              ['-i', audioTrack.path, '-i', videoTrack.path, '-shortest', path],
              runInShell: true);
          process.exitCode.then((exitCode) async {
            //sigterm
            if (exitCode == -1) {
              return;
            }
            print('Completed with: $exitCode');
            muxedTrack.downloadStatus = DownloadStatus.success;

            audioTrack.removeListener(downloadListener);
            videoTrack.removeListener(downloadListener);

            await File(audioTrack.path).delete();
            await File(videoTrack.path).delete();
          });

          process.stdout.listen((event) {
            print('OUT: ${utf8.decode(event)}');
          });
          process.stderr.listen((event) {
            print('ERR: ${utf8.decode(event)}');
          });

          muxedTrack._cancelCallback = () async {
            audioTrack._cancelCallback!();
            videoTrack._cancelCallback!();

            process.kill();
            muxedTrack.downloadStatus = DownloadStatus.canceled;
          };
        }
      }

      audioTrack.addListener(downloadListener);
      videoTrack.addListener(downloadListener);

      addVideo(muxedTrack);
      videos.add(muxedTrack);

      showSnackbar(SnackBar(
        content: Theme(
            data: settings.theme.themeData,
            child: Text(localizations.startDownload(video.title))),
        backgroundColor: settings.theme.themeData.snackBarTheme.backgroundColor,
      ));
    } else {
      final downloadPath = await getValidPath(
          '${path.join(saveDir, video.title.replaceAll(invalidChars, '_'))}${'.${stream.container.name}'}');

      final tempPath = path.join(saveDir, 'Unconfirmed $id.ytdownload');

      final file = File(tempPath);
      final sink = file.openWrite();
      final dataStream = yt.videos.streamsClient.get(stream);

      final downloadVideo = DownloadVideo(id, downloadPath, video.title,
          bytesToString(stream.size.totalBytes), stream.size.totalBytes,
          prefs: _prefs);

      addVideo(downloadVideo);
      videos.add(downloadVideo);

      final sub = dataStream
          .listen((data) => handleData(data, sink, downloadVideo),
              onError: (error, __) async {
        showSnackbar(
            SnackBar(content: Text(localizations.failDownload(video.title))));
        await cleanUp(sink, file);
        downloadVideo.downloadStatus = DownloadStatus.failed;
        downloadVideo.error = error.toString();
      }, onDone: () async {
        final newPath = await cleanUp(sink, file, downloadPath);
        downloadVideo.downloadStatus = DownloadStatus.success;
        downloadVideo.path = newPath!;
        showSnackbar(
            SnackBar(content: Text(localizations.finishDownload(video.title))));
      }, cancelOnError: true);

      downloadVideo._cancelCallback = () async {
        await cleanUp(sink, file);
        downloadVideo.downloadStatus = DownloadStatus.canceled;
        sub.cancel();

        showSnackbar(
            SnackBar(content: Text(localizations.cancelDownload(video.title))));
      };

      showSnackbar(SnackBar(
        content: Theme(
            data: settings.theme.themeData,
            child: Text(localizations.startDownload(video.title))),
        backgroundColor: settings.theme.themeData.snackBarTheme.backgroundColor,
      ));
    }
  }

  DownloadVideo processTrack(
      YoutubeExplode yt,
      StreamInfo stream,
      String saveDir,
      String container,
      Video video,
      AppLocalizations localizations) {
    final id = nextId;
    final tempPath =
        path.join(saveDir, 'Unconfirmed $id.ytdownload.$container');

    final file = File(tempPath);
    final sink = file.openWrite();

    final downloadVideo = DownloadVideo(id, tempPath, 'Temp$id',
        bytesToString(stream.size.totalBytes), stream.size.totalBytes,
        prefs: _prefs);

    final dataStream = yt.videos.streamsClient.get(stream);
    final sub = dataStream
        .listen((data) => handleData(data, sink, downloadVideo),
            onError: (error, __) async {
      await cleanUp(sink, file);
      downloadVideo.downloadStatus = DownloadStatus.failed;
      downloadVideo.error = error.toString();

      showSnackbar(
          SnackBar(content: Text(localizations.failDownload(video.title))));
    }, onDone: () async {
      await sink.flush();
      await sink.close();
      downloadVideo.downloadStatus = DownloadStatus.success;

      showSnackbar(
          SnackBar(content: Text(localizations.finishMerge(video.title))));
    }, cancelOnError: true);

    downloadVideo._cancelCallback = () async {
      await cleanUp(sink, file);
      downloadVideo.downloadStatus = DownloadStatus.canceled;
      sub.cancel();
    };
    return downloadVideo;
  }

  void handleData(List<int> bytes, IOSink sink, DownloadVideo video) {
    sink.add(bytes);
    video.downloadedBytes += bytes.length;
    final newProgress = (video.downloadedBytes / video.totalSize * 100).floor();
    video.downloadPerc = newProgress;
  }

  /// Flushes and closes the sink.
  /// If path is specified the file is moved to that path, otherwise is it deleted.
  /// Returns the new file path if [path] is specified.
  Future<String?> cleanUp(IOSink sink, File file, [String? path]) async {
    await sink.flush();
    await sink.close();
    if (path != null) {
      // ignore: parameter_assignments
      path = await getValidPath(path);
      await file.rename(path);
      return path;
    }
    await file.delete();
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
class DownloadVideo extends ChangeNotifier {
  final int id;
  final String title;
  final String size;
  final int totalSize;

  String _path;

  int _downloadPerc = 0;
  DownloadStatus _downloadStatus = DownloadStatus.downloading;
  int _downloadedBytes = 0;
  String _error = '';

  String get path => _path;

  int get downloadPerc => _downloadPerc;

  DownloadStatus get downloadStatus => _downloadStatus;

  int get downloadedBytes => _downloadedBytes;

  String get error => _error;

  set path(String path) {
    _path = path;

    _prefs?.setString('video_$id', json.encode(this));
    notifyListeners();
  }

  set downloadPerc(int value) {
    _downloadPerc = value;

    _prefs?.setString('video_$id', json.encode(this));
    notifyListeners();
  }

  set downloadStatus(DownloadStatus value) {
    _downloadStatus = value;

    _prefs?.setString('video_$id', json.encode(this));
    notifyListeners();
  }

  set downloadedBytes(int value) {
    _downloadedBytes = value;

    _prefs?.setString('video_$id', json.encode(this));
    notifyListeners();
  }

  set error(String value) {
    _error = value;
    _prefs?.setString('video_$id', json.encode(this));

    notifyListeners();
  }

  @JsonKey(ignore: true)
  VoidCallback? _cancelCallback;

  @JsonKey(ignore: true)
  final SharedPreferences? _prefs;

  DownloadVideo(this.id, this._path, this.title, this.size, this.totalSize,
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
}

/// Used when downloading both Video and Audio tracks to be merged.
@JsonSerializable()
class DownloadVideoTracks extends DownloadVideo {
  final DownloadVideo audio;
  final DownloadVideo video;

  DownloadVideoTracks(int id, String path, String title, String size,
      int totalSize, this.audio, this.video,
      {SharedPreferences? prefs})
      : super(id, path, title, size, totalSize, prefs: prefs);

  factory DownloadVideoTracks.fromJson(Map<String, dynamic> json) =>
      _$DownloadVideoTracksFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$DownloadVideoTracksToJson(this);
}

class StreamMerge extends ChangeNotifier {
  AudioOnlyStreamInfo? _audio;

  AudioOnlyStreamInfo? get audio => _audio;

  set audio(AudioOnlyStreamInfo? audio) {
    _audio = audio;
    notifyListeners();
  }

  VideoOnlyStreamInfo? _video;

  VideoOnlyStreamInfo? get video => _video;

  set video(VideoOnlyStreamInfo? video) {
    _video = video;
    notifyListeners();
  }

  StreamMerge();
}

enum DownloadStatus { downloading, success, failed, muxing, canceled }

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

void showSnackbar(SnackBar snackBar) {
  AppInit.scaffoldKey.currentState!.showSnackBar(snackBar);
}
