import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:youtube_downloader_flutter/src/shared.dart';

import '../../providers.dart';

class SuggestionList extends HookConsumerWidget {
  final String query;
  final void Function(String) callback;

  const SuggestionList(this.query, this.callback);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yt = ref.watch(ytProvider);
    final debQuery = useDebounce(query, const Duration(milliseconds: 200));

    final suggestions = useMemoFuture(
        () => yt.search.getQuerySuggestions(query),
        initialData: const <String>[],
        keys: [debQuery]);

    return ListView.builder(
      itemCount: suggestions.data!.length,
      itemBuilder: (context, index) {
        final result = suggestions.data![index];
        return MaterialButton(
          onPressed: () {
            callback(result);
          },
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: 10,
            leading: const Icon(Icons.search),
            title: Text(result),
          ),
        );
      },
    );
  }
}
