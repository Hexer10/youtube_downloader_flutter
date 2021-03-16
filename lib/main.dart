import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_size/window_size.dart';

import 'src/models/settings.dart';
import 'src/providers.dart';
import 'src/widgets/home_page.dart';
import 'src/win32/dpi_awareness.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('Youtube Downloader');
    setWindowMinSize(const Size(600, 400));
    setWindowMaxSize(Size.infinite);
    if (Platform.isWindows) {
      SetProcessDpiAwareness(1);
    }
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      observers: [MainObserver()],
      child: SettingsManager(),
    );
  }
}

class MainObserver implements ProviderObserver {
  @override
  void didAddProvider(ProviderBase provider, Object? value) {
    print('Added: $provider : $value');
  }

  @override
  void didDisposeProvider(ProviderBase provider) {
    print('Disposed: $provider');
  }

  @override
  void didUpdateProvider(ProviderBase provider, Object? newValue) {
    print('Update: $provider : $newValue');
  }

  @override
  void mayHaveChanged(ProviderBase provider) {
    print('MayChange: $provider');
  }
}

class SettingsManager extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final fetched = useState<bool>(false);
    final settings = useProvider(settingsProvider);

    useEffect(() {
      SharedPreferences.getInstance().then((value) async {
        settings.state = await SettingsImpl.init(value);
        fetched.value = true;
      });
    }, []);

    if (!fetched.value) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Youtube Downloader',
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Youtube Downloader',
      theme: settings.state.theme.themeData,
      home: const HomePage(),
    );
  }
}
