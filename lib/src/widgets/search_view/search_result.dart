import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:youtube_downloader_flutter/src/services/search_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../providers.dart';
import 'streams_list.dart';

class SearchResult extends HookWidget {
  late final searchProvider = StateProvider.autoDispose(
      (ref) => SearchService(ref.read(ytProvider), query));
  final String query;

  SearchResult({required this.query, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final service = useProvider(searchProvider).state;
    useListenable(service);


    if (size.width >= 560) {
      return LandscapeSearch(query: query, service: service);
    }
    return PortraitSearch(query: query, service: service);
  }
}

class LandscapeSearch extends StatelessWidget {
  final String query;
  final SearchService service;


  const LandscapeSearch({required this.query, required this.service, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final videos = service.videos;
    final loading = service.loading;

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: videos.length + (loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (loading && index == videos.length) {
          return Column(
            children: const [
              SizedBox(height: 10),
              CircularProgressIndicator(),
            ],
          );
        }
        final video = videos[index];
        if (index > 1 && index == videos.length - 1 && !loading) {
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
                            video.thumbnail,
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
                                    video.duration),
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
                        child: AutoSizeText(
                            '${AppLocalizations.of(context)!.author}: ${video.author}',
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

class PortraitSearch extends StatelessWidget {
  final String query;
  final SearchService service;

  const PortraitSearch({required this.query, required this.service, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final videos = service.videos;
    final loading = service.loading;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: videos.length + (loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (service.loading && index == videos.length) {
          return Column(
            children: const [
              SizedBox(height: 10),
              CircularProgressIndicator(),
            ],
          );
        }
        final video = videos[index];
        if (index > 1 && index == videos.length - 1 && !loading) {
          Future.microtask(service.nextPage);
        }
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
                          video.thumbnail,
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
                                  video.duration),
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
