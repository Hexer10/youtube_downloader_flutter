import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:search_app_bar/searcher.dart';

class SearchBloc<T> extends BlocBase {
  final Searcher searcher;
  //Filter<T> filter;

  final _isInSearchMode = BehaviorSubject<bool>();
  final _searchQuery = BehaviorSubject<String>();

  ///
  /// Inputs
  ///
  get onSearchQueryChanged => _searchQuery.add;

  get setSearchMode => _isInSearchMode.add;

  Function get onClearSearchQuery => () => onSearchQueryChanged('');

  ///
  /// Outputs
  ///
  Stream<bool> get isInSearchMode => _isInSearchMode.stream;

  Stream<String> get searchQuery => _searchQuery.stream;

  ///
  /// Constructor
  ///
  SearchBloc({
    @required this.searcher,
  }) {
    searchQuery.listen(searcher.onFiltering);
  }

  @override
  void dispose() {
    _isInSearchMode.close();
    _searchQuery.close();
    super.dispose();
  }
}
