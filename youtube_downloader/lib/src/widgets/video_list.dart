import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Container;

import 'streams_alert.dart';

class VideoListWidget extends StatelessWidget {
  final List<Video> videos;

  VideoListWidget({Key key, @required this.videos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return ListTile(
            onTap: () {
              showDialog(context: context, child: StreamsAlert(video));
            },
            leading: Image.network(
              video.thumbnails.highResUrl,
            ),
            title: Text(video.title));
      },
      itemExtent: 70,
    );
  }
}
