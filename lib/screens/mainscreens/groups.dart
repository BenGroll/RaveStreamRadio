import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/filesystem.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/screens/chats.dart';
import 'package:ravestreamradioapp/screens/overviewpages/groupoverviewpage.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;


class GroupsScreen extends StatefulWidget {
  ValueNotifier<List<Widget>> widgets = ValueNotifier([]);
  final dbc.User? loggedinas;
  GroupsScreen({super.key, required this.loggedinas});
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: cl.darkerGrey,
        body: Padding(
          padding: const EdgeInsets.all(0),
          child: GroupListBuilder(parent: widget)
        ),
        endDrawer: const ChatsDrawer(),
    );
  }
}

class GroupListBuilder extends StatelessWidget {
  GroupsScreen parent;
  GroupListBuilder({super.key, required this.parent});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
            onRefresh: () async {
              parent.widgets.value = await buildGroupTiles();
            },
            child: FutureBuilder(
                future: buildGroupTiles(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    parent.widgets.value = snapshot.data ??
                        [
                          Text(
                            "No Groups joined yet.",
                            style: TextStyle(color: Colors.white),
                          )
                        ];
                    return ValueListenableBuilder(
                        valueListenable: parent.widgets,
                        builder: (context, widgetlist, foo) {
                          return ListView(
                            children: widgetlist,
                          );
                        });
                  } else {
                    return const Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }
                }),
          );
  }
}


Future<List<Widget>> buildGroupTiles() async {
  if (currently_loggedin_as.value == null) {
    return [Text("Has to be logged in to view Groups")];
  }
  List<dbc.Group> groups =
      await db.showJoinedGroupsForUser(currently_loggedin_as.value!.username);
  if (groups.isEmpty)
    return [
      Text(
        "You haven't joined any groups yet.",
        style: TextStyle(color: Colors.white),
      )
    ];
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
      tileColor: cl.darkerGrey,
    );
  }
}


Future<List<Widget>> buildChatTiles() async {
  if (currently_loggedin_as.value == null) {
    return [Text("Has to be logged in to view Chats")];
  }
  List<dbc.Group> groups =
      await db.showJoinedGroupsForUser(currently_loggedin_as.value!.username);
  if (groups.isEmpty)
    return [
      Text(
        "You haven't joined any groups yet.",
        style: TextStyle(color: Colors.white),
      )
    ];
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