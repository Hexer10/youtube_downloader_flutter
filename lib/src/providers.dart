import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:youtube_downloader_flutter/src/models/download_manager.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'models/settings.dart';

final ytProvider = Provider<YoutubeExplode>((ref) => YoutubeExplode(),
    name: 'YT Explode provider');

final settingsProvider = StateProvider<Settings>(
    (ref) => const Settings(),
    name: 'Settings Provider');

final downloadProvider = StateProvider<DownloadManager>(
        (ref) => DownloadManager(),
    name: 'DownloadManager Provider');
