import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../providers.dart';
import '../../shared.dart';

class SuggestionList extends HookWidget {
  static final deb = Debouncer(duration: const Duration(milliseconds: 200));

  final String query;
  final void Function(String) callback;

  const SuggestionList(this.query, this.callback);

  @override
  Widget build(BuildContext context) {
    final controller = useStreamController<String>();
    final isMounted = useIsMounted();

    useEffect(() {
      //TODO: Find out why debouncing with `stream.debounce(...)` always returns an empty string (the default value).
      deb.run(() {
        if (isMounted()) {
          controller.add(query);
        }
      });
    }, [query]);

    final yt = useProvider(ytProvider);
    final stream = useStream(controller.stream, initialData: '');

    final suggestions = useMemoFuture(
        () => stream.data!.isEmpty
            ? Future.value(const <String>[])
            : yt.search.getQuerySuggestions(stream.data!),
        initialData: const <String>[],
        keys: [stream.data!]);

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
