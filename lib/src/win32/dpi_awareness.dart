// ignore_for_file: constant_identifier_names, non_constant_identifier_names
import 'dart:ffi';

const DPI_AWARENESS_INVALID = -1;
const DPI_AWARENESS_UNAWARE = 0;
const DPI_AWARENESS_SYSTEM_AWARE = 1;
const DPI_AWARENESS_PER_MONITOR_AWARE = 2;

final user32 = DynamicLibrary.open('user32.dll');
final shcore = DynamicLibrary.open('Shcore.dll');

typedef SetProcessDpiAwarenessContextC = Int8 Function(Int16);
typedef SetProcessDpiAwarenessContextDart = int Function(int);

bool SetProcessDpiAwarenessContext(int context) {
  final SetProcessDpiAwarenessContextDart func = user32
      .lookup<NativeFunction<SetProcessDpiAwarenessContextC>>(
          'SetProcessDpiAwarenessContext')
      .asFunction();

  return func(context) == 1;
}

typedef SetProcessDpiAwarenessC = Int8 Function(Int16);
typedef SetProcessDpiAwarenessDart = int Function(int);

bool SetProcessDpiAwareness(int context) {
  final SetProcessDpiAwarenessDart func = shcore
      .lookup<NativeFunction<SetProcessDpiAwarenessC>>(
      'SetProcessDpiAwareness')
      .asFunction();

  return func(context) == 1;
}
