import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:youtube_downloader_flutter/src/models/query_video.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

abstract class SearchService extends ChangeNotifier {
  FutureOr<void> nextPage();

  bool get loading;

  UnmodifiableListView<QueryVideo> get videos;

  factory SearchService(YoutubeExplode yt, String query) {
    final cid = ChannelId.parseChannelId(query);
    if (cid != null) {
      return _ChannelSearchServiceImpl(yt, cid);
    }
    return _VideoSearchServiceImpl(yt, query);
  }
}


class _ChannelSearchServiceImpl extends ChangeNotifier implements SearchService {
  final YoutubeExplode yt;
  final String channelId;

  bool _loading = false;

  @override
  bool get loading => _loading;

  final List<QueryVideo> _videos = <QueryVideo>[];

  @override
  UnmodifiableListView<QueryVideo> get videos => UnmodifiableListView(_videos);

  var _endResults = false;
  late ChannelUploadsList _currentPage;

  _ChannelSearchServiceImpl(this.yt, this.channelId) {
    yt.channels.getUploadsFromPage(channelId).then((value) {
      _videos.addAll(value.where((e) => !e.isLive).map((e) =>
          QueryVideo(
              e.title,
              e.id.value,
              e.author,
              e.duration!,
              e.thumbnails.highResUrl)));
      _loading = false;
      _currentPage = value;
      notifyListeners();
    });
  }

  @override
  Future<void> nextPage() async {
    if (_endResults) {
      return;
    }

    if (loading) {
      throw Exception('Cannot request the next page while loading.');
    }
    _loading = true;
    notifyListeners();

    final page = await _currentPage.nextPage();
    if (page == null) {
      _loading = false;
      _endResults = true;
      notifyListeners();
      return;
    }
    _currentPage = page;
    _videos.addAll(_currentPage.where((e) => !e.isLive).map((e) =>
        QueryVideo(
            e.title, e.id.value, e.author, e.duration!,
            e.thumbnails.highResUrl)));
    _loading = false;
    notifyListeners();
  }
}


class _VideoSearchServiceImpl extends ChangeNotifier implements SearchService {
  final YoutubeExplode yt;
  final String query;

  bool _loading = false;

  @override
  bool get loading => _loading;

  final List<QueryVideo> _videos = <QueryVideo>[];

  @override
  UnmodifiableListView<QueryVideo> get videos => UnmodifiableListView(_videos);

  var _endResults = false;
  late SearchList _currentPage;

  _VideoSearchServiceImpl(this.yt, this.query) {
    yt.search.getVideos(query).then((value) {
      _videos.addAll(value.where((e) => !e.isLive).map((e) =>
          QueryVideo(
              e.title,
              e.id.value,
              e.author,
              e.duration!,
              e.thumbnails.highResUrl)));
      _loading = false;
      _currentPage = value;
      notifyListeners();
    });
  }

  @override
  Future<void> nextPage() async {
    if (_endResults) {
      return;
    }

    if (loading) {
      throw Exception('Cannot request the next page while loading.');
    }
    _loading = true;
    notifyListeners();

    final page = await _currentPage.nextPage();
    if (page == null) {
      _loading = false;
      _endResults = true;
      notifyListeners();
      return;
    }
    _currentPage = page;
    _videos.addAll(_currentPage.where((e) => !e.isLive).map((e) =>
        QueryVideo(
            e.title, e.id.value, e.author, e.duration!,
            e.thumbnails.highResUrl)));
    _loading = false;
    notifyListeners();
  }
}
