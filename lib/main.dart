//TestChange
import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ravestreamradioapp/extensions.dart';
import 'package:ravestreamradioapp/messaging.dart';
import 'screens/homescreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/beamerroutes.dart';
import 'package:ravestreamradioapp/shared_state.dart' as shs;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> handleBackgroundMessage(RemoteMessage? message) async {
  print(message?.toMap());
}

void main() async {
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: Duration(minutes: 5),
      minimumFetchInterval: Duration(minutes: 5)));
  await MessagingAPI().registerApp();
  /*await remoteConfig.setDefaults(const {
    "DEFAULT_MINAGE": 18,
    "DISABLE_CHATWINDOW": false,
    "DISABLE_EVENT_EDITING": false,
    "DISABLE_GROUP_CREATION": false,
    "DISABLE_MESSAGE_SENDING": false,
    "SHOW_FEEDS": false,
    "POLICY": ""
});*/

  //pprint("Test");
  await db.getRemoteConfig();
  runApp(const MyApp());
}

final routerDelegate =
    BeamerDelegate(locationBuilder: RoutesLocationBuilder(routes: webroutes));

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    return MaterialApp.router(
      routeInformationParser: BeamerParser(),
      routerDelegate: routerDelegate,
      title: 'Rave Calendar',
      theme: ThemeData(
          primarySwatch: MaterialColor(0xFF000000, cl.blackmaterial),
          scrollbarTheme: ScrollbarThemeData(
              thumbVisibility: MaterialStateProperty.all<bool>(true))),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// InitialRoute
class MainRoute extends StatelessWidget {
  final Screens startingscreen;
  const MainRoute({this.startingscreen = Screens.events});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: ValueListenableBuilder(
      valueListenable: selectedbranch,
      builder: (context, snapshot, foo) {
        return FutureBuilder(
            future: Firebase.initializeApp(
                options: DefaultFirebaseOptions.currentPlatform),
            builder: (BuildContext context, AsyncSnapshot snap) {
              if (snap.connectionState == ConnectionState.done) {
                return FutureBuilder(
                    future: db.doStartupLoginDataCheck(),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return SafeArea(
                            minimum: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                            child: HomeScreen(
                                loggedinas: snapshot.data,
                                startingscreen: startingscreen));
                      } else {
                        return Container(color: Colors.transparent);
                      }
                    });
              } else {
                return const SpinKitRotatingCircle(
                    color: Colors.white, size: 50.0);
              }
            });
      },
    ));
  }
}
