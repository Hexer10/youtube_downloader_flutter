import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_downloader/src/blocs/youtube/search_bloc.dart';

class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  SearchAppBar({Key key})
      : preferredSize = Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  final Size preferredSize; // default is 56.0

  @override
  _SearchAppBarState createState() => _SearchAppBarState();
}

class _SearchAppBarState extends State<SearchAppBar> {
  var _searching = false;
  FocusNode _focus = FocusNode();

  @override
  void initState() {
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        setState(() {
          _searching = false;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_searching) {
      return AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            setState(() {
              return _searching = false;
            });
          },
        ),
        title: TextField(
          onSubmitted: (val) {
            BlocProvider.of<SearchBloc>(context).add(SearchVideo(query: val));
          },
          focusNode: _focus,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Search video'),
        ),
      );
    } else {
      return AppBar(
        title: Text('YouTube search'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                return _searching = true;
              });
            },
          )
        ],
      );
    }
  }
}
