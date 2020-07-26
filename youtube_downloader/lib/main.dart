import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:open_file/open_file.dart';
import 'package:rxdart/subjects.dart';
import 'package:search_app_bar/search_app_bar.dart';
import 'package:youtube_downloader/simple_bloc_observer.dart';
import 'package:youtube_downloader/src/blocs/settings_bloc.dart';
import 'package:youtube_downloader/src/blocs/youtube/search_bloc.dart';
import 'package:youtube_downloader/src/blocs/youtube/stream_download_bloc.dart';
import 'package:youtube_downloader/src/blocs/youtube/video_streams_bloc.dart';
import 'package:youtube_downloader/src/widgets/app_body.dart';
import 'package:youtube_downloader/src/widgets/settings_page.dart';

import 'src/global.dart';

// Streams are created so that app can respond to notification-related events since the plugin is initialised in the `main` function
final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject =
    BehaviorSubject<ReceivedNotification>();

final BehaviorSubject<String> selectNotificationSubject =
    BehaviorSubject<String>();

class ReceivedNotification {
  final int id;
  final String title;
  final String body;
  final String payload;

  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });
}

NotificationAppLaunchDetails notificationAppLaunchDetails;

Future<void> main() async {
  Bloc.observer = SimpleBlocObserver();
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build();

  notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  // Note: permissions aren't requested here just to demonstrate that can be done later using the `requestPermissions()` method
  // of the `IOSFlutterLocalNotificationsPlugin` class
  var initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification:
          (int id, String title, String body, String payload) async {
        didReceiveLocalNotificationSubject.add(ReceivedNotification(
            id: id, title: title, body: body, payload: payload));
      });
  var initializationSettings = InitializationSettings(
      initializationSettingsAndroid, initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
    if (payload != null) {
      final data = json.decode(payload);
      if (data['progress'] == 100 && data['path'] != null) {
        OpenFile.open(data['path']);
      }
    }
    selectNotificationSubject.add(payload);
  });

  runApp(MultiBlocProvider(
    child: MyApp(),
    providers: [
      BlocProvider(create: (_) => SearchBloc(ytRepository: repo)),
      BlocProvider(create: (_) => VideoStreamsBloc(ytRepository: repo)),
      BlocProvider(create: (_) => StreamDownloadBloc(ytRepository: repo)),
      BlocProvider(create: (_) => SettingsBloc()),
    ],
  ));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Downloader',
      theme: ThemeData(
        appBarTheme: AppBarTheme(iconTheme: IconThemeData.fallback()),
        iconTheme: IconThemeData.fallback().copyWith(color: Colors.white),
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key key}) : super(key: key);

  static var snackKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: snackKey,
      appBar: SearchAppBar(
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
          iconTheme: IconThemeData.fallback().copyWith(color: Colors.white),
          title: Text('YouTube downloader'),
          searcher: BlocProvider.of<SearchBloc>(context)),
      body: AppBody(),
    );
  }
}
