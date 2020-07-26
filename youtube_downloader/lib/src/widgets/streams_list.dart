import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:android_path_provider/android_path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_downloader/src/blocs/settings_bloc.dart';
import 'package:youtube_downloader/src/blocs/youtube/stream_download_bloc.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

import '../../main.dart';
import '../global.dart';

class StreamsList extends StatefulWidget {
  final Iterable<yt.StreamInfo> streams;
  final yt.Video video;

  StreamsList(
    this.streams,
    this.video, {
    Key key,
  }) : super(key: key);

  @override
  _StreamsListState createState() => _StreamsListState();
}

class _StreamsListState extends State<StreamsList> {
  Future<String> _getPath(yt.StreamInfo streamInfo) async {
    // ignore: close_sinks
    var bloc = BlocProvider.of<SettingsBloc>(context);

    var p = bloc.state.savePath;
    if (bloc.state.savePath == null) {
      p = await AndroidPathProvider.downloadsPath;
      bloc.add(SetSavePath(p));
    }

    p = path.join(p, '${widget.video.id}-${streamInfo.tag}');
    p = path.setExtension(p, '.${streamInfo.container.name}');
    return p;
  }

  Future<void> downloadStream(yt.StreamInfo streamInfo) async {
    var res = await Permission.storage.request();
    if (!res.isGranted) {
      print('Invalid perm: $res');
      return;
    }

    var p = await _getPath(streamInfo);

    var receivePort = ReceivePort();
    receivePort.listen((message) {
      if (message is SendPort) {
        message
            .send({'path': p, 'streamInfo': streamInfo, 'video': widget.video});
      }
      if (message is! Map<String, int>) {
        print('Invalid message: $message');
        return;
      }
      if (message['event'] == EV_START) {
        _showProgressNotification(widget.video, p, 0);
        MyHomePage.snackKey.currentState.showSnackBar(
            SnackBar(content: Text('Downloading ${widget.video.title}')));
      }
      if (message['event'] == EV_PROGRESS) {
        _showProgressNotification(widget.video, p, message['progress']);
      }
      if (message['event'] == EV_DONE) {
        _showProgressNotification(widget.video, p, 100);
        MyHomePage.snackKey.currentState.showSnackBar(SnackBar(
            content: Text('Download of ${widget.video.title} finished!')));
      }
      if (message['event'] == EV_FAIL) {
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text('Download of ${widget.video.title} failed!'),
          backgroundColor: Colors.redAccent,
        ));
      }
    });
    Isolate.spawn(_downloadIsolate, receivePort.sendPort);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        final stream = widget.streams.elementAt(index);
        if (stream is yt.MuxedStreamInfo) {
          File file;
          IOSink sink;
          return ListTile(
            onTap: () {
              return downloadStream(stream);
            },
            subtitle: Text(
                '${stream.videoQualityLabel} - ${stream.videoCodec} | ${stream.audioCodec}'),
            title: Text(
                'Video + Audio (.${stream.container}) - ${_bytesToString(stream.size.totalBytes)}'),
          );
        }
        if (stream is yt.VideoOnlyStreamInfo) {
          return ListTile(
            onTap: () => downloadStream(stream),
            subtitle:
                Text('${stream.videoQualityLabel} - ${stream.videoCodec}'),
            title: Text(
                'Video Only (.${stream.container}) - ${_bytesToString(stream.size.totalBytes)}'),
          );
        }
        if (stream is yt.AudioOnlyStreamInfo) {
          return ListTile(
            onTap: () => downloadStream(stream),
            subtitle: Text('${stream.audioCodec} | Bitrate: ${stream.bitrate}'),
            title: Text(
                'Audio Only (.${stream.container}) - ${_bytesToString(stream.size.totalBytes)}'),
          );
        }
        return ListTile(
            onTap: () => downloadStream(stream),
            title: Text('${stream.container} ${stream.runtimeType}'));
      },
      itemCount: widget.streams.length,
    );
  }

  String _bytesToString(int bytes) {
    final totalKiloBytes = bytes / 1024;
    final totalMegaBytes = totalKiloBytes / 1024;
    final totalGigaBytes = totalMegaBytes / 1024;

    String _getLargestSymbol() {
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

    num _getLargestValue() {
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

    return '${_getLargestValue().toStringAsFixed(2)} ${_getLargestSymbol()}';
  }
}

const EV_START = 0;
const EV_PROGRESS = 1;
const EV_DONE = 2;
const EV_FAIL = 3;

void _downloadIsolate(SendPort port) {
  var receivePort = ReceivePort();
  receivePort.listen((message) {
    // ignore: close_sinks
    print('Message: $message');
    var bloc = StreamDownloadBloc(ytRepository: repo);
    var file = File(message['path']);
    var sink = file.openWrite(mode: FileMode.writeOnlyAppend);
    var oldProgress = -1;
    bloc.listen((data) {
      if (data is StreamDownloadStart) {
        port.send(<String, int>{
          'event': EV_START,
        });
      }
      if (data is StreamDownloadProgress) {
        sink.add(data.bytes);

        var progress = data.progress.ceil();

        if (progress == oldProgress) {
          return;
        }
        oldProgress = progress;

        port.send(<String, int>{
          'event': EV_PROGRESS,
          'progress': progress,
        });
      }
      if (data is StreamDownloadDone) {
        bloc.close();
        sink.close();
        port.send(<String, int>{
          'event': EV_DONE,
        });
      }
      if (data is StreamDownloadFailure) {
        bloc.close();
        sink.close();
        port.send(<String, int>{
          'event': EV_FAIL,
        });
      }
    });
    bloc.add(StreamDownload(streamInfo: message['streamInfo']));
  });
  port.send(receivePort.sendPort);
}

final _downloadNotification = <yt.Video, int>{};
var _nextId = 0;

Future<void> _showProgressNotification(
    yt.Video video, String path, int progress) async {
  var maxProgress = 5;
  _downloadNotification[video] ??= _nextId++;
  var bigTextStyleInformation = BigTextStyleInformation(
    'Downloading <b>${video.title}</b> to $path.<br>Progress: $progress%',
    htmlFormatBigText: true,
    contentTitle: 'Downloading <b>${video.title}</b>',
    htmlFormatContentTitle: true,
  );
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'download video',
      'download video',
      'download video youtube video channel',
      styleInformation: bigTextStyleInformation,
      visibility: NotificationVisibility.Public,
      channelShowBadge: false,
      importance: Importance.Max,
      priority: Priority.High,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      ongoing: progress != 100,
      autoCancel: progress == 100,
      progress: progress);
  var iOSPlatformChannelSpecifics = IOSNotificationDetails();
  var platformChannelSpecifics = NotificationDetails(
      androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(_downloadNotification[video],
      'Downloading  ${video.title}', '$progress%', platformChannelSpecifics,
      payload: json.encode({'path': path, 'progress': progress}));
}
