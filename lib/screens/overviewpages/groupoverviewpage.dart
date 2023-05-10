import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ravestreamradioapp/commonwidgets.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/extensions.dart';
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;

class GroupOverviewPage extends StatelessWidget {
  final String groupid;
  dbc.Group? group;
  GroupOverviewPage({super.key, required this.groupid});

  @override
  Widget build(BuildContext context) {
    bool is_founder = false;
    return SafeArea(
        minimum: EdgeInsets.fromLTRB(
            0, MediaQuery.of(context).size.height / 50, 0, 0),
        child: FutureBuilder(
          future: db.getGroup(groupid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              ValueNotifier<dbc.Group?> groupNotifier =
                  ValueNotifier<dbc.Group?>(snapshot.data);
              return ValueListenableBuilder(
                  valueListenable: groupNotifier,
                  builder: (context, group, foo) {
                    return Scaffold(
                        backgroundColor: cl.darkerGrey,
                        appBar: AppBar(
                          backgroundColor: cl.lighterGrey,
                          centerTitle: true,
                          title: GestureDetector(
                            onLongPress: () {
                              if (group != null) {
                                Clipboard.setData(
                                    ClipboardData(text: group.groupid));
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text("Copied ID to clipboard")));
                              }
                            },
                            child: Text(
                                "Group: ${group?.groupid ?? 'Not Loadable'}"),
                          ),
                          actions: [
                            ReportButton(
                                target: "${branchPrefix}groups/$groupid")
                          ],
                        ),
                        body: snapshot.data != null
                            ? RefreshIndicator(
                                onRefresh: () async {
                                  groupNotifier.value =
                                      await db.getGroup(groupid);
                                },
                                child: GroupView(
                                    initialGroup:
                                        snapshot.data ?? dbc.demoGroup))
                            : Text("Couldn't load group $groupid"));
                  });
            } else {
              return Scaffold(
                  backgroundColor: cl.darkerGrey,
                  body: const Center(
                      child: cw.LoadingIndicator(color: Colors.white)));
            }
          },
        ));
  }
}

class GroupView extends StatelessWidget {
  dbc.Group initialGroup;
  GroupView({super.key, required this.initialGroup});

  @override
  Widget build(BuildContext context) {
    ValueNotifier<dbc.Group> group = ValueNotifier<dbc.Group>(initialGroup);
    bool isGroupAdmin = currently_loggedin_as.value != null &&
        group.value.members_roles != null &&
        group.value.members_roles!
            .containsKey(db.db.doc(currently_loggedin_as.value!.path)) &&
        group.value
                .members_roles![db.db.doc(currently_loggedin_as.value!.path)] ==
            "Founder";
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
                          if (isGroupAdmin)
                            IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.edit,
                                  color: cl.darkerGrey,
                                )),
                          ValueListenableBuilder(
                              valueListenable: group,
                              builder: (context, groupVal, foo) {
                                return Text(group.value.title ?? "Title",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                20));
                              }),
                          if (isGroupAdmin)
                            IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  ValueNotifier<String?> titleNot =
                                      ValueNotifier<String?>(group.value.title);
                                  await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return cw.SimpleStringEditDialog(
                                            to_notify: titleNot);
                                      });

                                  if (titleNot.value != null &&
                                      titleNot.value != group.value.title) {
                                    group.value.title = titleNot.value;
                                    await db.db
                                        .doc(
                                            "${branchPrefix}groups/${group.value.groupid}")
                                        .update({"title": group.value.title});
                                    group.notifyListeners();
                                  }
                                }),
                        ],
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                                children: [Text(
                                    "Hosted events: ${group.value.events.length}",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                25)),
                                                ListView(
                                                  
                                            children: db.queriefyEventList(groups.events, filters)
                                                .map(
                                                    (e) => hostedEventCard(e as dbc.Event))
                                                    .toList()
                                                ,),
                                                ]),
                            Column(
                                
                                children: [Text(
                                    "Members: ${group.value.members_roles?.length ?? 0}",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                25)),
                                                ListView(
                                            children: dbc
                                                .Group.members_roles!
                                                .map(
                                                    (e) => GroupMemberCard(e))
                                                    .toList()
                                                ,),
                                                ])
                          ])
                    ]))));
  }
}
