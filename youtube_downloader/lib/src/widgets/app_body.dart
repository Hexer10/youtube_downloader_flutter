import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_downloader/src/blocs/youtube/search_bloc.dart';
import 'package:youtube_downloader/src/widgets/video_list.dart';

class AppBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (BuildContext context, state) {
        if (state is SearchInitial) {
          return Center(child: Text('Start searching!'));
        }
        if (state is SearchLoading) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is SearchSuccess) {
          return VideoListWidget(videos: state.videos);
        }
        if (state is SearchFailure) {
          return Center(child: Text('An error occurred'));
        }
        return Text('An error occurred, state: $state');
      },
    );
  }
}
