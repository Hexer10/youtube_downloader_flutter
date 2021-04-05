import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../providers.dart';
import 'streams_list.dart';

// TODO: Maybe remove ValueNotifiers and make class extend ChangeNotifier
class SearchService {
  final YoutubeExplode yt;
  final String query;
  final ValueNotifier<List<Video>> videos = ValueNotifier<List<Video>>([]);
  final ValueNotifier<bool> loading = ValueNotifier<bool>(true);

  var _endResults = false;
  late SearchList _currentPage;

  SearchService(this.yt, this.query) {
    yt.search.getVideos(query).then((value) {
      videos.value = [...videos.value, ...value.where((e) => !e.isLive)];
      loading.value = false;
      _currentPage = value;
    });
  }

  Future<void> nextPage() async {
    if (_endResults) {
      return;
    }

    if (loading.value) {
      throw Exception('Cannot request the next page while loading.');
    }
    loading.value = true;
    final page = await _currentPage.nextPage();
    if (page == null) {
      loading.value = false;
      _endResults = true;
      return;
    }
    _currentPage = page;
    videos.value = [...videos.value, ..._currentPage.where((e) => !e.isLive)];
    loading.value = false;
  }
}

class SearchResult extends HookWidget {
  late final searchProvider = StateProvider.autoDispose(
      (ref) => SearchService(ref.read(ytProvider), query));
  final String query;

  SearchResult({required this.query, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final service = useProvider(searchProvider);

    if (size.width >= 560) {
      return LandscapeSearch(query: query, service: service.state);
    }
    return PortraitSearch(query: query, service: service.state);
  }
}

class LandscapeSearch extends HookWidget {
  final String query;
  final SearchService service;

  const LandscapeSearch({required this.query, required this.service, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final videoList = useValueListenable<List<Video>>(service.videos);
    final loading = useValueListenable<bool>(service.loading);

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: videoList.length + (loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (loading && index == videoList.length) {
          return Column(
            children: const [
              SizedBox(height: 10),
              CircularProgressIndicator(),
            ],
          );
        }
        final video = videoList[index];
        if (index > 1 && index == videoList.length - 1 && !loading) {
          Future.microtask(service.nextPage);
        }
        return GestureDetector(
          onTap: () {
            showDialog(
                context: context, builder: (context) => StreamsList(video));
          },
          child: Card(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            video.thumbnails.highResUrl,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                        Positioned(
                            right: 9,
                            bottom: 9,
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(.75),
                                  borderRadius: BorderRadius.circular(4)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 1),
                              child: Text(
                                _formatDuration(
                                    video.duration ?? const Duration()),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1
                                    ?.copyWith(
                                        fontSize: 11, color: Colors.white),
                              ),
                            )),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: AutoSizeText(
                        video.title,
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1
                            ?.copyWith(fontSize: 15),
                        textAlign: TextAlign.start,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 17),
                        child: AutoSizeText('From: ${video.author}',
                            style: Theme.of(context)
                                .textTheme
                                .subtitle1
                                ?.copyWith(
                                    fontSize: 13, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            minFontSize: 6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
    );
  }
}

class PortraitSearch extends HookWidget {
  final String query;
  final SearchService service;

  const PortraitSearch({required this.query, required this.service, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final videoList = useValueListenable<List<Video>>(service.videos);
    final loading = useValueListenable<bool>(service.loading);
    print('Loading: $loading');
    final scrollController = useScrollController();

    useEffect(() {
      scrollController.addListener(() {
        if (scrollController.position.atEdge &&
            scrollController.position.pixels != 0) {
          if (!service.loading.value) {
            service.nextPage();
          }
        }
      });
    }, []);

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(top: 10),
      itemCount: videoList.length + (loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (loading && index == videoList.length) {
          return Column(
            children: const [
              SizedBox(height: 10),
              CircularProgressIndicator(),
            ],
          );
        }
        final video = videoList[index];
        return GestureDetector(
          onTap: () {
            showDialog(
                context: context, builder: (context) => StreamsList(video));
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          video.thumbnails.highResUrl,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                      Positioned(
                          right: 9,
                          bottom: 9,
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(.75),
                                borderRadius: BorderRadius.circular(4)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 1),
                            child: Text(
                              _formatDuration(
                                  video.duration ?? const Duration()),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1
                                  ?.copyWith(fontSize: 11, color: Colors.white),
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SelectableText(
                    video.title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        ?.copyWith(fontSize: 15),
                    textAlign: TextAlign.start,
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (context) => StreamsList(video));
                    },
                  ),
                  const SizedBox(height: 5),
                  Text(
                    video.author,
                    style: Theme.of(context)
                        .textTheme
                        .subtitle1
                        ?.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _formatDuration(Duration d) {
  final totalSecs = d.inSeconds;
  final hours = totalSecs ~/ 3600;
  final minutes = (totalSecs % 3600) ~/ 60;
  final seconds = totalSecs % 60;
  final buffer = StringBuffer();

  if (hours > 0) {
    buffer.write('$hours:');
  }
  buffer.write('${minutes.toString().padLeft(2, '0')}:');
  buffer.write(seconds.toString().padLeft(2, '0'));
  return buffer.toString();
}
