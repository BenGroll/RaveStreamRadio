// ignore_for_file: prefer_const_constructors

import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'colors.dart' as cl;
import 'package:ravestreamradioapp/pres/rave_stream_icons_icons.dart'
    show RaveStreamIcons;
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'shared_state.dart';
import 'filesystem.dart' as files;
import 'database.dart' as db;
import 'databaseclasses.dart' as dbc;
import 'package:auto_size_text/auto_size_text.dart';

/// Custom Snackbar used to notify User
/// Fixed to the bottom of scaffold body
SnackBar hintSnackBar(String alertMessage) {
  return SnackBar(
      backgroundColor: cl.deep_black,
      behavior: SnackBarBehavior.fixed,
      content: Text(alertMessage));
}

final CalendarAppBar = AppBar(
    leading: const OpenSidebarButton(),
    actions: [IconButton(onPressed: () {}, icon: Icon(Icons.filter_alt))],
    title: const Text("Events"),
    centerTitle: true);

final FavouritesAppBar = AppBar(
  leading: const OpenSidebarButton(),
  backgroundColor: cl.deep_black,
  title: const Text("Favourites"),
  centerTitle: true,
);

TabBar tabbar = TabBar(
  tabs: [Tab(text: "Groups"), Tab(text: "Chats")],
);

final GroupsAppBar = (AppBar(
  leading: const OpenSidebarButton(),
  elevation: 8,
  backgroundColor: cl.deep_black,
  title: DefaultTabController(
      length: 2,
      child: PreferredSize(preferredSize: tabbar.preferredSize, child: tabbar)),
  centerTitle: true,
));

AppBar ProfileAppBar(dbc.User? user) {
  return user == null
      ? AppBar(
          leading: const OpenSidebarButton(),
          title: const Text("Not logged in."),
          centerTitle: true,
        )
      : AppBar(
          leading: const OpenSidebarButton(),
          title: Text(user.username),
          actions: [
            IconButton(
                onPressed: () async {
                  kIsWeb
                      ? await files.writeLoginDataWeb("", "")
                      : await files.writeLoginDataMobile("", "");
                  currently_loggedin_as.value =
                      await db.doStartupLoginDataCheck();
                },
                icon: Icon(Icons.logout))
          ],
        );
}

/// Custom Builder to support waiting for image data.
/// Returns CircularProgressIndicator until image is loaded
class FutureImageBuilder extends StatelessWidget {
  final Future<Widget> futureImage;
  const FutureImageBuilder({required this.futureImage});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: futureImage,
        builder: ((context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return snapshot.data as Widget;
          } else {
            return const CircularProgressIndicator(color: Colors.white);
          }
        }));
  }
}

class OpenSidebarButton extends StatelessWidget {
  const OpenSidebarButton({super.key});
  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
        child: Image(
            image: AssetImage("graphics/ravestreamlogo_white_on_trans.png")));
  }
}

class NavBar extends StatelessWidget {
  const NavBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: cl.nearly_black,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        // ignore: prefer_const_literals_to_create_immutables
        children: [
          ListTile(
            onTap: () {
              Beamer.of(context).beamToNamed("/social");
            },
            title: Text("About Us(DE)",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.height / 40)),
          ),
          ListTile(
            onTap: () {
              Beamer.of(context).beamToNamed("/imprint");
            },
            title: Text("Imprint(DE)",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.height / 40)),
          ),
          ListTile(
            onTap: () {
              Beamer.of(context).beamToNamed("/policy");
            },
            title: Text("Privacy Policy(DE)",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.height / 40)),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "© RaveStreamRadio 2023",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String errormessage;
  final int? errorcode;
  final List<Widget>? actions;
  const ErrorScreen(
      {super.key,
      this.errormessage = "Unknown Error occured",
      this.errorcode,
      this.actions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cl.deep_black,
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(errormessage, style: TextStyle(color: Colors.white)),
            Text("ErrorCode: ${errorcode ?? -1}",
                style: TextStyle(color: Colors.white))
          ]),
    );
    ;
  }
}
