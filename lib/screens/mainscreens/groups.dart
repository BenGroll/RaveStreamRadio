// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/filesystem.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/screens/overviewpages/eventoverviewpage.dart';
import 'package:ravestreamradioapp/screens/overviewpages/groupoverviewpage.dart';
import 'package:ravestreamradioapp/screens/overviewpages/useroverviewpage.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;
import 'package:ravestreamradioapp/extensions.dart';
import 'package:ravestreamradioapp/chatting.dart';

enum QueryCategory { user, event, group }

class QueryEntry {
  final String id;
  final String name;
  final QueryCategory type;
  Icon? icon;
  QueryEntry({required this.id, required this.name, required this.type}) {
    if (type == QueryCategory.event) {
      icon = const Icon(
        Icons.local_activity,
        color: Colors.white,
      );
    }
    if (type == QueryCategory.group) {
      icon = const Icon(
        Icons.groups,
        color: Colors.white,
      );
    }
    if (type == QueryCategory.user) {
      icon = const Icon(
        Icons.perm_identity,
        color: Colors.white,
      );
    }
  }
}

class GroupsScreen extends StatefulWidget {
  ValueNotifier<List<Widget>> widgets = ValueNotifier([]);
  final dbc.User? loggedinas;
  GroupsScreen({super.key, required this.loggedinas});
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

List<Widget> groupListToListTiles(
    List<dbc.Group> list, BuildContext context, ValueNotifier to_Notify,
    [String? searchString]) {
  list = list.queryStringMatch(searchString ?? "");
  list = list.pinnedFirst;
  List<ListTile> outL = list
      .map((e) => ListTile(
            onTap: () {
              kIsWeb
                  ? Beamer.of(context).beamToNamed("/groups/${e.groupid}")
                  : Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          GroupOverviewPage(groupid: "${e.groupid}")));
            },
            onLongPress: () {
              if (currently_loggedin_as.value!.pinned_groups
                  .contains(db.db.doc("${branchPrefix}groups/${e.groupid}"))) {
                currently_loggedin_as.value!.pinned_groups
                    .remove(db.db.doc("${branchPrefix}groups/${e.groupid}"));
                db.db.doc(currently_loggedin_as.value!.path).update({
                  "pinned_groups": currently_loggedin_as.value!.pinned_groups
                });
                ScaffoldMessenger.of(context)
                    .showSnackBar(cw.hintSnackBar("Group pinned."));
                to_Notify.notifyListeners();
              } else {
                currently_loggedin_as.value!.pinned_groups
                    .add(db.db.doc("${branchPrefix}groups/${e.groupid}"));
                db.db.doc(currently_loggedin_as.value!.path).update({
                  "pinned_groups": currently_loggedin_as.value!.pinned_groups
                });
                ScaffoldMessenger.of(context)
                    .showSnackBar(cw.hintSnackBar("Group unpinned."));
                to_Notify.notifyListeners();
              }
            },
            title: Text(e.title ?? "@${e.groupid}",
                style: TextStyle(color: Colors.white)),
            leading: CircleAvatar(),
            trailing: db.hasGroupPinned(
                    e, currently_loggedin_as.value ?? dbc.demoUser)
                ? Icon(Icons.push_pin, color: Colors.white)
                : null,
          ))
      .toList();
  return outL;
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    ValueNotifier<String> searchString = ValueNotifier<String>("");
    return DefaultTabController(
      length: 2,
      child: Scaffold(
          appBar: AppBar(
              leading: cw.OpenSidebarButton(),
              elevation: 2,
              backgroundColor: cl.lighterGrey,
              title: Container(
                alignment: Alignment.center,
                margin: EdgeInsets.symmetric(horizontal: 8),
                padding: EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: cl.lighterGrey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          searchString.value = value;
                        },
                        decoration: InputDecoration(
                          hintText: "Search",
                          hintStyle: TextStyle(
                            color: Colors.white,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    //SvgPicture.asset("assets/icons/search.svg"),
                    Icon(Icons.search, color: Colors.white)
                  ],
                ),
              ),
              centerTitle: true,
              actions: [cw.OpenChatButton(context: context)],
              bottom: TabBar(
                tabs: [
                  Tab(text: "Groups"),
                  Tab(text: "Discover"),
                ],
              )),
          backgroundColor: cl.darkerGrey,
          drawer: cw.NavBar(),
          endDrawer: const ChatsDrawer(),
          body: TabBarView(
            children: [
              FutureBuilder(
                  future: db.queryGroups(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return ValueListenableBuilder(
                          valueListenable: searchString,
                          builder: (context, query, foo) {
                            ValueNotifier<List<Widget>> widgetlist =
                                ValueNotifier<List<Widget>>(
                                    groupListToListTiles(snapshot.data ?? [],
                                        context, searchString, query));
                            return RefreshIndicator(
                              onRefresh: () async {
                                widgetlist.value = groupListToListTiles(
                                    await db.queryGroups(),
                                    context,
                                    searchString,
                                    query);
                              },
                              child: ListView(
                                children: widgetlist.value.isEmpty
                                    ? [
                                        const Center(
                                            child: Text(
                                                "You haven't joined any groups yet",
                                                style: TextStyle(
                                                    color: Colors.white)))
                                      ]
                                    : widgetlist.value,
                              ),
                            );
                          });
                    } else {
                      return cw.LoadingIndicator(color: Colors.white);
                    }
                  }),

              /// Discover Page
              FutureBuilder(
                  future: db.getIndexedEntitys(),
                  builder: (context, AsyncSnapshot<List<Map>> snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return cw.LoadingIndicator(color: Colors.white);
                    } else {
                      List<QueryEntry> users = snapshot.data![1].entries
                          .map((e) => QueryEntry(
                              id: e.key,
                              name: e.value,
                              type: QueryCategory.user))
                          .toList();
                      List<QueryEntry> groups = snapshot.data![0].entries
                          .map((e) => QueryEntry(
                              id: e.key,
                              name: e.value,
                              type: QueryCategory.group))
                          .toList();
                      List<QueryEntry> events = snapshot.data![2].entries
                          .map((e) => QueryEntry(
                              id: e.key,
                              name: e.value,
                              type: QueryCategory.event))
                          .toList();
                      List<QueryEntry> data = users + groups + events;
                      return ValueListenableBuilder(
                          valueListenable: searchString,
                          builder: (context, string, foo) {
                            List<QueryEntry> shownEntrys = string.isEmpty
                                ? []
                                : data.matchesString(string);
                            return ListView(
                              children: string.isEmpty
                                  ? [
                                      const Center(
                                          child: Text(
                                              "Enter a search to see results",
                                              style: TextStyle(
                                                  color: Colors.white)))
                                    ]
                                  : shownEntrys
                                      .map((e) => ListTile(
                                            title: Text(e.name,
                                                style: const TextStyle(
                                                    color: Colors.white)),
                                            subtitle: Text(e.id,
                                                style: const TextStyle(
                                                    color: Colors.white)),
                                            trailing: e.icon,
                                            onTap: () {
                                              if (e.type ==
                                                  QueryCategory.event) {
                                                kIsWeb
                                                  ? Beamer.of(context).beamToNamed("/events/${e.id}")
                                                  : Navigator.of(context).push(MaterialPageRoute(
                                                      builder: (context) =>
                                                          EventOverviewPage(e.id)));
                                              } else if (e.type ==
                                                  QueryCategory.group) {
                                                kIsWeb
                                                  ? Beamer.of(context).beamToNamed("/groups/${e.id}")
                                                  : Navigator.of(context).push(MaterialPageRoute(
                                                      builder: (context) =>
                                                          GroupOverviewPage(groupid: e.id)));
                                              } else if (e.type ==
                                                  QueryCategory.user) {
                                                kIsWeb
                                                  ? Beamer.of(context).beamToNamed("/users/${e.id}@groups")
                                                  : Navigator.of(context).push(MaterialPageRoute(
                                                      builder: (context) => UserOverviewPage(username: e.id)));
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(cw
                                                        .hintSnackBar("Error"));
                                              }
                                            },
                                          ))
                                      .toList(),
                            );
                          });
                    }
                  })
            ],
          )),
    );
  }
}
