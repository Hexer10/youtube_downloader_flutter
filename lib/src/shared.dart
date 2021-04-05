import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class Debouncer {
  final Duration duration;
  Timer? _timer;

  Debouncer({required this.duration});

  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(duration, action);
  }
}

AsyncSnapshot<T> useMemoFuture<T>(Future<T> Function() future,
    {required T initialData, required List<Object?> keys}) {
  final memo = useMemoized(future, keys);
  return useFuture(memo, initialData: initialData);
}
