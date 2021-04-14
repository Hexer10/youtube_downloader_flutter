import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class SearchService extends ChangeNotifier {
  final YoutubeExplode yt;
  final String query;

  bool _loading = false;
  bool get loading => _loading;
  final List<Video> _videos = <Video>[];
  UnmodifiableListView<Video> get videos => UnmodifiableListView(_videos);

  var _endResults = false;
  late SearchList _currentPage;

  SearchService(this.yt, this.query) {
    yt.search.getVideos(query).then((value) {
      _videos.addAll(value.where((e) => !e.isLive));
      _loading = false;
      _currentPage = value;
      notifyListeners();
    });
  }

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
    _videos.addAll(_currentPage.where((e) => !e.isLive));
    _loading = false;
    notifyListeners();
  }
}
