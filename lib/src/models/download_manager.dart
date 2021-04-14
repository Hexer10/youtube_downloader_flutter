import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_downloader_flutter/main.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'settings.dart';

part 'download_manager.g.dart';

class DownloadManager extends ChangeNotifier {
  DownloadManager();

  Future<void> downloadStream(YoutubeExplode yt, Video video, Settings settings,
          StreamType type, AppLocalizations localizations,
          {StreamInfo? singleStream,
          StreamMerge? merger,
          String? ffmpegContainer}) =>
      throw UnimplementedError();

  Future<void> removeVideo(SingleTrack video) => throw UnimplementedError();

  List<SingleTrack> get videos => throw UnimplementedError();
}

class DownloadManagerImpl extends ChangeNotifier implements DownloadManager {
  static final invalidChars = RegExp(r'[\\\/:*?"<>|]');

  final SharedPreferences _prefs;

  @override
  final List<SingleTrack> videos;
  final List<String> videoIds;

  final Map<int, bool> cancelTokens = {};

  int _nextId;

  int get nextId {
    _prefs.setInt('next_id', ++_nextId);
    return _nextId;
  }

  DownloadManagerImpl._(this._prefs, this._nextId, this.videoIds, this.videos);

  void addVideo(SingleTrack video) {
    final id = 'video_${video.id}';
    videoIds.add(id);

    _prefs.setStringList('video_list', videoIds);
    _prefs.setString(id, json.encode(video));

    notifyListeners();
  }

  @override
  Future<void> removeVideo(SingleTrack video) async {
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
      StreamType type, AppLocalizations localizations,
      {StreamInfo? singleStream,
      StreamMerge? merger,
      String? ffmpegContainer}) async {
    assert(singleStream != null || merger != null);
    assert(merger == null ||
        merger.video != null &&
            merger.audio != null &&
            ffmpegContainer != null);

    if (Platform.isAndroid || Platform.isIOS) {
      final req = await Permission.storage.request();
      if (!req.isGranted) {
        showSnackbar(SnackBar(content: Text(localizations.permissionError)));
        return;
      }
    }

    final isMerging = singleStream == null;
    final stream = singleStream ?? merger!.video!;
    final id = nextId;
    final saveDir = settings.downloadPath;

    if (isMerging) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final process = await Process.run('ffmpeg', [], runInShell: true);
        if (!(process.stderr as String).startsWith("ffmpeg version")) {
          showSnackbar(SnackBar(content: Text(localizations.ffmpegNotFound)));
          return;
        }
      }
      processMuxedTrack(yt, video, merger!, stream, saveDir, id,
          ffmpegContainer!, settings, localizations);
    } else {
      processSingleTrack(yt, video, stream, saveDir, id, type, localizations);
    }
  }

  Future<void> processSingleTrack(
      YoutubeExplode yt,
      Video video,
      StreamInfo stream,
      String saveDir,
      int id,
      StreamType type,
      AppLocalizations localizations) async {
    final downloadPath = await getValidPath(
        '${path.join(saveDir, video.title.replaceAll(invalidChars, '_'))}${'.${stream.container.name}'}');

    final tempPath = path.join(saveDir, 'Unconfirmed $id.ytdownload');

    final file = File(tempPath);
    final sink = file.openWrite();
    final dataStream = yt.videos.streamsClient.get(stream);

    final downloadVideo = SingleTrack(id, downloadPath, video.title,
        bytesToString(stream.size.totalBytes), stream.size.totalBytes, type,
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
        content: Text(
      localizations.startDownload(video.title),
    )));
  }

  Future<void> processMuxedTrack(
      YoutubeExplode yt,
      Video video,
      StreamMerge merger,
      StreamInfo stream,
      String saveDir,
      int id,
      String ffmpegContainer,
      Settings settings,
      AppLocalizations localizations) async {
    final downloadPath = await getValidPath(
        '${path.join(settings.downloadPath, video.title.replaceAll(invalidChars, '_'))}$ffmpegContainer');

    final audioTrack = processTrack(yt, merger.audio!, saveDir,
        stream.container.name, video, StreamType.audio, localizations);

    final videoTrack = processTrack(yt, merger.video!, saveDir,
        stream.container.name, video, StreamType.video, localizations);

    final muxedTrack = MuxedTrack(
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

      localizations.cancelDownload(video.title);
    };

    Future<void> downloadListener() async {
      muxedTrack.downloadedBytes =
          audioTrack.downloadedBytes + videoTrack.downloadedBytes;
      muxedTrack.downloadPerc =
          (muxedTrack.downloadedBytes / muxedTrack.totalSize * 100).floor();
      if (audioTrack.downloadStatus == DownloadStatus.success &&
          videoTrack.downloadStatus == DownloadStatus.success) {
        muxedTrack.downloadStatus = DownloadStatus.muxing;
        final path = await getValidPath(muxedTrack.path);
        muxedTrack.path = path;

        final args = [
          '-i',
          audioTrack.path,
          '-i',
          videoTrack.path,
          '-shortest',
          path,
        ];
        if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
          desktopFFMPEG(muxedTrack, audioTrack, videoTrack, path, args,
              downloadListener, video, localizations);
        } else {
          mobileFFMPEG(muxedTrack, audioTrack, videoTrack, path, args,
              downloadListener, video, localizations);
        }
      }
    }

    audioTrack.addListener(downloadListener);
    videoTrack.addListener(downloadListener);

    addVideo(muxedTrack);
    videos.add(muxedTrack);

    showSnackbar(
        SnackBar(content: Text(localizations.startDownload(video.title))));
  }

  Future<void> desktopFFMPEG(
      MuxedTrack muxedTrack,
      SingleTrack audioTrack,
      SingleTrack videoTrack,
      String outPath,
      List<String> args,
      VoidCallback downloadListener,
      Video video,
      AppLocalizations localizations) async {
    final process = await Process.start('ffmpeg', args, runInShell: true);
    process.exitCode.then((exitCode) async {
      //sigterm
      if (exitCode == -1) {
        return;
      }
      muxedTrack.downloadStatus = DownloadStatus.success;

      audioTrack.removeListener(downloadListener);
      videoTrack.removeListener(downloadListener);

      await File(audioTrack.path).delete();
      await File(videoTrack.path).delete();

      localizations.finishMerge(video.title);
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
      localizations.cancelMerge(video.title);
    };
  }

  Future<void> mobileFFMPEG(
      MuxedTrack muxedTrack,
      SingleTrack audioTrack,
      SingleTrack videoTrack,
      String outPath,
      List<String> args,
      VoidCallback downloadListener,
      Video video,
      AppLocalizations localizations) async {
    final ffmpeg = FlutterFFmpeg();
    final id = await ffmpeg.executeAsyncWithArguments(args, (execution) async {
      //TODO: See https://github.com/tanersener/flutter-ffmpeg/issues/286
      // This never gets called

      //killed
      if (execution.returnCode == 255) {
        return;
      }
      muxedTrack.downloadStatus = DownloadStatus.success;

      audioTrack.removeListener(downloadListener);
      videoTrack.removeListener(downloadListener);

      await File(audioTrack.path).delete();
      await File(videoTrack.path).delete();

      localizations.finishMerge(video.title);
    });

    final file = File(outPath);
    var oldSize = -1;

    // Currently the ffmpeg's executionCallback is never called so we have to
    // pool and check if the file is created and written to.
    Future.doWhile(() async {
      if (muxedTrack.downloadStatus == DownloadStatus.canceled) {
        return false;
      }

      if (!(await file.exists())) {
        await Future.delayed(const Duration(seconds: 2));
        return true;
      }
      final stat = await file.stat();
      final size = stat.size;
      if (oldSize != size) {
        oldSize = size;
        await Future.delayed(const Duration(seconds: 2));
        return true;
      }
      return false;
    }).then((_) async {
      if (muxedTrack.downloadStatus == DownloadStatus.canceled) {
        return;
      }

      muxedTrack.downloadStatus = DownloadStatus.success;

      audioTrack.removeListener(downloadListener);
      videoTrack.removeListener(downloadListener);

      await File(audioTrack.path).delete();
      await File(videoTrack.path).delete();

      localizations.finishMerge(video.title);
    });

    muxedTrack._cancelCallback = () async {
      audioTrack._cancelCallback!();
      videoTrack._cancelCallback!();

      ffmpeg.cancelExecution(id);
      muxedTrack.downloadStatus = DownloadStatus.canceled;
      localizations.cancelMerge(video.title);
    };
  }

  SingleTrack processTrack(
      YoutubeExplode yt,
      StreamInfo stream,
      String saveDir,
      String container,
      Video video,
      StreamType type,
      AppLocalizations localizations) {
    final id = nextId;
    final tempPath =
        path.join(saveDir, 'Unconfirmed $id.ytdownload.$container');

    final file = File(tempPath);
    final sink = file.openWrite();

    final downloadVideo = SingleTrack(id, tempPath, 'Temp$id',
        bytesToString(stream.size.totalBytes), stream.size.totalBytes, type,
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
    }, cancelOnError: true);

    downloadVideo._cancelCallback = () async {
      await cleanUp(sink, file);
      downloadVideo.downloadStatus = DownloadStatus.canceled;
      sub.cancel();
    };
    return downloadVideo;
  }

  void handleData(List<int> bytes, IOSink sink, SingleTrack video) {
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
    final videos = <SingleTrack>[];
    for (final id in videoIds) {
      final jsonVideo = prefs.getString(id)!;
      final track =
          SingleTrack.fromJson(json.decode(jsonVideo) as Map<String, dynamic>);
      if (track.downloadStatus == DownloadStatus.downloading ||
          track.downloadStatus == DownloadStatus.muxing) {
        track.downloadStatus = DownloadStatus.failed;
        track.error = 'Error occurred while downloading';
        prefs.setString(id, json.encode(track));
      }
      videos.add(track);
    }
    return DownloadManagerImpl._(prefs, nextId, videoIds, videos);
  }
}

@JsonSerializable()
class SingleTrack extends ChangeNotifier {
  final int id;
  final String title;
  final String size;
  final int totalSize;
  @JsonKey(required: false, defaultValue: StreamType.video)
  final StreamType streamType;

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

  SingleTrack(this.id, String path, this.title, this.size, this.totalSize,
      this.streamType,
      {SharedPreferences? prefs})
      : _path = path,
        _prefs = prefs;

  factory SingleTrack.fromJson(Map<String, dynamic> json) =>
      _$SingleTrackFromJson(json);

  Map<String, dynamic> toJson() => _$SingleTrackToJson(this);

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
class MuxedTrack extends SingleTrack {
  final SingleTrack audio;
  final SingleTrack video;

  @JsonKey()
  @override
  final StreamType streamType;

  MuxedTrack(int id, String path, String title, String size, int totalSize,
      this.audio, this.video,
      {SharedPreferences? prefs, this.streamType = StreamType.video})
      : super(id, path, title, size, totalSize, streamType, prefs: prefs);

  factory MuxedTrack.fromJson(Map<String, dynamic> json) =>
      _$MuxedTrackFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MuxedTrackToJson(this);
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

enum DownloadStatus { downloading, success, failed, muxing, canceled }

enum StreamType { audio, video }
