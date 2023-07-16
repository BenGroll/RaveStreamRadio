// ignore_for_file: prefer_const_constructors, non_constant_identifier_names, use_build_context_synchronously, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import 'dart:io';

import 'package:beamer/beamer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:ravestreamradioapp/screens/managecalendarscreen.dart'
    as managescreen;
import 'package:ravestreamradioapp/chatting.dart';
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;

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
      backgroundColor: cl.lighterGrey,
      elevation: 0,
      leading: const OpenSidebarButton(),
      title: Text(title),
      centerTitle: true,
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
            icon: Icon(Icons.filter_list, color: Colors.white)),
      ]);
}

/// AppBar for the Favourites homescreen
AppBar FavouritesAppBar(BuildContext context) {
  return AppBar(
    leading: const OpenSidebarButton(),
    backgroundColor: cl.lighterGrey,
    title: const Text("Favourites"),
    centerTitle: true,
  );
}

/// TabBar for the Social Tab of the homescreens

/// AppBar for the Groups homescreen

/// AppBar for the Profile homescreen
AppBar ProfileAppBar(BuildContext context) {
  dbc.User? user = currently_loggedin_as.value;
  return user == null
      ? AppBar(
          backgroundColor: cl.lighterGrey,
          leading: const OpenSidebarButton(),
          title: const Text("Not logged in."),
          centerTitle: true,
        )
      : AppBar(
          backgroundColor: cl.lighterGrey,
          leading: const OpenSidebarButton(),
          title: Text(user.username),
          actions: [
            IconButton(
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
                icon: Icon(Icons.settings))
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
            return const LoadingIndicator(color: Colors.white);
          }
        }));
  }
}

/// Button that opens HomeScreen Drawer
class OpenSidebarButton extends StatelessWidget {
  const OpenSidebarButton({super.key});
  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
        icon: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.height / 300),
          child: kIsWeb
              ? Image.asset("graphics/splash.png")
              : SvgPicture.asset("graphics/rsrvector.svg", color: Colors.white),
        ));
  }
}

/// Button that opens HomeScreen Drawer
class OpenChatButton extends StatelessWidget {
  late BuildContext context;
  OpenChatButton({super.key, required this.context});
  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () {
          if (currently_loggedin_as.value == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                hintSnackBar("You have to be logged in to view chats."));
          } else {
            Scaffold.of(context).openEndDrawer();
          }
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
          child: ListView(
            children: [
              Divider(color: cl.darkerGrey),
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
              Divider(color: cl.darkerGrey),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                tileColor: cl.lighterGrey,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => FeedbackScreen()));
                },
                subtitle: Text("Please tell us what you think!",
                    style: TextStyle(color: Colors.white)),
                title: Text(
                    maxLines: 1,
                    "Feedback",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.height / 40)),
              ),
              Divider(color: cl.darkerGrey),
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
                          return Expanded(
                              child: LoadingIndicator(color: Colors.white));
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
                child: GestureDetector(
                  onDoubleTap: () => deleteAllChats(),
                  child: Text(
                    "© RaveStreamRadio 2023\n v$VERSIONCODE, build $BUILDVERSION",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
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
      backgroundColor: cl.lighterGrey,
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
              icon: Icon(Icons.login)),
        ],
      ),
      drawer: managescreen.ManagingScreensDrawer(),
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
              return LoadingIndicator(color: Colors.white);
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
                                newTime?.hour ??
                                    (initialDate != null
                                        ? initialDate.hour
                                        : 1),
                                newTime?.minute ??
                                    (initialDate != null
                                        ? initialDate.minute
                                        : 1),
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
                            ValueNotifier<dbc.Event> ev =
                                ValueNotifier<dbc.Event>(await db
                                    .getEvent(eventid)
                                    .then((value) => value ?? dbc.demoEvent));
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
                                                          "description": ev
                                                              .value!
                                                              .description
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
                                              to_Notify: ev)),
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

class ProfileDescriptionEditor extends StatelessWidget {
  String? initialValue;
  late String? currentValue;
  Function(String)? onChange;
  ProfileDescriptionEditor(
      {this.initialValue = "", key, required this.onChange})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    currentValue = initialValue;
    return TextFormField(
      initialValue: initialValue,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.multiline,
      maxLines: null,
      autofocus: true,
      expands: true,
      cursorColor: Colors.white,
      onChanged: onChange,
    );
  }
}

class ProfileAliasEditor extends StatelessWidget {
  String? initialValue;
  late String? currentValue;
  Function(String)? onChange;
  ProfileAliasEditor({this.initialValue = "", key, required this.onChange})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    currentValue = initialValue;
    return TextFormField(
      initialValue: initialValue,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.multiline,
      maxLines: null,
      autofocus: true,
      expands: true,
      cursorColor: Colors.white,
      onChanged: onChange,
    );
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
                              Navigator.of(context).pop();
                              showFeedbackDialog(context, [
                                "Thank you!",
                                "Your Report has been submitted.",
                                "It may take a while for a moderator to review and potentially act on your report."
                              ]);
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
      backgroundColor: cl.darkerGrey,
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

class StartChatButton extends StatelessWidget {
  String other_person_username;
  StartChatButton({required this.other_person_username});

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () async {
          if (DISABLE_CHATWINDOW) {
            ScaffoldMessenger.of(context).showSnackBar(hintSnackBar(
                "Chatting is disabled right now, but will soon be available"));
            return;
          }
          print("Other Person Username: $other_person_username");
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return Dialog(
                  backgroundColor: Colors.transparent,
                  child: Container(
                      child: LoadingIndicator(
                    color: Colors.white,
                    message: "Loading Chat...",
                  )),
                );
              });
          ChatOutline? chatThatExists =
              await findPrivateChatByOtherUser(other_person_username);
          print("ChatThatExists: $chatThatExists");
          if (chatThatExists != null) {
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ChatWindow(id: chatThatExists.chatID)));
          } else {
            Navigator.of(context).pop();
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    child: Container(
                        child: LoadingIndicator(
                      color: Colors.white,
                      message: "Creating Chat...",
                    )),
                  );
                });
            String newChatID = await startNewChat(other_person_username);
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ChatWindow(id: newChatID)));
          }
        },
        icon: Icon(Icons.send, color: Colors.white));
  }
}

class ProfileWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  const ProfileWidget({
    Key? key,
    required this.icon,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(
                width: 16,
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: cl.darkerGrey,
            size: 16,
          )
        ],
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final Color color;
  final String? message;
  const LoadingIndicator({super.key, required this.color, this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Column(
          children: [
            AspectRatio(
                aspectRatio: 1,
                child: FractionallySizedBox(
                  widthFactor: 0.66,
                  heightFactor: 0.66,
                  child:
                      CircularProgressIndicator(color: color.withOpacity(0.66)),
                )),
            if (message != null)
              Text(message ?? "Loading...",
                  style: TextStyle(color: Colors.white))
          ],
        ),
      ),
    );
  }
}

class SimpleStringEditDialog extends StatelessWidget {
  ValueNotifier to_notify;
  SimpleStringEditDialog({super.key, required this.to_notify});

  @override
  Widget build(BuildContext context) {
    String stringcontent = to_notify.value ?? "";
    return AlertDialog(
      title: Text("Edit", style: TextStyle(color: Colors.white)),
      backgroundColor: cl.lighterGrey,
      content: TextFormField(
        autofocus: true,
        decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            )),
        style: TextStyle(color: Colors.white),
        cursorColor: Colors.white,
        maxLines: 1,
        initialValue: stringcontent,
        onChanged: (value) {
          stringcontent = value;
        },
      ),
      actions: [
        TextButton(
            onPressed: () {
              if (to_notify.value != stringcontent) {
                to_notify.value = stringcontent;
              }
              Navigator.of(context).pop();
            },
            child: Text("Confirm", style: TextStyle(color: Colors.white))),
      ],
    );
  }
}

class LinkEditingDialog extends StatelessWidget {
  ValueNotifier<List<dbc.Link>> to_Notify;
  LinkEditingDialog({super.key, required this.to_Notify});

  List<Widget> buildListTiles(ValueNotifier<List<dbc.Link>> links, context) {
    List<Widget> widgets = [
      TextButton(
          onPressed: () async {
            ValueNotifier<String> title = ValueNotifier<String>("");
            ValueNotifier<String> url = ValueNotifier<String>("");
            await showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) =>
                    SingleLinkEditDialog(title: title, url: url));
            if (url.value.isNotEmpty) {
              List<dbc.Link> linkbuffer = links.value;
              linkbuffer.add(dbc.Link(
                  title: title.value.isEmpty ? "Link" : title.value,
                  url: url.value));
              links.value = linkbuffer;
              links.notifyListeners();
            }
          },
          child: Text("Add new Link", style: TextStyle(color: Colors.white)))
    ];
    int i = 0;
    for (int i = 0; i < links.value.length; i++) {
      widgets.add(ListTile(
          title:
              Text(links.value[i].title, style: TextStyle(color: Colors.white)),
          trailing: Text("$i", style: TextStyle(color: Colors.white)),
          onTap: () async {
            int index = i;
            ValueNotifier<String> title =
                ValueNotifier<String>(links.value[i].title);
            ValueNotifier<String> url =
                ValueNotifier<String>(links.value[i].url);
            await showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) =>
                    SingleLinkEditDialog(title: title, url: url));
            if (url.value.isNotEmpty) {
              List<dbc.Link> linkbuffer = links.value;
              if (title.value == "DeleteThisLink-12345678912062g53f4v8p0h" &&
                  url.value == "DeleteThisLink-12345678912062g53f4v8p0h") {
                linkbuffer.removeAt(i);
                links.value = linkbuffer;
                links.notifyListeners();
              } else {
                linkbuffer[i] = dbc.Link(
                    title: title.value.isEmpty ? "Link" : title.value,
                    url: url.value);
                links.value = linkbuffer;
                links.notifyListeners();
              }
            }
          }));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    ValueNotifier<List<dbc.Link>> currentLinkList =
        ValueNotifier<List<dbc.Link>>(to_Notify.value);
    return AlertDialog(
      backgroundColor: cl.lighterGrey,
      title: Text("Edit Links", style: TextStyle(color: Colors.white)),
      content: ValueListenableBuilder(
          valueListenable: currentLinkList,
          builder: (context, linklist, foo) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: buildListTiles(currentLinkList, context),
            );
          }),
      actions: [
        TextButton(
          child: Text("Cancel", style: TextStyle(color: Colors.white)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
            child: Text("Save", style: TextStyle(color: Colors.white)),
            onPressed: () {
              to_Notify.value = currentLinkList.value;
              Navigator.of(context).pop();
              to_Notify.notifyListeners();
            })
      ],
    );
  }
}

class SingleLinkEditDialog extends StatelessWidget {
  ValueNotifier<String> title;
  ValueNotifier<String> url;
  SingleLinkEditDialog({super.key, required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    String titleS = title.value;
    String urlS = url.value;
    return AlertDialog(
      backgroundColor: cl.lighterGrey,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text((title != "" || url != "") ? "Edit ${titleS}" : "Add new Link",
              style: TextStyle(color: Colors.white)),
          titleS.isEmpty && urlS.isEmpty
              ? Container()
              : IconButton(
                  icon: Icon(Icons.delete, color: Colors.white),
                  onPressed: () {
                    title.value = "DeleteThisLink-12345678912062g53f4v8p0h";
                    url.value = "DeleteThisLink-12345678912062g53f4v8p0h";
                    Navigator.of(context).pop();
                  },
                )
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            initialValue: titleS,
            autofocus: true,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
                hintText: "Label, e.g 'Instagram'",
                hintStyle: TextStyle(color: Colors.white)),
            onChanged: (value) {
              titleS = value;
            },
            maxLines: null,
          ),
          TextFormField(
            initialValue: urlS,
            autofocus: true,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
                hintText: "URL", hintStyle: TextStyle(color: Colors.white)),
            onChanged: (value) {
              urlS = value;
            },
            maxLines: null,
          )
        ],
      ),
      actions: [
        ElevatedButton(
            onPressed: () {
              title.value = "";
              url.value = "";
              Navigator.of(context).pop();
            },
            child: Text("Cancel", style: TextStyle(color: Colors.white))),
        ElevatedButton(
            onPressed: () {
              title.value = titleS;
              url.value = urlS;
              Navigator.of(context).pop();
            },
            child: Text("Save", style: TextStyle(color: Colors.white)))
      ],
    );
  }
}

class DeleteEventIconButton extends StatelessWidget {
  dbc.Event event;
  DeleteEventIconButton({super.key, required this.event});
  @override
  Widget build(BuildContext context) {
    return db.hasPermissionToEditEventObject(event)
        ? IconButton(
            onPressed: () async {
              await showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: cl.lighterGrey,
                      title: Text("Are you sure?",
                          style: TextStyle(color: Colors.white)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("WARNING",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                          Text("This can not be undone",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold))
                        ],
                      ),
                      actions: [
                        TextButton(
                          child: Text("Cancel",
                              style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text("Delete Event",
                              style: TextStyle(color: Colors.red)),
                          onPressed: () async {
                            bool hasPermission = false;
                            await showDialog(
                                context: context,
                                builder: (context) {
                                  return FutureBuilder(
                                      future: db.hasPermissionToEditEvent(
                                          event.eventid),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState !=
                                            ConnectionState.done) {
                                          return cw.LoadingIndicator(
                                              color: Colors.white);
                                        } else {
                                          if (snapshot.hasData &&
                                              snapshot.data == true) {
                                            return FutureBuilder(
                                                future: db
                                                    .deleteEvent(event.eventid),
                                                builder: (BuildContext context,
                                                    AsyncSnapshot snap) {
                                                  if (snap.connectionState !=
                                                      ConnectionState.done) {
                                                    return AlertDialog(
                                                        backgroundColor:
                                                            cl.lighterGrey,
                                                        content:
                                                            cw.LoadingIndicator(
                                                                color: Colors
                                                                    .white));
                                                  } else {
                                                    return AlertDialog(
                                                      backgroundColor:
                                                          cl.lighterGrey,
                                                      title: Text(
                                                          "Deleted Event",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
                                                      actions: [
                                                        TextButton(
                                                          child: Text("Okay!",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white)),
                                                          onPressed: () {
                                                            if (kIsWeb) {
                                                              Beamer.of(context)
                                                                  .popToNamed(
                                                                      "/events/");
                                                            } else {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                              Navigator.of(
                                                                      context)
                                                                  .maybePop();
                                                            }
                                                          },
                                                        )
                                                      ],
                                                    );
                                                  }
                                                });
                                          } else {
                                            return AlertDialog(
                                              backgroundColor: cl.lighterGrey,
                                              title: Text("Oops.."),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text("Something went wrong.",
                                                      style: TextStyle(
                                                          color: Colors.white)),
                                                  Text(
                                                      "Maybe you dont have permission to delete this.",
                                                      style: TextStyle(
                                                          color: Colors.white))
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  child: Text("Understood",
                                                      style: TextStyle(
                                                          color: Colors.white)),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                )
                                              ],
                                            );
                                          }
                                        }
                                      });
                                });
                          },
                        )
                      ],
                    );
                  });
            },
            icon: Icon(Icons.delete, color: Colors.white))
        : SizedBox(height: 0, width: 0);
  }
}

class EventOverviewpageSideDrawer extends StatelessWidget {
  dbc.Event event;
  EventOverviewpageSideDrawer({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: cl.lighterGrey,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: DISPLAY_SHORT_SIDE(context) / 30,
            vertical: DISPLAY_LONG_SIDE(context) / 60),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              ListTile(
                  title: Text("Report",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: DISPLAY_SHORT_SIDE(context) / 20)),
                  onTap: () {
                    String desc = "";
                    showModalBottomSheet(
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadiusDirectional.circular(8.0)),
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
                                      labelText:
                                          "Tell us more about this report...",
                                      labelStyle:
                                          TextStyle(color: Colors.white),
                                      enabledBorder: OutlineInputBorder(
                                          borderSide:
                                              BorderSide(color: cl.lighterGrey),
                                          borderRadius:
                                              BorderRadius.circular(8.0))),
                                  style: TextStyle(color: Colors.white),
                                  cursorColor: Colors.white,
                                  showCursor: true,
                                ),
                              ),
                              TextButton(
                                  style: TextButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0)),
                                      backgroundColor: cl.lighterGrey),
                                  onPressed: () async {
                                    DocumentReference newRep = await db.db
                                        .collection("${branchPrefix}reports")
                                        .add({
                                      "description": desc,
                                      "issuer": db.db.doc(
                                          "${branchPrefix}users/${currently_loggedin_as.value!.username}"),
                                      "target": event.eventid,
                                      "timestamp": Timestamp.now(),
                                      "state": "filed"
                                    });
                                    await newRep.update({"id": newRep.id});
                                    Navigator.of(context).pop();
                                    showFeedbackDialog(context, [
                                      "Thank you!",
                                      "Your Report has been submitted.",
                                      "It may take a while for a moderator to review and potentially act on your report."
                                    ]);
                                  },
                                  child: Text(
                                    "Report",
                                    style: TextStyle(color: Colors.white),
                                  ))
                            ],
                          );
                        });
                  },
                  trailing: Icon(Icons.report_outlined, color: Colors.white)),
              db.hasPermissionToEditEventObject(event)
                  ? ListTile(
                      title: Text("Edit",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: DISPLAY_SHORT_SIDE(context) / 20)),
                      trailing: Icon(Icons.edit, color: Colors.white),
                      onTap: () {
                        Beamer.of(context)
                            .beamToNamed("/editevent/${event.eventid}");
                      },
                    )
                  : SizedBox(height: 0),
              db.doIHavePermission(GlobalPermission.MODERATE) &&
                      event.status != "frozen"
                  ? ListTile(
                      title: Text("Freeze",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: DISPLAY_SHORT_SIDE(context) / 20)),
                      subtitle: Text(
                          "This hides the event from the public. Only use when Event isnt complying with our values / is being reported / is spam",
                          style: TextStyle(color: Colors.white)),
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  backgroundColor: cl.lighterGrey,
                                  title: Text(
                                      "Do you really want to freeze this Event?",
                                      style: TextStyle(color: Colors.white)),
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text("Cancel",
                                            style: TextStyle(
                                                color: Colors.white))),
                                    TextButton(
                                        onPressed: () async {
                                          showLoadingDialog(
                                              context, "Freezing Event...");
                                          await db.uploadEventToDatabase(
                                              event.copyWith(
                                                  eventid: event.eventid,
                                                  status:
                                                      EventStatus.frozen.name));
                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop();
                                        },
                                        child: Text("YES",
                                            style:
                                                TextStyle(color: Colors.red)))
                                  ],
                                ));
                      },
                    )
                  : SizedBox(height: 0),
              db.doIHavePermission(GlobalPermission.MODERATE) &&
                      event.status == "frozen"
                  ? ListTile(
                      title: Text("UnFreeze",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: DISPLAY_SHORT_SIDE(context) / 20)),
                      subtitle: Text(
                          "This opens up the Event to the public again.",
                          style: TextStyle(color: Colors.white)),
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  backgroundColor: cl.lighterGrey,
                                  title: Text(
                                      "Do you really want to unfreeze this Event?",
                                      style: TextStyle(color: Colors.white)),
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text("Cancel",
                                            style: TextStyle(
                                                color: Colors.white))),
                                    TextButton(
                                        onPressed: () async {
                                          showLoadingDialog(
                                              context, "Unfreezing Event...");
                                          await db.uploadEventToDatabase(
                                              event.copyWith(
                                                  eventid: event.eventid,
                                                  status:
                                                      EventStatus.public.name));
                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop();
                                        },
                                        child: Text("YES",
                                            style:
                                                TextStyle(color: Colors.red)))
                                  ],
                                ));
                      },
                    )
                  : SizedBox(height: 0)
            ]),
      ),
    );
  }
}

void showLoadingDialog(context, [String? task]) {
  showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
            backgroundColor: cl.darkerGrey,
            title: task != null
                ? Text(task, style: TextStyle(color: Colors.white))
                : null,
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [cw.LoadingIndicator(color: Colors.white)]),
          ));
}

void showFeedbackDialog(context, List<String>? messages) {
  showDialog(
      context: context,
      builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(32.0))),
          backgroundColor: cl.lighterGrey,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: DISPLAY_SHORT_SIDE(context) / 50,
                vertical: DISPLAY_LONG_SIDE(context) / 50),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: messages == null
                  ? []
                  : messages
                      .map(
                          (e) => Text(e, style: TextStyle(color: Colors.white)))
                      .toList(),
            ),
          )));
}

void showDevFeedbackDialog(context, List<String>? messages) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(32.0))),
          backgroundColor: cl.lighterGrey,
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Dismiss", style: TextStyle(color: Colors.white)))
          ],
          content: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: DISPLAY_SHORT_SIDE(context) / 50,
                vertical: DISPLAY_LONG_SIDE(context) / 50),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: messages == null
                    ? []
                    : messages
                        .map((e) => SelectableText(e,
                            style: TextStyle(color: Colors.white)))
                        .toList(),
              ),
            ),
          )));
}

class FeedbackScreen extends StatelessWidget {
  String feedbackcontent = "";
  ValueNotifier<dbc.FeedbackCategory> category =
      ValueNotifier(dbc.FeedbackCategory.Idea);
  FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cl.darkerGrey,
      appBar: AppBar(
        title: Text("FeedBack"),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width / 25),
        children: [
          Center(
              child: Text(
                  "Please tell us what we can improve, what you found out doesn't work, any ideas you have or really all your thoughts! We'll address all your Feedback!",
                  maxLines: null,
                  style: TextStyle(color: Colors.white))),
          Divider(color: cl.darkerGrey),
          TextField(
            onChanged: (value) {
              feedbackcontent = value;
            },
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0)),
                filled: true,
                fillColor: cl.lighterGrey,
                hintText: "Feedback",
                labelText: "Tell us your thoughts here",
                labelStyle: const TextStyle(color: Colors.grey),
                hintStyle: const TextStyle(color: Colors.grey)),
            maxLines: null,
            maxLength: null,
          ),
          Divider(color: cl.darkerGrey),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Which Category does your feedback fit in?",
                  maxLines: 2, style: TextStyle(color: Colors.white)),
              ValueListenableBuilder(
                  valueListenable: category,
                  builder: (context, cat, foo) {
                    return DropdownButton(
                        dropdownColor: cl.lighterGrey,
                        value: cat,
                        items: dbc.FeedbackCategory.values
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.name,
                                      style: TextStyle(color: Colors.white)),
                                ))
                            .toList(),
                        onChanged: (dbc.FeedbackCategory? value) {
                          if (value != null) {
                            category.value = value;
                          }
                        });
                  })
            ],
          ),
          Divider(color: cl.darkerGrey),
          InkWell(
              onTap: () async {
                await db.db
                    .doc("feedback/${timestamp2precise(Timestamp.now())}")
                    .set(dbc.FeedBackCollector(
                            category: category.value,
                            feedbackcontent: feedbackcontent,
                            feedbackSenderUserName:
                                currently_loggedin_as.value == null
                                    ? null
                                    : currently_loggedin_as.value!.username)
                        .toMap());
                Navigator.of(context).pop();
                showFeedbackDialog(context,
                    ["Thank you!", "Your Feedback has been submitted."]);
              },
              child: Card(
                  color: cl.lighterGrey,
                  child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(
                          child: Text(
                        "Send Feedback!",
                        style: TextStyle(color: Colors.white),
                      )))))
        ],
      ),
    );
  }
}

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
        backgroundColor: cl.darkerGrey,
        child: Column(
          children: [
            DrawerHeader(
                child: Text("Account Settings",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: DISPLAY_LONG_SIDE(context) / 30))),
            ListTile(
                onTap: () async {
                  showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) => cw.LoadingIndicator(
                          color: Colors.white, message: "Logging out"));
                  await files.writeLoginDataMobile("", "");
                  await files.writeLoginDataWeb("", "");
                  await Future.delayed(Duration(seconds: 3));
                  currently_loggedin_as.value = null;
                  Navigator.of(context).pop();
                },
                title: Text("Log out",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: DISPLAY_LONG_SIDE(context) / 40)),
                trailing: Icon(Icons.logout, color: Colors.white)),
            ListTile(
                onTap: () async {
                  ValueNotifier<bool> deleteEvents = ValueNotifier(true);
                  await showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => AlertDialog(
                            backgroundColor: cl.darkerGrey,
                            title: Text("Are your sure?",
                                style: TextStyle(color: Colors.white)),
                            content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                      "This will permanentely delete your account.",
                                      style: TextStyle(color: Colors.white)),
                                  Text(
                                      "There is no way to recover your data after deletion..",
                                      style: TextStyle(color: Colors.white)),
                                  Text(
                                      "Also delete your Events? (Keeping them will just remove you as a host, but keep the event itself online.)",
                                      style: TextStyle(color: Colors.white)),
                                  ValueListenableBuilder(
                                      valueListenable: deleteEvents,
                                      builder: (context, snapshot, foo) {
                                        return Checkbox(
                                            value: snapshot,
                                            onChanged: (value) {
                                              deleteEvents.value =
                                                  value ?? deleteEvents.value;
                                            });
                                      })
                                ]),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    Scaffold.of(context).closeEndDrawer();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        hintSnackBar(
                                            "Canceled account deletion."));
                                  },
                                  child: Text("Dismiss",
                                      style: TextStyle(color: Colors.white))),
                              TextButton(
                                  onPressed: () async {
                                    cw.showLoadingDialog(context);
                                    await db.deleteUser(
                                        currently_loggedin_as.value?.username ??
                                            "demouser",
                                        deleteEvents.value);
                                    await files.writeLoginDataMobile("", "");
                                    await files.writeLoginDataWeb("", "");
                                    await Future.delayed(Duration(seconds: 3));
                                    currently_loggedin_as.value = null;
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        hintSnackBar(
                                            "Your Account has been deleted."));
                                  },
                                  child: Text("Delete!",
                                      style:
                                          TextStyle(color: Colors.redAccent)))
                            ],
                          ));
                },
                title: Text("Delete this account",
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: DISPLAY_LONG_SIDE(context) / 40)),
                trailing: Icon(Icons.delete, color: Colors.red))
          ],
        ));
  }
}
