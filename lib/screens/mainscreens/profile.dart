import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/screens/devsettingsscreen.dart';
import 'package:ravestreamradioapp/screens/homescreen.dart' as home;
import 'package:ravestreamradioapp/screens/loginscreen.dart';
import 'package:ravestreamradioapp/filesystem.dart' as files;
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;
import 'package:ravestreamradioapp/extensions.dart';


class ProfileScreen extends StatefulWidget {
  final dbc.User? loggedinas;
  const ProfileScreen({super.key, required this.loggedinas});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return widget.loggedinas == null
        ? NotLoggedInScaffold()
        : LoggedInScaffold(loggedinas: widget.loggedinas ?? dbc.demoUser);
  }
}

class NotLoggedInScaffold extends StatelessWidget {
  const NotLoggedInScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cl.lighterGrey,
      body: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 20.0,
            horizontal: 10.0,
          ),
          child: Center(
            child: ElevatedButton(
              child: const Text("Login"),
              onPressed: () {
                //Navigate to Login Screen
                kIsWeb
                ? Beamer.of(context).beamToNamed("/login")
                : Navigator.of(context).push(
                    MaterialPageRoute(builder: ((context) => LoginScreen())));
              },
            ),
          )),
    );
  }
}

class LoggedInScaffold extends StatelessWidget {
  final dbc.User loggedinas;
  const LoggedInScaffold({super.key, required this.loggedinas});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cl.lighterGrey,
      body : selectedbranch.value == ServerBranches.develop
      ? DevSettingsScreen()
      : Container()
    );
  }
}
