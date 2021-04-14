import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:youtube_downloader_flutter/src/widgets/downloads_view/downloads_page.dart';
import 'package:youtube_downloader_flutter/src/widgets/search_view/search_result.dart';

import 'widgets/search_view/suggestion_list.dart';

class SearchBar extends HookWidget {
  const SearchBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        elevation: 5,
        child: Container(
          padding: const EdgeInsets.only(left: 10),
          height: kToolbarHeight,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                }),
            Text(
              'Youtube Downloader',
              style: Theme.of(context).textTheme.headline5,
            ),
            Row(children: [
              IconButton(
                icon: const Icon(Icons.download_rounded),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const DownloadsPage()));
                },
              ),
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  showSearch(
                      context: context, delegate: CustomSearchDelegate());
                },
                icon: const Icon(
                  Icons.search,
                ),
              )
            ]),
          ]),
        ),
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return SearchResult(query: query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return SuggestionList(query, (value) {
      query = value;
      showResults(context);
    });
  }
}
