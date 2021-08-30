import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win32/win32.dart';
import 'package:window_size/window_size.dart';
import 'package:youtube_downloader_flutter/src/models/download_manager.dart';

import 'src/models/settings.dart';
import 'src/providers.dart';
import 'src/widgets/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('Youtube Downloader');
    setWindowMinSize(const Size(600, 800));
    setWindowMaxSize(Size.infinite);
    if (Platform.isWindows) {
      SetProcessDpiAwareness(1);
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      observers: [MainObserver()],
      child: const AppInit(),
    );
  }
}

class MainObserver implements ProviderObserver {
  @override
  void didAddProvider(
      ProviderBase provider, Object? value, ProviderContainer container) {
    debugPrint('Added: $provider : $value(${value.runtimeType})');
  }

  @override
  void didDisposeProvider(ProviderBase provider, ProviderContainer container) {
    debugPrint('Disposed: $provider');
  }

  @override
  void didUpdateProvider(ProviderBase provider, Object? previousValue,
      Object? newValue, ProviderContainer container) {
    debugPrint('Update: $provider : $newValue');
  }
}

class AppInit extends HookConsumerWidget {
  static final scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  const AppInit({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fetched = useState<bool>(false);
    final settings = ref.watch(settingsProvider);
    final downloadManager = ref.watch(downloadProvider);

    useEffect(() {
      SharedPreferences.getInstance().then((value) async {
        downloadManager.state = DownloadManagerImpl.init(value);
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

    // TODO: Might be worth finding another way to achieve this
    return MaterialApp(
      scaffoldMessengerKey: scaffoldKey,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: settings.state.locale,
      title: 'Youtube Downloader',
      theme: settings.state.theme.themeData,
    );
  }
}
