import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/screens/devsettingsscreen.dart';
import 'package:ravestreamradioapp/screens/homescreen.dart' as home;
import 'package:ravestreamradioapp/screens/loginscreen.dart';
import 'package:ravestreamradioapp/filesystem.dart' as files;
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/screens/overviewpages/useroverviewpage.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;
import 'package:ravestreamradioapp/extensions.dart';

import '../../commonwidgets.dart';
import '../../conv.dart';

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
                    : Navigator.of(context).push(MaterialPageRoute(
                        builder: ((context) => LoginScreen())));
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
        backgroundColor: cl.darkerGrey,
        body: UserView(
          username: currently_loggedin_as.value!.username,
        ));
  }
}

class UserView extends StatelessWidget {
  String username;
  UserView({super.key, required this.username});

  Future<dbc.User?> _getUser() async {
    if (currently_loggedin_as.value != null) {
      if (currently_loggedin_as.value!.username == username) {
        return currently_loggedin_as.value;
      }
    }
    return await db.getUser(username);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return cw.LoadingIndicator(color: Colors.white);
          }
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data == null) {
            return Scaffold(
                backgroundColor: cl.darkerGrey,
                body: Center(
                    child: Text("Couldn't load user $username",
                        style: TextStyle(color: Colors.white))));
          }
          ValueNotifier<dbc.User> user =
              ValueNotifier<dbc.User>(snapshot.data ?? dbc.demoUser);
          bool userIsMyself = currently_loggedin_as.value != null &&
              user.value.username == currently_loggedin_as.value!.username;
          return Scaffold(
              backgroundColor: cl.darkerGrey,
              body: SingleChildScrollView(
                  child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Center(
                              child: Container(
                                width: 150,
                                child: const CircleAvatar(
                                  radius: 70,
                                  /*backgroundImage: SvgPicture(pictureProvider),*/
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: cl.lighterGrey,
                                    width: 5.0,
                                  ),
                                ),
                              ),
                            ),
                            // Avatar Editor Icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                if (userIsMyself)
                                  IconButton(
                                      onPressed: () {},
                                      icon: Icon(
                                        Icons.edit,
                                        color: cl.darkerGrey,
                                      )),
                                ValueListenableBuilder(
                                    valueListenable: user,
                                    builder: (context, userVal, foo) {
                                      return Text(
                                          (userVal.alias == null ||
                                                  userVal.alias!.isEmpty)
                                              ? "No Alias created."
                                              : userVal.alias ??
                                                  "No Alias created.",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  20));
                                    }),
                                if (userIsMyself)
                                  IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                      ),
                                      onPressed: () async {
                                        ValueNotifier<String?> aliasNot =
                                            ValueNotifier<String?>(
                                                user.value.alias);
                                        await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return cw.SimpleStringEditDialog(
                                                  to_notify: aliasNot);
                                            });

                                        if (aliasNot.value != null &&
                                            aliasNot.value !=
                                                user.value.alias) {
                                          user.value.alias = aliasNot.value;
                                          await db.db
                                              .doc(
                                                  "${branchPrefix}users/${user.value.username}")
                                              .update(
                                                  {"alias": user.value.alias});
                                          await db
                                              .addUserToIndexFile(user.value);
                                          user.notifyListeners();
                                        }
                                      }),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                if (userIsMyself)
                                  IconButton(
                                      onPressed: () {},
                                      icon: Icon(
                                        Icons.edit,
                                        color: cl.darkerGrey,
                                      )),
                                ValueListenableBuilder(
                                    valueListenable: user,
                                    builder: (context, userVal, foo) {
                                      return Text(
                                          (userVal.description == null ||
                                                  userVal.description!.isEmpty)
                                              ? "No description yet."
                                              : userVal.description ??
                                                  "No description yet.",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  25));
                                    }),
                                if (userIsMyself)
                                  IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                      ),
                                      onPressed: () async {
                                        ValueNotifier<String?> descriptionNot =
                                            ValueNotifier<String?>(
                                                user.value.description);
                                        await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return cw.SimpleStringEditDialog(
                                                  to_notify: descriptionNot);
                                            });

                                        if (descriptionNot.value != null &&
                                            descriptionNot.value !=
                                                user.value.alias) {
                                          user.value.description =
                                              descriptionNot.value;
                                          await db.db
                                              .doc(
                                                  "${branchPrefix}users/${user.value.username}")
                                              .update({
                                            "description":
                                                user.value.description
                                          });
                                          await db
                                              .addUserToIndexFile(user.value);
                                          user.notifyListeners();
                                        }
                                      }),
                              ],
                            ),
                            Text(
                                    "Hosted events: ${user.value.events.length}",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                25)),
                                                 ListView(
                                                  
                                            children: db.queriefyEventList(events, filters)
                                                .map(
                                                    (e) => hostedEventCard(e))
                                                    .toList()
                                                ,),
                          ]))));
        });
  }
}
