import 'package:async/async.dart';
import 'package:bloc/bloc.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:search_app_bar/searcher.dart';
import 'package:youtube_downloader/src/repositories/youtube_repository.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState>
    implements Searcher<String> {
  final YoutubeRepository ytRepository;

  SearchBloc({@required this.ytRepository})
      : assert(ytRepository != null),
        super(SearchInitial()) {
    debouncer.values.listen(
      (search) {
        add(SearchVideo(query: search));
      },
    );
  }

  CancelableOperation<List<Video>> _currentOp;

  @override
  Stream<SearchState> mapEventToState(
    SearchEvent event,
  ) async* {
    if (event is SearchVideo) {
      _currentOp?.cancel();
      yield SearchLoading();
      try {
        _currentOp = CancelableOperation.fromFuture(
            ytRepository.ytClient.search.getVideosAsync(event.query).toList());
        var videos = await _currentOp.valueOrCancellation(null);
        if (videos != null) {
          yield SearchSuccess(videos: videos);
        }
      } catch (_) {
        yield SearchFailure();
      }
    }
    if (event is ResetSearch) {
      _currentOp?.cancel();
      yield SearchInitial();
    }
  }

  final debouncer = Debouncer<String>(Duration(milliseconds: 500));

  @override
  void Function(String) get onFiltering => (value) {
        if (value.isEmpty) {
          add(ResetSearch());
          return;
        }
        debouncer.value = value;
      };
}

/* Events */
abstract class SearchEvent extends Equatable {
  const SearchEvent();
}

class SearchVideo extends SearchEvent {
  final String query;

  const SearchVideo({@required this.query}) : assert(query != null);

  @override
  List<Object> get props => [query];
}

class ResetSearch extends SearchEvent {
  const ResetSearch();

  @override
  List<Object> get props => [];
}

/* State */
abstract class SearchState extends Equatable {
  const SearchState();

  List<Object> get props => [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {}

class SearchSuccess extends SearchState {
  final List<Video> videos;

  SearchSuccess({@required this.videos});

  List<Object> get props => [videos];
}

class SearchFailure extends SearchState {}
