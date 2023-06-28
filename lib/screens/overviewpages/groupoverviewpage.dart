// ignore_for_file: sort_child_properties_last, invalid_use_of_visible_for_testing_member

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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
                          centerTitle: true,
                          title: GestureDetector(
                            onLongPress: () {
                              if (group != null) {
                                Clipboard.setData(
                                    ClipboardData(text: group.groupid));
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text("Copied ID to clipboard")));
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

//! Children ListTiles go here!
class ANNOUNCEMENT extends StatelessWidget {
  dbc.FeedEntry entry;
  ANNOUNCEMENT({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cl.darkerGrey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: BorderSide(
                    width: 1,
                    color: cl.lighterGrey,
                  )
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(timestamp2readablestamp(entry.timestamp),
                style: TextStyle(color: Colors.white)),
            Divider(
              thickness: 1,
              color: cl.lighterGrey,
            ),
            Text(entry.textcontent ?? "This Announcment is empty.",
                style: TextStyle(color: Colors.white))
          ],
        ),
      ),
    );
  }
}

class NewsFeed extends StatelessWidget {
  String groupID;
  NewsFeed({super.key, required this.groupID});

  List<Widget> buildFeedCards(List<dbc.FeedEntry> entries) {
    List<Widget> outL = [];
    entries.forEach((element) {
      switch (element.type) {
        case dbc.FeedEntryType.ANNOUNCEMENT:
          outL.add(ANNOUNCEMENT(entry: element));
          break;
        default:
      }
    });
    return outL;
  }

  @override
  Widget build(BuildContext context) {
    return !SHOW_FEEDS ? Center(child: Text("News-Feed is disabled right now, but will be enabled by future updates.", style: TextStyle(color: Colors.white))) : FutureBuilder(
        future: db.readGroupFeedListMap(groupID),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            List<dbc.FeedEntry> entries =
                db.feedEntryMapToList(snapshot.data ?? {});
            entries = entries.bynewest().reversed.toList();
            if (entries.isEmpty) {
              return Center(
                  child: Text("This feed is empty...",
                      style: TextStyle(color: cl.lighterGrey)));
            } else {
              return Column(
                children: buildFeedCards(entries),
              );
            }
          } else {
            return LoadingIndicator(
                color: Colors.white, message: "Loading feed...");
          }
        });
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
    ValueNotifier triggerthistorefreshicon = ValueNotifier(null);
    List<Widget> columnWidgetList = [
      Center(
        child: Container(
          width: 150,
          child: InkWell(
            onTap: () async {
              if (isGroupAdmin) {
                ImagePicker picker = ImagePicker();
                XFile? image =
                    await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  File file = File(image.path);
                  await db.uploadGroupIcon(group.value.groupid, file);
                  triggerthistorefreshicon.notifyListeners();
                  ScaffoldMessenger.of(context).showSnackBar(
                      cw.hintSnackBar("Profile Picture Changed!"));
                }
              }
            },
            child: ValueListenableBuilder(
                valueListenable: triggerthistorefreshicon,
                builder: (context, snapshot, foo) {
                  return FutureBuilder(
                      future: FirebaseStorage.instance
                          .ref("groupicons/${group.value.groupid}")
                          .getDownloadURL(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.transparent,
                            foregroundImage: snapshot.hasData
                                ? NetworkImage(snapshot.data ?? "")
                                : null,
                          );
                        } else {
                          return const CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.transparent,
                          );
                        }
                      });
                }),
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
                        fontSize: MediaQuery.of(context).size.width / 20));
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
                        return cw.SimpleStringEditDialog(to_notify: titleNot);
                      });

                  if (titleNot.value != null &&
                      titleNot.value != group.value.title) {
                    group.value.title = titleNot.value;
                    await db.db
                        .doc("${branchPrefix}groups/${group.value.groupid}")
                        .update({"title": group.value.title});
                    group.notifyListeners();
                  }
                }),
        ],
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  cw.hintSnackBar("Viewing of Event-List is WIP."));
            },
            child: Text("Hosted events: ${group.value.events.length}",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width / 25))),
        TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  cw.hintSnackBar("Viewing of Member-List is WIP."));
            },
            child: Text("Members: ${group.value.members_roles?.length ?? 0}",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width / 25)))
      ]),
      Divider(thickness: 2, color: cl.lighterGrey),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Align(
              alignment: Alignment.topCenter,
              child: Text("News-Feed",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: DISPLAY_LONG_SIDE(context) / 30))),
        if(isGroupAdmin) IconButton(onPressed: () {
          
        }, icon: Icon(Icons.add, color: Colors.white))
        ],
      ),
      NewsFeed(groupID: group.value.groupid)
    ];
    return Scaffold(
        backgroundColor: cl.darkerGrey,
        body: SingleChildScrollView(
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 15),
                child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: columnWidgetList))));
  }
}
