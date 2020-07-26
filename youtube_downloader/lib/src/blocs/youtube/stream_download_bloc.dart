import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_downloader/src/repositories/youtube_repository.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class StreamDownloadBloc
    extends Bloc<StreamDownloadEvent, StreamDownloadState> {
  final YoutubeRepository ytRepository;

  StreamDownloadBloc({@required this.ytRepository})
      : assert(ytRepository != null),
        super(StreamDownloadInitial());

  @override
  Stream<StreamDownloadState> mapEventToState(
    StreamDownloadEvent event,
  ) async* {
    if (event is StreamDownload) {
      try {
        var totalSize = event.streamInfo.size.totalBytes;
        var count = 0;
        yield StreamDownloadStart();
        await for (var data in ytRepository.ytClient.videos.streamsClient
            .get(event.streamInfo)) {
          count += data.length;
          print('${count} - ${totalSize} = ${count - totalSize}');
          var progress =
              num.parse(((count / totalSize) * 100).toStringAsFixed(2));
          yield StreamDownloadProgress(bytes: data, progress: progress);
        }
        yield StreamDownloadDone();
      } catch (e, s) {
        yield StreamDownloadFailure(e, s);
      }
    }
  }
}

/* Events */
abstract class StreamDownloadEvent extends Equatable {
  const StreamDownloadEvent();
}

class StreamDownload extends StreamDownloadEvent {
  final StreamInfo streamInfo;

  const StreamDownload({@required this.streamInfo})
      : assert(streamInfo != null);

  @override
  List<Object> get props => [streamInfo];
}

/* State */

abstract class StreamDownloadState extends Equatable {
  const StreamDownloadState();

  List<Object> get props => [];
}

class StreamDownloadInitial extends StreamDownloadState {
  const StreamDownloadInitial();
}

class StreamDownloadStart extends StreamDownloadState {
  const StreamDownloadStart();
}

class StreamDownloadProgress extends StreamDownloadState {
  final List<int> bytes;

  /// Progress in %
  final num progress;

  StreamDownloadProgress({@required this.bytes, @required this.progress});

  List<Object> get props => [bytes, progress];

  @override
  String toString() => 'StreamDownloadProgress($progress)';
}

class StreamDownloadDone extends StreamDownloadState {
  StreamDownloadDone();
}

class StreamDownloadFailure extends StreamDownloadState {
  final Object error;
  final StackTrace trace;

  StreamDownloadFailure(this.error, [this.trace]);

  List<Object> get props => [error, trace];
}
