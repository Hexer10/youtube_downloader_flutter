import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:youtube_downloader_flutter/src/providers.dart';
import 'package:youtube_downloader_flutter/src/widgets/streams_list.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class SearchResult extends HookWidget {
  final String query;

  const SearchResult({required this.query, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final yt = useProvider(ytProvider);

    final videoList = useState<List<Video>>([]);
    final currentPage = useState<SearchList?>(null);
    final scrollController = useScrollController();

    // Loading a new page.
    final loadingPage = useState<bool>(true);

    useEffect(() {
      if (currentPage.value != null) {
        videoList.value = [...videoList.value, ...?currentPage.value];
      }
    }, [currentPage.value]);
    useEffect(() {
      scrollController.addListener(() {
        if (scrollController.position.atEdge &&
            scrollController.position.pixels != 0) {
          loadingPage.value = true;
          currentPage.value!.nextPage().then((value) {
            loadingPage.value = false;
            return currentPage.value = value;
          });
        }
      });
      yt.search.getVideos(query).then((value) {
        loadingPage.value = false;
        return currentPage.value = value;
      });
    }, []);

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(top: 10),
      itemCount: videoList.value.length + (loadingPage.value ? 1 : 0),
      itemBuilder: (context, index) {
        if (loadingPage.value && index == videoList.value.length) {
          return Column(
            children: const  [
              SizedBox(height: 10),
              CircularProgressIndicator(),
            ],
          );
        }
        final video = videoList.value[index];
        return GestureDetector(
          onTap: () {
            showDialog(context: context, builder: (context) => StreamsList(video));
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
                        aspectRatio: 16 / 9.0,
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
                            padding:
                            const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            child: Text(
                              formatDuration(video.duration ?? const Duration()),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1
                                  ?.copyWith(fontSize: 11, color: Colors.white),
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(video.title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          ?.copyWith(fontSize: 15),
                      textAlign: TextAlign.start),
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

  static String formatDuration(Duration d) {
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
}
