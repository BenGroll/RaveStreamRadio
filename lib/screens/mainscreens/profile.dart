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
      drawer: const cw.NavBar(),
      backgroundColor: cl.nearly_black,
      appBar: AppBar(
        leading: const cw.OpenSidebarButton(),
        title: const Text("Not logged in."),
        centerTitle: true,
      ),
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
      drawer: const cw.NavBar(),
      backgroundColor: cl.nearly_black,
      appBar: AppBar(
        leading: const cw.OpenSidebarButton(),
        title: Text(loggedinas.username),
        actions: [
          IconButton(
              onPressed: () async {
                kIsWeb
                ? await files.writeLoginDataWeb("", "")
                : await files.writeLoginDataMobile("", "");
                currently_loggedin_as.value = await db.doStartupLoginDataCheck();
              },
              icon: Icon(Icons.logout))
        ],
      ),
      body : selectedbranch.value == ServerBranches.develop
      ? DevSettingsScreen()
      : Container()
    );
  }
}
