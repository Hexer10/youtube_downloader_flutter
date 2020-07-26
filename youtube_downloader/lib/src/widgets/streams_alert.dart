import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_downloader/src/blocs/youtube/video_streams_bloc.dart';
import 'package:youtube_downloader/src/widgets/streams_list.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

class StreamsAlert extends StatefulWidget {
  final yt.Video video;

  StreamsAlert(this.video, {Key key}) : super(key: key);

  static const items = <DropdownMenuItem<String>>[
    DropdownMenuItem(value: 'all', child: Text('All')),
    DropdownMenuItem(value: 'muxed', child: Text('Video +  Audio')),
    DropdownMenuItem(value: 'video', child: Text('Video')),
    DropdownMenuItem(value: 'audio', child: Text('Audio')),
  ];

  @override
  _StreamsAlertState createState() => _StreamsAlertState();
}

class _StreamsAlertState extends State<StreamsAlert> {
  @override
  void initState() {
    BlocProvider.of<VideoStreamsBloc>(context)
        .add(VideoStreamsQuery(format: 'all', video: widget.video));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoStreamsBloc, VideoStreamsState>(
        builder: (context, state) {
      print('State: $state');
      if (state is VideoStreamsInitial) {
        return _getDialog(context, 'all', loading: true);
      }
      if (state is VideoStreamsLoading) {
        return _getDialog(context, state.format, loading: true);
      }
      if (state is VideoStreamsSuccess) {
        return _getDialog(context, state.format, streams: state.streams);
      }
      if (state is VideoStreamsFailure) {
        if (state.error is yt.VideoUnplayableException) {
          return _getDialog(context, state.format,
              error: true,
              errorMsg:
                  'This video is not playable!\nMost likely it is a livestream, '
                  'wait for it to finish!');
        }
        return _getDialog(context, state.format,
            error: true,
            errorMsg: 'Unknown error please report this to the GitHub Repo:'
                '${state.error}\n\n${state.trace}');
      }
      return _getDialog(context, 'all',
          error: true, errorMsg: 'Unknown; State: $state\nContext: $context');
    });
  }

  _getDialog(BuildContext context, String format,
      {Iterable<yt.StreamInfo> streams,
      bool loading = false,
      bool error = false,
      String errorMsg = ''}) {
    return AlertDialog(
      title: Text('${widget.video.title}', overflow: TextOverflow.ellipsis, maxLines: 1, softWrap: false,),
      content: Container(
          width: double.maxFinite,
          height: double.maxFinite,
          child: error
              ? Text(errorMsg, textAlign: TextAlign.center)
              : loading
                  ? SizedBox(
                      child: Column(
                      children: <Widget>[
                        CircularProgressIndicator(),
                      ],
                    ))
                  : StreamsList(streams, widget.video)),
      actions: <Widget>[
        DropdownButton(
          value: format,
          onChanged: (value) {
            BlocProvider.of<VideoStreamsBloc>(context)
                .add(VideoStreamsQuery(format: value, video: widget.video));
            print(value);
          },
          items: StreamsAlert.items,
        )
      ],
    );
  }
}
