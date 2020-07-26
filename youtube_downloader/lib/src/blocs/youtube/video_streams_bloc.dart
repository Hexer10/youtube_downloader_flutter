import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_downloader/src/repositories/youtube_repository.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoStreamsBloc extends Bloc<VideoStreamsEvent, VideoStreamsState> {
  final YoutubeRepository ytRepository;

  VideoStreamsBloc({@required this.ytRepository})
      : assert(ytRepository != null),
        super(VideoStreamsInitial());

  @override
  Stream<VideoStreamsState> mapEventToState(
    VideoStreamsEvent event,
  ) async* {
    if (event is VideoStreamsQuery) {
      yield VideoStreamsLoading(format: event.format);
      try {
        var manifest = await ytRepository.ytClient.videos.streamsClient
            .getManifest(
                event.video.id); //await _streamsCache[event.video.id]();
        var streams = manifest.streams;
        if (event.format == 'muxed') {
          yield VideoStreamsSuccess(
              streams: streams.whereType<MuxedStreamInfo>(), format: 'muxed');
        } else if (event.format == 'audio') {
          yield VideoStreamsSuccess(
              streams: streams.whereType<AudioOnlyStreamInfo>(),
              format: 'audio');
        } else if (event.format == 'video') {
          yield VideoStreamsSuccess(
              streams: streams.whereType<VideoOnlyStreamInfo>(),
              format: 'video');
        } else {
          yield VideoStreamsSuccess(streams: streams, format: 'all');
        }
      } catch (e, s) {
        yield VideoStreamsFailure(event.format, e, s);
      }
    }
  }
}

/* Events */
abstract class VideoStreamsEvent extends Equatable {
  const VideoStreamsEvent();
}

class VideoStreamsQuery extends VideoStreamsEvent {
  final Video video;
  final String format;

  const VideoStreamsQuery({@required this.video, @required this.format})
      : assert(video != null),
        assert(format != null);

  @override
  List<Object> get props => [video, format];
}

/* State */

abstract class VideoStreamsState extends Equatable {
  const VideoStreamsState();

  List<Object> get props => [];
}

class VideoStreamsInitial extends VideoStreamsState {
  const VideoStreamsInitial();
}

class VideoStreamsLoading extends VideoStreamsState {
  final String format;

  VideoStreamsLoading({@required this.format});

  List<Object> get props => [format];
}

class VideoStreamsSuccess extends VideoStreamsState {
  final Iterable<StreamInfo> streams;
  final String format;

  VideoStreamsSuccess({@required this.streams, @required this.format});

  List<Object> get props => [streams, format];
}

class VideoStreamsFailure extends VideoStreamsState {
  final String format;
  final Object error;
  final StackTrace trace;

  VideoStreamsFailure(this.format, this.error, [this.trace]);

  List<Object> get props => [format, error, trace];
}
