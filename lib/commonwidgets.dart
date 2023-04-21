// ignore_for_file: prefer_const_constructors, non_constant_identifier_names, use_build_context_synchronously

import 'dart:io';

import 'package:beamer/beamer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/extensions.dart';
import 'package:ravestreamradioapp/linkbuttons.dart';
import 'package:ravestreamradioapp/screens/descriptioneditingscreen.dart';
import 'package:ravestreamradioapp/screens/eventcreationscreens.dart';
import 'package:ravestreamradioapp/pres/rave_stream_icons_icons.dart'
    show RaveStreamIcons;
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/screens/loginscreen.dart';
import 'package:ravestreamradioapp/screens/mainscreens/calendar.dart';
import 'shared_state.dart';
import 'filesystem.dart' as files;
import 'database.dart' as db;
import 'databaseclasses.dart' as dbc;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:ravestreamradioapp/screens/managecalendarscreen.dart'
    as managescreen;

/// Function to open date picker
///
/// Returns DateTime picked
///
/// If return = null, user canceled the picking
Future<DateTime?> pick_date(BuildContext context, DateTime? initialDate) async {
  return await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(
        DateTime.now().year + 20,
      ));
}

/// Function to open time picker
///
/// Returns TimeOfDay picked
///
/// If return = null, user canceled the picking
Future<TimeOfDay?> pick_time(
    BuildContext context, TimeOfDay? initialTime) async {
  return await showTimePicker(
      context: context, initialTime: initialTime ?? TimeOfDay.now());
}

/// Custom Snackbar used to notify User
///
/// Fixed to the bottom of scaffold body
SnackBar hintSnackBar(String alertMessage) {
  return SnackBar(
      backgroundColor: cl.darkerGrey,
      behavior: SnackBarBehavior.fixed,
      content: Text(alertMessage));
}

/// AppBar for the Calendar homescreen
AppBar CalendarAppBar(
    BuildContext context, ValueNotifier<db.EventFilters> filters,
    {String title = "Events"}) {
  return AppBar(
      backgroundColor: cl.darkerGrey,
      leading: const OpenSidebarButton(),
      actions: [
        IconButton(
            onPressed: () {
              showModalBottomSheet(
                  backgroundColor: cl.lighterGrey,
                  context: context,
                  builder: (BuildContext context) =>
                      EventFilterBottomSheet(filters: filters));
              //ScaffoldMessenger.of(context).s
            },
            icon: Icon(Icons.filter_list, color: Colors.white))
      ],
      title: Text(title),
      centerTitle: true);
}

/// AppBar for the Calendar homescreen
AppBar FavouritesAppBar(BuildContext context) {
  return AppBar(
    leading: const OpenSidebarButton(),
    backgroundColor: cl.darkerGrey,
    title: const Text("Favourites"),
    centerTitle: true,
  );
}

/// TabBar for the Social Tab of the homescreens

/// AppBar for the Groups homescreen
AppBar GroupsAppBar(BuildContext context) {
  return AppBar(
    leading: const OpenSidebarButton(),
    elevation: 8,
    backgroundColor: cl.darkerGrey,
    title: Text("Groups", style: TextStyle(color: Colors.white)),
    centerTitle: true,
    actions: [OpenChatButton(context: context)],
  );
}

/// AppBar for the Profile homescreen
AppBar ProfileAppBar(BuildContext context) {
  dbc.User? user = currently_loggedin_as.value;
  return user == null
      ? AppBar(
          backgroundColor: cl.darkerGrey,
          leading: const OpenSidebarButton(),
          title: const Text("Not logged in."),
          centerTitle: true,
        )
      : AppBar(
          backgroundColor: cl.darkerGrey,
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

/// Button that opens HomeScreen Drawer
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

/// Button that opens HomeScreen Drawer
class OpenChatButton extends StatelessWidget {
  late BuildContext context;
  OpenChatButton({super.key, required this.context});
  @override
  Widget build(BuildContext contextt) {
    return IconButton(
        onPressed: () {
          Scaffold.of(contextt).openEndDrawer();
        },
        icon: Icon(Icons.question_answer));
  }
}

/// SideBar for the homescreen
class NavBar extends StatelessWidget {
  const NavBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Drawer(
        backgroundColor: cl.darkerGrey,
        child: Padding(
          padding: EdgeInsetsDirectional.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            // ignore: prefer_const_literals_to_create_immutables
            children: [
              Expanded(
                child: SizedBox(),
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                tileColor: cl.lighterGrey,
                onTap: () {
                  Beamer.of(context).beamToNamed("/drafts");
                },
                title: Text(
                    maxLines: 2,
                    "Your Drafts",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.height / 40)),
              ),
              Expanded(
                child: SizedBox(),
              ),
              db.doIHavePermission(GlobalPermission.MODERATE) ||
                      db.doIHavePermission(GlobalPermission.MODERATE)
                  ? FutureBuilder(
                      future: db.getOpenReportsCount(),
                      builder: (context, repCount) {
                        if (repCount.connectionState == ConnectionState.done) {
                          return ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                            tileColor: cl.lighterGrey,
                            onTap: () {
                              Beamer.of(context).beamToNamed("/moderate");
                            },
                            title: Text(
                                maxLines: 2,
                                "View Reports",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.of(context).size.height /
                                            40)),
                            subtitle: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${repCount.data?['filed']} filed Report(s)',
                                  style: TextStyle(
                                      color: cl.greynothighlight,
                                      fontSize:
                                          MediaQuery.of(context).size.height /
                                              80),
                                ),
                                Text(
                                  '${repCount.data?['pending']} pending Repor(ts)',
                                  style: TextStyle(
                                      color: cl.greynothighlight,
                                      fontSize:
                                          MediaQuery.of(context).size.height /
                                              80),
                                )
                              ],
                            ),
                          );
                        } else {
                          return CircularProgressIndicator();
                        }
                      })
                  : SizedBox(),
              Divider(color: cl.darkerGrey),
              db.doIHavePermission(GlobalPermission.MANAGE_HOSTS) ||
                      db.doIHavePermission(GlobalPermission.MANAGE_EVENTS)
                  ? ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                      tileColor: cl.lighterGrey,
                      onTap: () {
                        Beamer.of(context).beamToNamed("/manage");
                      },
                      title: Text(
                          maxLines: 2,
                          "Manage Calendar",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  MediaQuery.of(context).size.height / 40)),
                      subtitle: Text(
                        '"MANAGE_EVENTS" permission needed.',
                        style: TextStyle(
                            color: cl.greynothighlight,
                            fontSize: MediaQuery.of(context).size.height / 80),
                      ),
                    )
                  : SizedBox(),
              Divider(color: cl.darkerGrey),
              db.doIHavePermission(GlobalPermission.CHANGE_DEV_SETTINGS)
                  ? ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                      tileColor: cl.lighterGrey,
                      onTap: () {
                        Beamer.of(context).beamToNamed("/dev");
                      },
                      title: Text("Dev. Settings",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  MediaQuery.of(context).size.height / 40)),
                      subtitle: Text(
                        '"CHANGE_DEV_SETTINGS" permission needed.',
                        style: TextStyle(
                            color: cl.greynothighlight,
                            fontSize: MediaQuery.of(context).size.height / 80),
                      ),
                    )
                  : SizedBox(height: 0),
              Divider(color: cl.darkerGrey),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                tileColor: cl.lighterGrey,
                onTap: () {
                  Beamer.of(context).beamToNamed("/social");
                },
                title: Text("About Us(DE)",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.height / 40)),
              ),
              Divider(color: cl.darkerGrey),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                tileColor: cl.lighterGrey,
                onTap: () {
                  Beamer.of(context).beamToNamed("/imprint");
                },
                title: Text("Imprint(DE)",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.height / 40)),
              ),
              Divider(color: cl.darkerGrey),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                tileColor: cl.lighterGrey,
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
        ));
  }
}

/// Default Screen to display Errors
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
      backgroundColor: cl.darkerGrey,
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(errormessage, style: TextStyle(color: Colors.white)),
            Text("ErrorCode: ${errorcode ?? -1}",
                style: TextStyle(color: Colors.white))
          ]),
    );
  }
}

/// EventList notifier
ValueNotifier<List<Map<String, dynamic>>> eventListNOT = ValueNotifier([]);

/// Table to edit and view all Event data
class EventTable extends StatelessWidget {
  ValueNotifier<bool> editTable = ValueNotifier<bool>(false);
  EventTable({super.key});

  @override
  Widget build(BuildContext context) {
    ValueNotifier<int?> sortIndex = ValueNotifier(null);
    ValueNotifier<bool> isAscending = ValueNotifier<bool>(false);
    return Scaffold(
      backgroundColor: cl.darkerGrey,
      appBar: AppBar(
        centerTitle: true,
        title: Text("Events"),
        actions: [
          ValueListenableBuilder(
              valueListenable: editTable,
              builder: (context, value, foo) {
                return IconButton(
                    onPressed: () {
                      editTable.value = !editTable.value;
                    },
                    icon: Icon(
                      value ? Icons.build_circle : Icons.build_circle_outlined,
                      color: Colors.white,
                    ));
              }),
          IconButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => LoginScreen()));
              },
              icon: Icon(Icons.login))
        ],
      ),
      drawer: Drawer(
        backgroundColor: cl.lighterGrey,
        child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            // ignore: prefer_const_literals_to_create_immutables
            children: !db.doIHavePermission(GlobalPermission.MANAGE_EVENTS)
                ? []
                : [
                    ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                      tileColor: cl.lighterGrey,
                      onTap: () {
                        managescreen.selectedManagementScreen.value =
                            managescreen.ManagementScreens.Events;
                        managescreen.scaffoldKey.currentState!.closeDrawer();
                      },
                      title: Text("Events",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  MediaQuery.of(context).size.height / 40)),
                    ),
                    ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                      tileColor: cl.lighterGrey,
                      onTap: () {
                        managescreen.selectedManagementScreen.value =
                            managescreen.ManagementScreens.Hosts;
                        managescreen.scaffoldKey.currentState!.closeDrawer();
                      },
                      title: Text("Hosts",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  MediaQuery.of(context).size.height / 40)),
                    ),
                    ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                      tileColor: cl.lighterGrey,
                      onTap: () {
                        managescreen.selectedManagementScreen.value =
                            managescreen.ManagementScreens.Media;
                        managescreen.scaffoldKey.currentState!.closeDrawer();
                      },
                      title: Text("Media",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  MediaQuery.of(context).size.height / 40)),
                    ),
                  ]),
      ),
      body: FutureBuilder(
          future: db.readEventIndexesJson(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              eventListNOT.value = db
                  .getEventListFromIndexes(snapshot.data)
                  .map((e) => e.toMap())
                  .toList();
              List<String> columns = eventListNOT.value.first.keys.toList();
              return ValueListenableBuilder(
                  valueListenable: editTable,
                  builder: (context, editing, foo) {
                    return ValueListenableBuilder(
                        valueListenable: eventListNOT,
                        builder: (context, snapshot, foo) {
                          return ValueListenableBuilder(
                              valueListenable: sortIndex,
                              builder: (context, sortIDX, foo) {
                                return ValueListenableBuilder(
                                    valueListenable: isAscending,
                                    builder: (context, isAsc, foo) {
                                      return SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.vertical,
                                            child: Theme(
                                              data: ThemeData(
                                                  iconTheme: IconThemeData(
                                                      color: Color.fromARGB(
                                                          255, 209, 209, 209))),
                                              child: DataTable(
                                                  border: TableBorder.all(
                                                      color: Color.fromARGB(
                                                          255, 172, 172, 172)),
                                                  sortAscending: isAsc,
                                                  sortColumnIndex: sortIDX,
                                                  columns: columns
                                                      .map((e) => DataColumn(
                                                            label: Text(e,
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white)),
                                                            onSort: (int idx,
                                                                bool
                                                                    isAscendingOrder) {
                                                              sortIndex.value =
                                                                  idx;
                                                              isAscending
                                                                      .value =
                                                                  isAscendingOrder;
                                                              try {
                                                                if (isAscendingOrder) {
                                                                  String
                                                                      sortattribute =
                                                                      eventListNOT
                                                                          .value[
                                                                              0]
                                                                          .keys
                                                                          .toList()[sortIndex
                                                                              .value ??
                                                                          0];
                                                                  if (sortattribute ==
                                                                      "hostreference") {
                                                                    return;
                                                                  }
                                                                  List<Map<String, dynamic>>
                                                                      list =
                                                                      eventListNOT
                                                                          .value;
                                                                  list.sort((a,
                                                                          b) =>
                                                                      a[sortattribute]
                                                                          .compareTo(
                                                                              b[sortattribute]));
                                                                  eventListNOT
                                                                          .value =
                                                                      list;
                                                                } else {
                                                                  String
                                                                      sortattribute =
                                                                      eventListNOT
                                                                          .value[
                                                                              0]
                                                                          .keys
                                                                          .toList()[sortIndex
                                                                              .value ??
                                                                          0];
                                                                  if (sortattribute ==
                                                                      "hostreference") {
                                                                    return;
                                                                  }
                                                                  List<Map<String, dynamic>>
                                                                      list =
                                                                      eventListNOT
                                                                          .value;
                                                                  list.sort((b,
                                                                          a) =>
                                                                      a[sortattribute]
                                                                          .compareTo(
                                                                              b[sortattribute]));
                                                                  eventListNOT
                                                                          .value =
                                                                      list;
                                                                }
                                                              } catch (e) {
                                                                pprint(e);
                                                              }
                                                            },
                                                          ))
                                                      .toList(),
                                                  rows: getRows(
                                                      eventListNOT.value,
                                                      context,
                                                      editing)),
                                            ),
                                          ));
                                    });
                              });
                        });
                  });
            } else {
              return CircularProgressIndicator(color: Colors.white);
            }
          }),
    );
  }

  List<DataRow> getRows(
      List<Map<String, dynamic>> events, BuildContext context, bool editing) {
    return events.map((event) {
      bool allowed_to_edit =
          db.hasPermissionToEditEventObject(dbc.Event.fromMap(event));
      String eventid = event["eventid"];
      return DataRow(
          color: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
            // Even rows will have a grey color.
            if (allowed_to_edit) {
              return Color.fromARGB(255, 116, 116, 116).withOpacity(0.2);
            } else {
              return cl
                  .darkerGrey; // Use default value for other states and odd rows.
            }
          }),
          cells: event.keys.map((String key) {
            if (event[key] == null) {
              return DataCell(
                Text("Empty", style: TextStyle(color: Colors.white)),
                showEditIcon: editing && allowed_to_edit,
              );
            } else if (event[key] is DocumentReference) {
              return DataCell(
                  buildLinkButtonFromRef(
                      event[key], TextStyle(color: Colors.white)),
                  showEditIcon: editing && allowed_to_edit,
                  onTap: !db.hasPermissionToEditEventObject(
                          dbc.Event.fromMap(event))
                      ? null
                      : () {});
            } else if (event[key] is Timestamp) {
              return DataCell(
                  Text(
                    timestamp2readablestamp(event[key]),
                    style: TextStyle(color: Colors.white),
                  ),
                  showEditIcon: editing && allowed_to_edit,
                  onTap: !db.hasPermissionToEditEventObject(
                          dbc.Event.fromMap(event))
                      ? null
                      : () async {
                          DateTime? initialDate;
                          if (event[key] != null) {
                            initialDate = DateTime.fromMillisecondsSinceEpoch(
                                event[key].millisecondsSinceEpoch);
                          }
                          DateTime? newDate =
                              await pick_date(context, initialDate);
                          TimeOfDay? newTime;
                          if (initialDate == null) {
                            newTime = TimeOfDay.now();
                          } else {
                            newTime = await pick_time(
                                context, TimeOfDay.fromDateTime(initialDate));
                          }
                          int? foundEventIndex = eventListNOT.value
                              .whereIsEqual("eventid", eventid);
                          if (foundEventIndex != null) {
                            if (newDate != null) {
                              if (newTime == null) {
                                eventListNOT.value[foundEventIndex][key] =
                                    Timestamp.fromDate(newDate);
                              } else {
                                return;
                              }
                              await db.db
                                  .doc("${branchPrefix}events/$eventid")
                                  .update(
                                      {"$key": Timestamp.fromDate(newDate)});
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(hintSnackBar("$key Changed."));
                            } else {
                              DateTime newFinalDateTime = DateTime(
                                (initialDate != null ? initialDate.year : 2000),
                                (initialDate != null ? initialDate.month : 1),
                                (initialDate != null ? initialDate.day : 1),
                                newTime?.hour ?? (initialDate != null ? initialDate.hour : 1),
                                newTime?.minute ?? (initialDate != null ? initialDate.minute : 1),
                              );
                              eventListNOT.value[foundEventIndex][key] =
                                  Timestamp.fromDate(newFinalDateTime);
                            }
                          }
                        });
            } else if (event[key] is Map) {
              return DataCell(
                  Text(
                    "${event[key].length} Entries.",
                    style: TextStyle(color: Colors.white),
                  ),
                  showEditIcon: editing && allowed_to_edit,
                  onTap: db.hasPermissionToEditEventObject(
                          dbc.Event.fromMap(event))
                      ? () {}
                      : null);
            } else if (key == "eventid") {
              return DataCell(
                  Text(
                    event[key].toString(),
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: db.hasPermissionToEditEventObject(
                          dbc.Event.fromMap(event))
                      ? null
                      : () {});
            } else if (key == "description") {
              return DataCell(
                TextButton(
                    onPressed: !db.hasPermissionToEditEventObject(
                            dbc.Event.fromMap(event))
                        ? null
                        : () async {
                            //pprint(eventid);
                            String description = await db
                                .getEvent(eventid)
                                .then((value) => value?.description ?? "");
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) => WillPopScope(
                                      onWillPop: () async {
                                        int? foundEventIndex = eventListNOT
                                            .value
                                            .whereIsEqual("eventid", eventid);
                                        bool close = false;
                                        await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text("Save Changes?"),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () async {
                                                        await db.db
                                                            .doc(
                                                                "${branchPrefix}events/$eventid")
                                                            .update({
                                                          "description":
                                                              description
                                                        });

                                                        Navigator.of(context)
                                                            .pop();
                                                        close = true;
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                                hintSnackBar(
                                                                    "Description Changed."));
                                                      },
                                                      child: Text("Yes")),
                                                  TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                        Navigator.of(context)
                                                            .pop();
                                                        close = false;
                                                      },
                                                      child: Text("Cancel"))
                                                ],
                                              );
                                            });
                                        return close;
                                      },
                                      child: Scaffold(
                                          backgroundColor: Colors.black,
                                          appBar: AppBar(
                                            title: Text("Edit Description"),
                                          ),
                                          body: DescriptionEditingPage(
                                            initialValue: description,
                                            onChange: (value) {
                                              description = value;
                                            },
                                          )),
                                    )));
                          },
                    child: Row(
                      children: [
                        Text("Show Description",
                            style: TextStyle(color: Colors.white)),
                        Icon(
                          Icons.open_in_new,
                          color: Color.fromARGB(255, 207, 207, 207),
                        )
                      ],
                    )),
              );
            }
            return DataCell(
                Text(
                  event[key].toString(),
                  style: TextStyle(color: Colors.white),
                ),
                showEditIcon: editing && allowed_to_edit,
                onTap:
                    db.hasPermissionToEditEventObject(dbc.Event.fromMap(event))
                        ? () {}
                        : null);
          }).toList());
    }).toList();
  }
}

class ReportButton extends StatelessWidget {
  final String target;
  const ReportButton({super.key, required this.target});

  @override
  Widget build(BuildContext context) {
    return currently_loggedin_as.value == null
        ? Container()
        : IconButton(
            onPressed: () {
              String desc = "";
              showModalBottomSheet(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusDirectional.circular(8.0)),
                  backgroundColor: cl.darkerGrey,
                  context: context,
                  builder: (BuildContext context) {
                    return Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            onChanged: (value) {
                              desc = value;
                            },
                            minLines: 5,
                            maxLines: 2000,
                            decoration: InputDecoration(
                                filled: true,
                                fillColor: cl.lighterGrey,
                                labelText: "Tell us more about this report...",
                                labelStyle: TextStyle(color: Colors.white),
                                enabledBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: cl.lighterGrey),
                                    borderRadius: BorderRadius.circular(8.0))),
                            style: TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            showCursor: true,
                          ),
                        ),
                        TextButton(
                            style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0)),
                                backgroundColor: cl.lighterGrey),
                            onPressed: () async {
                              DocumentReference newRep = await db.db
                                  .collection("${branchPrefix}reports")
                                  .add({
                                "description": desc,
                                "issuer": db.db.doc(
                                    "${branchPrefix}users/${currently_loggedin_as.value!.username}"),
                                "target": target,
                                "timestamp": Timestamp.now(),
                                "state": "filed"
                              });
                              await newRep.update({"id": newRep.id});
                              ScaffoldMessenger.of(context).showSnackBar(
                                  hintSnackBar("Report was sent!"));
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              "Report",
                              style: TextStyle(color: Colors.white),
                            ))
                      ],
                    );
                  });
            },
            icon: Icon(
              Icons.report_outlined,
              color: Colors.white,
            ));
  }
}

class EventFilterSideBar extends StatelessWidget {
  ValueNotifier<db.EventFilters> filters;
  EventFilterSideBar({super.key, required this.filters});
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: cl.lighterGrey,
      child: Scaffold(
        appBar: AppBar(title: Text("Filter(s)")),
        body: ListView(
          // ignore: prefer_const_literals_to_create_immutables
          children: [
            ListTile(
              dense: true,
              title: Text(
                  maxLines: 1,
                  "After (Timestamp)",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.height / 40)),
            ),
            ListTile(
              dense: false,
              title: Text(
                  maxLines: 1,
                  "TBI Pick Timestamp",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.height / 40)),
            ),
            ListTile(
              dense: true,
              title: Text(
                  maxLines: 1,
                  "Before (Timestamp)",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.height / 40)),
            ),
            ListTile(
              dense: false,
              title: Text(
                  maxLines: 1,
                  "Age limit",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.height / 40)),
            ),
            ListTile(
                dense: false,
                title: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(),
                )),
            ListTile(
              dense: false,
              title: Text(
                  maxLines: 1,
                  "TBI Pick Timestamp",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.height / 40)),
            ),
          ],
        ),
      ),
    );
  }
}
