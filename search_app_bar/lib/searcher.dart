import 'dart:core';

abstract class Searcher<T> {
  void Function(String) get onFiltering;
}
