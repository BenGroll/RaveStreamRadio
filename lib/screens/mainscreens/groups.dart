import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/filesystem.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/screens/overviewpages/groupoverviewpage.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;

class GroupsScreen extends StatefulWidget {
  final dbc.User? loggedinas;
  const GroupsScreen({super.key, required this.loggedinas});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

TabBar tabbar = const TabBar(
            tabs: [
              Tab(text: "Groups"),
              Tab(text: "Chats")
            ],
          );

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const cw.NavBar(),
        backgroundColor: cl.nearly_black,
        appBar: AppBar(
          leading: const cw.OpenSidebarButton(),
          elevation: 8,
          backgroundColor: cl.deep_black,
          title: PreferredSize(
            preferredSize: tabbar.preferredSize,
            child: tabbar
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(0),
          child: FutureBuilder(
              future: buildGroupTiles(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return ListView(
                    children: snapshot.data ?? [Text("Something went wrong")],
                  );
                } else {
                  return Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }
              }),
        ),
      ),
    );
  }
}

Future<List<Widget>> buildGroupTiles() async {
  if (currently_loggedin_as.value == null) {
    return [Text("Has to be logged in to view Groups")];
  }
  List<dbc.Group> groups =
      await db.showJoinedGroupsForUser(currently_loggedin_as.value!.username);

  List<Widget> tiles = [];
  groups.forEach((element) {
    if (db.hasGroupPinned(
        element, currently_loggedin_as.value ?? dbc.demoUser)) {
      tiles.add(GroupEntry(group: element));
    }
  });
  groups.forEach((element) {
    if (!db.hasGroupPinned(
        element, currently_loggedin_as.value ?? dbc.demoUser)) {
      tiles.add(GroupEntry(group: element));
    }
  });

  return tiles;
}

class GroupEntry extends StatelessWidget {
  final dbc.Group group;
  const GroupEntry({required this.group});
  @override
  Widget build(BuildContext context) {
    bool is_pinned =
        db.hasGroupPinned(group, currently_loggedin_as.value ?? dbc.demoUser);
    return ListTile(
      onTap: () {
        kIsWeb
            ? Beamer.of(context).beamToNamed("/groups/${group.groupid}")
            : Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    GroupOverviewPage(groupid: group.groupid)));
      },
      leading: CircleAvatar(
        foregroundImage: Image(
                image: AssetImage("graphics/ravestreamlogo_white_on_trans.png"))
            .image,
      ),
      title: Text(group.title ?? group.groupid,
          style: TextStyle(color: Colors.white)),
      subtitle: Text(
        "Members: ${group.members_roles?.length ?? 0}",
        style: TextStyle(color: Colors.white),
      ),
      trailing: AspectRatio(
          aspectRatio: 1,
          child: is_pinned
              ? Icon(
                  Icons.push_pin,
                  color: Color.fromARGB(255, 220, 220, 220),
                )
              : Container()),
      tileColor: cl.deep_black,
    );
  }
}
