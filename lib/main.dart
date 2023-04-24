//TestChange
import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/extensions.dart';
import 'screens/homescreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/beamerroutes.dart';

void main() async {
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  //pprint("Test");
  runApp(const MyApp());
}

final routerDelegate =
    BeamerDelegate(locationBuilder: RoutesLocationBuilder(routes: webroutes));

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routeInformationParser: BeamerParser(),
      routerDelegate: routerDelegate,
      title: 'RaveStreamRadio',
      theme:
          ThemeData(primarySwatch: MaterialColor(0xFF000000, cl.blackmaterial)),
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
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              return SafeArea(
                                  minimum:
                                      const EdgeInsets.fromLTRB(0, 15, 0, 0),
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
            }));
  }
}
