import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

AsyncSnapshot<T> useMemoFuture<T>(Future<T> Function() future,
    {required T initialData, required List<Object?> keys}) {
  final memo = useMemoized(future, keys);
  return useFuture(memo, initialData: initialData);
}

/// From https://usehooks.com/useDebounce/
T useDebounce<T>(T value, Duration delay) {
  final debouncedValue = useState(value);

  useEffect(() {
    final handler = Timer(delay, () => debouncedValue.value = value);
    return () => handler.cancel();
  }, [value, delay]);
  return debouncedValue.value;
}
