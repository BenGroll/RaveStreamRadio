// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import 'dart:io';
import 'package:beamer/beamer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/screens/descriptioneditingscreen.dart';
import 'package:ravestreamradioapp/screens/homescreen.dart';
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/screens/mainscreens/calendar.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:flutter/scheduler.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:ravestreamradioapp/extensions.dart';

/// What text to show in the dropdown to host as yourself
const HOST_YOURSELF_ID = "Host as yourself.";

/// Screens
enum Screen { general, description, links, media }

/// Loading Animation
const loader = cw.LoadingIndicator(color: Colors.white);

class EventCreationScreen extends StatelessWidget {
  final String? eventIDToBeEdited;

  /// PIADGPIDW
  ValueNotifier<Screen> current_screen = ValueNotifier<Screen>(Screen.general);
  ValueNotifier<bool> is_awaiting_upload = ValueNotifier(false);
  bool block_upload = false;

  ValueNotifier<dbc.Event> currentEventData = ValueNotifier<dbc.Event>(
      dbc.Event(
          eventid: "",
          title: "",
          locationname: "",
          description: "",
          links: {}));

  List<dbc.Link> editLinkInList(List<dbc.Link> links, dbc.Link searchlink) {
    List<dbc.Link> bufferlist = links.reversed.toList().reversed.toList();
    for (int i = 0; i < links.length; i++) {
      if (links[i] == searchlink) {
        bufferlist[i].title = searchlink.title;
        bufferlist[i].url = searchlink.url;
        return bufferlist;
      }
    }
    return bufferlist;
  }

  List<Widget> getLinkList(BuildContext context, List<dbc.Link> links) {
    List<Widget> linkso = [];
    links.forEach((element) {
      linkso.add(LinkListCard(link: element, parent: this));
    });
    linkso.add(AddLinkButton(parent: this));
    return linkso;
  }

  Future uploadEvent(dbc.Event event, BuildContext context) async {
    print(event.hostreference);
    is_awaiting_upload.value = true;
    if (event.templateHostID != null && event.templateHostID!.isNotEmpty) {
      event.hostreference = null;
    }
    await db.uploadEventToDatabase(event);
    await Future.delayed(Duration(seconds: 1));
    kIsWeb ? Beamer.of(context).popToNamed("/") : Navigator.of(context).pop();
    if (kIsWeb) {
      eventIDToBeEdited != null
          ? ScaffoldMessenger.of(context)
              .showSnackBar(cw.hintSnackBar("Event edited successfully!"))
          : ScaffoldMessenger.of(context)
              .showSnackBar(cw.hintSnackBar("Event created successfully!"));
    }
    currently_selected_screen.notifyListeners();
    is_awaiting_upload.value = false;
    Navigator.of(context).pop();
  }

  /// if it returns an empty list, the validate is without error.
  ///
  /// The List contains the seperate error messages
  Future<List<String>> validateUpload() async {
    dbc.Event toValidate = currentEventData.value;
    bool eventIdEmpty = true;
    List<String> errormessages = [];
    if (toValidate.templateHostID == null && toValidate.hostreference == null) {
      errormessages.add("Event needs a host specified.");
    }
    if (toValidate.templateHostID == HOST_YOURSELF_ID) {
      currentEventData.value.hostreference = db.db
          .doc("${branchPrefix}users/${currently_loggedin_as.value!.username}");
      toValidate.templateHostID = null;
    }
    if (validateEventIDFieldLight(currentEventData.value.eventid) != null) {
      errormessages
          .add(validateEventIDFieldLight(currentEventData.value.eventid)!);
    } else {
      eventIdEmpty = false;
    }

    if (toValidate.templateHostID != null) {
      DocumentSnapshot hostDocRef =
          await db.db.doc("demohosts/${toValidate.templateHostID}").get();
      if (!hostDocRef.exists) {
        errormessages
            .add("Templatehost ${toValidate.templateHostID} does not exist.");
      }
    }
    if (eventIDToBeEdited != null) {
    } else {
      if (!eventIdEmpty) {
        if (await validateEventIDFieldDB(currentEventData.value.eventid) !=
            null) {
          errormessages.add("EventID is taken. Choose another one");
        }
      }
    }
    if (currentEventData.value.title == null ||
        currentEventData.value.title!.isEmpty) {
      errormessages.add("You have to give your event a title.");
    }
    return errormessages;
  }

  /// Takes List<dbc.Link>
  ///
  /// Returns {title : url} map
  Map<String, String> linkListToDBMap(List<dbc.Link> list) {
    Map<String, String> outmap = {};
    list.forEach((element) {
      outmap[element.title] = element.url;
    });
    return outmap;
  }

  Widget mapScreenToWidget(Screen selection) {
    switch (selection) {
      case Screen.general:
        {
          return GeneralSettingsPage(parent: this);
        }
      case Screen.description:
        {
          return DescriptionEditingPage(
              initialValue: currentEventData.value.description ?? "empty",
              onChange: (String value) {
                currentEventData.value.description = value;
              });
        }
      case Screen.links:
        {
          return LinkEditingScreen(parent: this);
        }
      case Screen.media:
        {
          return MediaEditingScreen(parent: this);
        }
      default:
        return Container();
    }
  }

  String? validateEventIDFieldLight(String content) {
    if (content.isEmpty) {
      return "EventID: Can't be empty.";
    }
    String allowed = "abcdefghijklmnopqrstuvwxyz0123456789";
    bool notallowed = false;
    content.characters.forEach((element) {
      if (!allowed.contains(element)) {
        notallowed = true;
      }
    });
    if (notallowed) {
      return "EventID: Only a-z and 0-9 allowed.";
    }
    return null;
  }

  Future<String?> validateEventIDFieldDB(String content) async {
    if (content.isEmpty) return "";
    bool isFree = await db.db
        .collection("${branchPrefix}events")
        .doc(content)
        .get()
        .then((value) => !value.exists);
    return isFree ? null : "Eventid: Already taken.";
  }

  EventCreationScreen({super.key, this.eventIDToBeEdited = null});
  @override
  Widget build(BuildContext context) {
    current_screen.value = Screen.general;
    currentEventData.value = dbc.Event(
        eventid: "", title: "", locationname: "", description: "", links: {});
    // Add decision tree
    if (currently_loggedin_as.value == null) {
      return const cw.ErrorScreen(
          errormessage: "You have to be logged in to create or edit events.");
    } else {
      currentEventData.value.hostreference = db.db
          .doc("${branchPrefix}users/${currently_loggedin_as.value!.username}");
      if (eventIDToBeEdited == null) {
        // Open Create new event eventcreationscreen
        return DefaultTabController(
          length: 4,
          child: ValueListenableBuilder(
              valueListenable: current_screen,
              builder: (context, screen, child) {
                return Scaffold(
                    backgroundColor: cl.darkerGrey,
                    appBar: AppBar(
                      backgroundColor: cl.darkerGrey,
                      bottom: const TabBar(tabs: [
                        Tab(
                          child: Text("General"),
                        ),
                        Tab(
                          child: Text("Desc."),
                        ),
                        Tab(
                          child: Text("Links"),
                        ),
                        Tab(
                          child: Text("Media"),
                        ),
                      ]),
                      actions: [
                        TextButton(
                            onPressed: () async {
                              print(block_upload);
                              if (!block_upload) {
                                block_upload = true;
                                List<Widget> errorcontent =
                                    await validateUpload().then((value) {
                                  return value
                                      .map((e) => Text(e,
                                          style:
                                              TextStyle(color: Colors.white)))
                                      .toList();
                                });
                                block_upload = false;
                                if (errorcontent.isEmpty) {
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) =>
                                          UploadEventDialog(parent: this));
                                } else {
                                  showDialog(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (context) => UploadingErrorDialog(
                                        errormessages: errorcontent,
                                        parent: this),
                                  );
                                }
                              }
                            },
                            child: Text("Upload",
                                style: TextStyle(color: Colors.white)))
                      ],
                    ),
                    body: TabBarView(
                      children: [
                        GeneralSettingsPage(parent: this),
                        DescriptionEditingPage(onChange: (String value) {
                          currentEventData.value.description = value;
                        }),
                        LinkEditingScreen(parent: this),
                        MediaEditingScreen(parent: this)
                      ],
                    ));
              }),
        );
      } else {
        // Am I allowed to edit this event?
        return FutureBuilder(
            future: db.hasPermissionToEditEvent(eventIDToBeEdited!),
            builder: (context, canEditSnap) {
              if (canEditSnap.connectionState == ConnectionState.done) {
                if (canEditSnap.data == null) {
                  return cw.ErrorScreen(
                      errormessage:
                          "Snapshot from 'db.hasPermissionToEditEvent' has no data.");
                } else {
                  if (canEditSnap.data!) {
                    // User has permission to edit event
                    print("lol0");
                    return DefaultTabController(
                      length: 4,
                      child: FutureBuilder(
                          future: db.getEvent(eventIDToBeEdited!),
                          builder: (context, existingEventDataSnap) {
                            if (existingEventDataSnap.connectionState ==
                                ConnectionState.done) {
                              if (existingEventDataSnap.hasData &&
                                  existingEventDataSnap.data != null) {
                                // Load existing values
                                dbc.Event event = existingEventDataSnap.data!;
                                currentEventData.value = event;
                                // / Load existing values
                                return ValueListenableBuilder(
                                    valueListenable: current_screen,
                                    builder: (context, screen, child) {
                                      return Scaffold(
                                          backgroundColor: cl.darkerGrey,
                                          appBar: AppBar(
                                            bottom: TabBar(tabs: [
                                              Tab(
                                                child: Text("General"),
                                              ),
                                              Tab(
                                                child: Text("Desc."),
                                              ),
                                              Tab(
                                                child: Text("Links"),
                                              ),
                                              Tab(
                                                child: Text("Media"),
                                              ),
                                            ]),
                                            actions: [
                                              TextButton(
                                                  onPressed: () async {
                                                    if (!block_upload) {
                                                      block_upload = true;
                                                      List<Widget>
                                                          errorcontent =
                                                          await validateUpload()
                                                              .then((value) {
                                                        return value
                                                            .map((e) => Text(e,
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white)))
                                                            .toList();
                                                      });
                                                      if (errorcontent
                                                          .isEmpty) {
                                                        showDialog(
                                                            barrierDismissible:
                                                                false,
                                                            context: context,
                                                            builder: (context) =>
                                                                UploadEventDialog(
                                                                    parent:
                                                                        this));
                                                      } else {
                                                        showDialog(
                                                          barrierDismissible:
                                                              true,
                                                          context: context,
                                                          builder: (context) =>
                                                              UploadingErrorDialog(
                                                                  errormessages:
                                                                      errorcontent,
                                                                  parent: this),
                                                        );
                                                      }
                                                    }
                                                  },
                                                  child: Text("Upload",
                                                      style: TextStyle(
                                                          color: Colors.white)))
                                            ],
                                          ),
                                          body: TabBarView(
                                            children: [
                                              GeneralSettingsPage(parent: this),
                                              DescriptionEditingPage(
                                                  initialValue: currentEventData
                                                          .value.description ??
                                                      "",
                                                  onChange: (String value) {
                                                    currentEventData.value
                                                        .description = value;
                                                  }),
                                              LinkEditingScreen(parent: this),
                                              MediaEditingScreen(parent: this)
                                            ],
                                          ));
                                    });
                              } else {
                                return cw.ErrorScreen(
                                    errormessage:
                                        "Snapshot from 'db.getEvent' has no data or data is null.");
                              }
                            } else {
                              return loader;
                            }
                          }),
                    );
                  } else {
                    return cw.ErrorScreen(
                        errormessage:
                            "You do not have the permission to edit event @$eventIDToBeEdited.\nIf you believe this is an error, please contact the host or the RaveStreamRadio team.");
                  }
                }
              } else {
                return loader;
              }
            });
      }
    }

    // For type safety
  }
}

class GeneralSettingsPage extends StatelessWidget {
  ValueNotifier<String?> eventidvalidator =
      ValueNotifier<String?>("!EventID can't be empty");
  EventCreationScreen parent;
  GeneralSettingsPage({super.key, required this.parent});

  @override
  Widget build(BuildContext context) {
    eventidvalidator.value =
        parent.eventIDToBeEdited == null ? "!EventID can't be empty" : null;
    ValueNotifier<bool> isEventTitleEmpty = ValueNotifier<bool>(
        parent.currentEventData.value.title == null ||
            parent.currentEventData.value.title!.isEmpty);
    return Padding(
        padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width / 25),
        child: ListView(
          children: [
            ValueListenableBuilder(
                valueListenable: eventidvalidator,
                builder: (context, eventidvalidatedstring, child) {
                  return Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height / 100,
                          horizontal: MediaQuery.of(context).size.width / 50),
                      child: Column(children: [
                        Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: const [
                              Expanded(
                                  child: Divider(
                                      color:
                                          Color.fromARGB(255, 179, 179, 179))),
                              Text("Choose Host",
                                  style: TextStyle(color: Colors.white)),
                              Expanded(
                                  child: Divider(
                                      color:
                                          Color.fromARGB(255, 179, 179, 179)))
                            ]),
                        !db.doIHavePermission(GlobalPermission.MANAGE_EVENTS)
                            ? SizedBox(height: 0)
                            : FutureBuilder(
                                future: db.getDemoHostIDs(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<Map<String, String>>
                                        snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.done) {
                                    List<String> sortedValuesList =
                                        snapshot.data!.values.toList()..sort();
                                    sortedValuesList.insert(
                                        0, HOST_YOURSELF_ID);
                                    return Theme(
                                      data: ThemeData.dark(),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 6,
                                            child: ValueListenableBuilder(
                                                valueListenable:
                                                    parent.currentEventData,
                                                builder: (context,
                                                    eventDatacurrent, foo) {
                                                  return DropdownSearch(
                                                    selectedItem: snapshot
                                                            .data!.keys
                                                            .contains(parent
                                                                .currentEventData
                                                                .value
                                                                .templateHostID)
                                                        ? snapshot.data![parent
                                                            .currentEventData
                                                            .value
                                                            .templateHostID]
                                                        : parent
                                                            .currentEventData
                                                            .value
                                                            .templateHostID,
                                                    onChanged: (value) {
                                                      pprint(
                                                          "New Build Invoked");
                                                      print(value);
                                                      if (value ==
                                                          HOST_YOURSELF_ID) {
                                                        parent
                                                                .currentEventData
                                                                .value
                                                                .templateHostID =
                                                            HOST_YOURSELF_ID;
                                                      } else {
                                                        parent
                                                                .currentEventData
                                                                .value
                                                                .templateHostID =
                                                            getKeyMatchingValueFromMap(
                                                                snapshot.data ??
                                                                    {},
                                                                value);
                                                      }
                                                      pprint(parent
                                                          .currentEventData
                                                          .value
                                                          .templateHostID);
                                                    },
                                                    popupProps: const PopupProps
                                                            .menu(
                                                        //showSelectedItems: true,
                                                        showSearchBox: true,
                                                        searchFieldProps:
                                                            TextFieldProps(
                                                                autofocus: true,
                                                                decoration:
                                                                    InputDecoration(
                                                                        focusedBorder:
                                                                            UnderlineInputBorder(
                                                                          // This changes color of line between search field and results
                                                                          borderSide:
                                                                              BorderSide(color: Colors.white),
                                                                        ),
                                                                        focusColor:
                                                                            Colors
                                                                                .white,
                                                                        hintText:
                                                                            "Search..."))),
                                                    items: sortedValuesList,
                                                    dropdownButtonProps:
                                                        const DropdownButtonProps(
                                                            color:
                                                                Colors.white),
                                                    dropdownDecoratorProps:
                                                        const DropDownDecoratorProps(
                                                            baseStyle: TextStyle(
                                                                color: Colors
                                                                    .white),
                                                            dropdownSearchDecoration:
                                                                InputDecoration(
                                                              /*helperText:
                                                                  "Leave empty to host as yourself. Press the x to unselect.",*/
                                                              hintText:
                                                                  "No Host Chosen",
                                                              labelStyle: TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                              enabledBorder:
                                                                  UnderlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                              disabledBorder:
                                                                  UnderlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                            )),
                                                  );
                                                }),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return loader;
                                  }
                                },
                              ), // Continue Here After DropDownSearch
                        SizedBox(
                            height: MediaQuery.of(context).size.height / 50),
                        parent.eventIDToBeEdited != null
                            ? Center(
                                child: Text(
                                  "EventID: ${parent.eventIDToBeEdited}",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.height /
                                              50),
                                ),
                              )
                            : TextFormField(
                                initialValue:
                                    parent.currentEventData.value.eventid,
                                onChanged: (value) async {
                                  eventidvalidator.value =
                                      parent.validateEventIDFieldLight(value);
                                  parent.currentEventData.value.eventid = value;
                                },
                                onFieldSubmitted: (value) async {
                                  eventidvalidator.value = await parent
                                      .validateEventIDFieldDB(value);
                                  parent.currentEventData.value.eventid = value;
                                },
                                onSaved: (newValue) async {
                                  eventidvalidator.value = await parent
                                      .validateEventIDFieldDB(newValue ?? "");
                                  parent.currentEventData.value.eventid =
                                      newValue ?? "";
                                },
                                style: const TextStyle(color: Colors.white),
                                cursorColor: Colors.white,
                                decoration: InputDecoration(
                                  icon: Icon(
                                      eventidvalidatedstring != null
                                          ? Icons.highlight_off
                                          : Icons.check_circle_outline,
                                      color: Colors.white),
                                  labelText: "Event-ID",
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
                                  hintText: "only letters and numbers allowed.",
                                  hintStyle:
                                      const TextStyle(color: Colors.grey),
                                ),
                              ),
                        parent.eventIDToBeEdited == null
                            ? SizedBox(height: 0)
                            : Text(
                                eventidvalidatedstring ?? "",
                                style: const TextStyle(color: Colors.grey),
                              )
                      ]));
                }),
            ValueListenableBuilder(
                valueListenable: isEventTitleEmpty,
                builder: ((context, eventTitleEmpty, child) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height / 100,
                        horizontal: MediaQuery.of(context).size.width / 50),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: parent.currentEventData.value.title,
                          onChanged: (value) async {
                            isEventTitleEmpty.value = value.isEmpty;
                            parent.currentEventData.value.title = value;
                          },
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            icon: Icon(
                                eventTitleEmpty
                                    ? Icons.highlight_off
                                    : Icons.check_circle_outline,
                                color: Colors.white),
                            labelText: "Event Title",
                            labelStyle: const TextStyle(color: Colors.white),
                            hintText: "Give your event a title!",
                            hintStyle: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        Text(
                          eventTitleEmpty ? "Can't be empty" : "",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const Divider(color: Color.fromARGB(255, 66, 66, 66)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Card(
                                color: cl.lighterGrey,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                            MediaQuery.of(context)
                                                .size
                                                .height) /
                                        75,
                                    side: const BorderSide(
                                      width: 1,
                                      color: Color.fromARGB(26, 255, 255, 255),
                                    )),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    TextButton(
                                        onPressed: () async {
                                          DateTime? initialDate;
                                          if (parent.currentEventData.value
                                                  .begin !=
                                              null) {
                                            initialDate = DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    parent
                                                        .currentEventData
                                                        .value
                                                        .begin!
                                                        .millisecondsSinceEpoch);
                                          }
                                          DateTime? picked_date = await cw
                                              .pick_date(context, initialDate);
                                          print(picked_date);
                                          if (picked_date != null) {
                                            parent.currentEventData.value
                                                    .begin =
                                                Timestamp.fromDate(picked_date);
                                            pprint(parent
                                                .currentEventData.value.begin);
                                            parent.currentEventData
                                                .notifyListeners();
                                          }
                                        },
                                        child: const Text(
                                          "Pick begin date",
                                          style: TextStyle(color: Colors.white),
                                        )),
                                    TextButton(
                                        onPressed: () async {
                                          TimeOfDay? initialTime;
                                          if (parent.currentEventData.value
                                                  .begin !=
                                              null) {
                                            initialTime =
                                                TimeOfDay.fromDateTime(DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        parent
                                                            .currentEventData
                                                            .value
                                                            .begin!
                                                            .millisecondsSinceEpoch));
                                          }

                                          TimeOfDay? picked_time = await cw
                                              .pick_time(context, initialTime);
                                          if (picked_time != null) {
                                            DateTime currentTime = parent
                                                        .currentEventData
                                                        .value
                                                        .begin ==
                                                    null
                                                ? DateTime.now()
                                                : parent.currentEventData.value
                                                    .begin!
                                                    .toDate();
                                            parent.currentEventData.value
                                                    .begin =
                                                Timestamp.fromDate(DateTime(
                                                    currentTime.year,
                                                    currentTime.month,
                                                    currentTime.day,
                                                    picked_time.hour,
                                                    picked_time.minute));
                                            parent.currentEventData
                                                .notifyListeners();
                                          }
                                        },
                                        child: const Text(
                                          "Pick begin time",
                                          style: TextStyle(color: Colors.white),
                                        ))
                                  ],
                                )),
                            const VerticalDivider(
                              color: Color.fromARGB(255, 232, 232, 232),
                              thickness: 2,
                            ),
                            Card(
                                color: cl.lighterGrey,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                            MediaQuery.of(context)
                                                .size
                                                .height) /
                                        75,
                                    side: const BorderSide(
                                      width: 1,
                                      color: Color.fromARGB(26, 255, 255, 255),
                                    )),
                                child: Column(
                                  children: [
                                    TextButton(
                                        onPressed: () async {
                                          DateTime? initialDate;
                                          if (parent
                                                  .currentEventData.value.end !=
                                              null) {
                                            initialDate = DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    parent
                                                        .currentEventData
                                                        .value
                                                        .end!
                                                        .millisecondsSinceEpoch);
                                          }

                                          DateTime? picked_date = await cw
                                              .pick_date(context, initialDate);
                                          if (picked_date != null) {
                                            parent.currentEventData.value.end =
                                                Timestamp.fromDate(picked_date);
                                            pprint(timestamp2readablestamp(
                                                parent.currentEventData.value
                                                    .end));
                                            parent.currentEventData
                                                .notifyListeners();
                                          }
                                        },
                                        child: const Text(
                                          "Pick end date",
                                          style: TextStyle(color: Colors.white),
                                        )),
                                    TextButton(
                                        onPressed: () async {
                                          TimeOfDay initialTime =
                                              TimeOfDay.fromDateTime(DateTime
                                                  .fromMillisecondsSinceEpoch(parent
                                                      .currentEventData
                                                      .value
                                                      .begin!
                                                      .millisecondsSinceEpoch));

                                          TimeOfDay? picked_time = await cw
                                              .pick_time(context, initialTime);
                                          if (picked_time != null) {
                                            DateTime currentTime = parent
                                                        .currentEventData
                                                        .value
                                                        .end ==
                                                    null
                                                ? DateTime.now()
                                                : parent
                                                    .currentEventData.value.end!
                                                    .toDate();
                                            parent.currentEventData.value.end =
                                                Timestamp.fromDate(DateTime(
                                                    currentTime.year,
                                                    currentTime.month,
                                                    currentTime.day,
                                                    picked_time.hour,
                                                    picked_time.minute));
                                            parent.currentEventData
                                                .notifyListeners();
                                          }
                                        },
                                        child: const Text(
                                          "Pick end time",
                                          style: TextStyle(color: Colors.white),
                                        ))
                                  ],
                                )),
                          ],
                        ),
                        ValueListenableBuilder(
                          valueListenable: parent.currentEventData,
                          builder: (context, eventData, child) {
                            return eventData.begin == null &&
                                    eventData.end == null
                                ? Text(
                                    "If you dont provide at least 'end date', your event will not be visible in default calendar",
                                    style: TextStyle(color: Colors.grey))
                                : Text(
                                    "Begins at: ${timestamp2readablestamp(eventData.begin)}",
                                    style: TextStyle(color: Colors.white),
                                  );
                            ;
                          },
                        ),
                        ValueListenableBuilder(
                          valueListenable: parent.currentEventData,
                          builder: (context, event, child) {
                            return event.end == null
                                ? SizedBox(height: 0)
                                : Text(
                                    "Ends at: ${timestamp2readablestamp(event.end)}",
                                    style: TextStyle(color: Colors.white),
                                  );
                          },
                        )
                      ],
                    ),
                  );
                })),
            TextFormField(
              initialValue: parent.currentEventData.value.locationname,
              onChanged: (value) {
                parent.currentEventData.value.locationname = value;
              },
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                icon: Icon(Icons.location_on, color: Colors.white),
                labelText: "Event Location",
                labelStyle: TextStyle(color: Colors.white),
                hintText: "Describe where to find your event",
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
            TextFormField(
              initialValue: parent.currentEventData.value.minAge.toString(),
              onChanged: (value) async {
                parent.currentEventData.value.minAge = int.parse(value);
              },
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                icon: Icon(Icons.warning, color: Colors.white),
                labelText: "Min. Age",
                labelStyle: const TextStyle(color: Colors.white),
                hintText: "Put in the required age for your event!",
                hintStyle: const TextStyle(color: Colors.grey),
              ),
            ),
            TextFormField(
              initialValue: parent.currentEventData.value.genre,
              onChanged: (value) async {
                parent.currentEventData.value.genre = value;
              },
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                icon: Icon(Icons.music_note, color: Colors.white),
                labelText: "Event Genre",
                labelStyle: const TextStyle(color: Colors.white),
                hintText: "Describe the genre of your Event!",
                hintStyle: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ));
  }
}

class AddLinkButton extends StatelessWidget {
  String label = "";
  String url = "";
  EventCreationScreen parent;
  AddLinkButton({super.key, required this.parent});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: cl.darkerGrey,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusDirectional.circular(8.0))),
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) => LinkCreateDialog(parent: parent));
        },
        child: Text("Add new link"));
  }
}

class LinkEditingScreen extends StatelessWidget {
  EventCreationScreen parent;
  LinkEditingScreen({Key? key, required this.parent}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: parent.currentEventData,
        builder: (context, eventdata, foo) {
          return ListView(
            padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.height / 50,
                horizontal: MediaQuery.of(context).size.width / 50),
            children: parent.getLinkList(
                context, dbc.linkListFromMap(eventdata.links ?? {})),
          );
        });
  }
}

class LinkListCard extends StatelessWidget {
  dbc.Link link;
  EventCreationScreen parent;
  LinkListCard({required this.link, required this.parent});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        showDialog(
            context: context,
            builder: ((context) => LinkEditDialog(link: link, parent: parent)));
      },
      tileColor: Colors.black,
      title: Center(
          child: Text(link.title, style: TextStyle(color: Colors.white))),
    );
  }
}

class LinkCreateDialog extends StatelessWidget {
  String label = "";
  String url = "";
  EventCreationScreen parent;
  LinkCreateDialog({super.key, required this.parent});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(MediaQuery.of(context).size.width / 50),
          side: BorderSide(color: Color.fromARGB(255, 60, 60, 60))),
      backgroundColor: cl.darkerGrey,
      title: Text("Enter Link Data", style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            style: TextStyle(color: Colors.white),
            autofocus: true,
            decoration: InputDecoration(
                disabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white)),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white)),
                hintText: "Label, e.g 'Instagram'",
                hintStyle: TextStyle(color: Colors.white)),
            cursorColor: Colors.white,
            onChanged: (value) {
              label = value;
            },
            maxLines: null,
          ),
          TextFormField(
            autofocus: true,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white)),
                focusColor: Colors.white,
                hintText: "URL",
                hintStyle: TextStyle(color: Colors.white)),
            cursorColor: Colors.white,
            onChanged: (value) {
              url = value;
            },
            maxLines: null,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () {
              List<dbc.Link> formerlist = dbc
                  .linkListFromMap(parent.currentEventData.value.links ?? {});
              formerlist.add(dbc.Link(title: label, url: url));
              Navigator.of(context).pop();
              parent.currentEventData.value.links =
                  dbc.mapFromLinkList(formerlist);
              parent.currentEventData.notifyListeners();
            },
            child: Text("Add link to event",
                style: TextStyle(color: Colors.white)))
      ],
    );
  }
}

class LinkEditDialog extends StatelessWidget {
  dbc.Link link;
  EventCreationScreen parent;
  LinkEditDialog({super.key, required this.link, required this.parent});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cl.darkerGrey,
      title: Text("Edit Link", style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            initialValue: link.title,
            autofocus: true,
            decoration: InputDecoration(
                hintText: "Label, e.g 'Instagram'",
                hintStyle: TextStyle(color: Colors.white)),
            onChanged: (value) {
              link.title = value;
            },
            maxLines: null,
          ),
          TextFormField(
            initialValue: link.url,
            autofocus: true,
            decoration: InputDecoration(
                hintText: "URL", hintStyle: TextStyle(color: Colors.white)),
            onChanged: (value) {
              link.url = value;
            },
            maxLines: null,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
            onPressed: () {
              List<dbc.Link> formerlist = dbc
                  .linkListFromMap(parent.currentEventData.value.links ?? {});
              Navigator.of(context).pop();
              parent.currentEventData.value.links =
                  dbc.mapFromLinkList(parent.editLinkInList(formerlist, link));
            },
            child: Text("Save changes to Link",
                style: TextStyle(color: Colors.white)))
      ],
    );
  }
}

class UploadEventDialog extends StatelessWidget {
  EventCreationScreen parent;
  UploadEventDialog({super.key, required this.parent});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: parent.is_awaiting_upload,
        builder: (context, uploading, foo) {
          return AlertDialog(
            backgroundColor: cl.darkerGrey,
            title: uploading
                ? null
                : Text("Finished?", style: TextStyle(color: Colors.white)),
            content: uploading
                ? Center(child: loader)
                : Text(
                    "Post the event?\nYou can also save your event to publish later.",
                    style: TextStyle(color: Colors.white)),
            actions: uploading
                ? null
                : [
                    TextButton(
                      child: Text("Discard",
                          style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        uploading = false;
                        parent.block_upload = false;
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                        onPressed: () {
                          dbc.Event newEventData =
                              parent.currentEventData.value;
                          newEventData.status = EventStatus.draft.name;
                          parent.uploadEvent(newEventData, context);
                        },
                        child: Text("Save(TBA)",
                            style: TextStyle(color: Colors.white))),
                    TextButton(
                        onPressed: () {
                          parent.uploadEvent(
                              parent.currentEventData.value, context);
                        },
                        child: Text("Publish",
                            style: TextStyle(color: Colors.white))),
                  ],
          );
        });
  }
}

class UploadingErrorDialog extends StatelessWidget {
  final List<Widget> errormessages;
  EventCreationScreen parent;
  UploadingErrorDialog(
      {super.key, required this.errormessages, required this.parent});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cl.darkerGrey,
      title:
          Text("Couldn't upload Event", style: TextStyle(color: Colors.white)),
      content: FutureBuilder(
          future: parent.validateUpload(),
          builder: (context, snapshot) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: errormessages,
            );
          }),
    );
  }
}

class MediaEditingScreen extends StatelessWidget {
  EventCreationScreen parent;
  MediaEditingScreen({super.key, required this.parent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width / 30,
          vertical: MediaQuery.of(context).size.height / 40),
      child: db.doIHavePermission(GlobalPermission.MANAGE_EVENTS)
          ? Column(
              children: [
                const Text(
                  "The Icon is the image shown in the calendar overview.",
                  maxLines: 23,
                  style: TextStyle(color: Colors.white),
                ),
                TextFormField(
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  initialValue: parent.currentEventData.value.icon,
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(
                    /*icon: Icon(
                eventidvalidatedstring != null
                  ? Icons.highlight_off
                  : Icons.check_circle_outline,
                color: Colors.white),*/
                    labelText: "Location of Icon Image",
                    labelStyle: TextStyle(color: Colors.white),
                    hintText: "If left empty defaults to host's pfp.",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  onChanged: (value) {
                    String newS = value.replaceAll(
                        "gs://ravestreammobileapp.appspot.com/", "");
                    parent.currentEventData.value.icon =
                        newS.isEmpty ? null : newS;
                  },
                ),
                const Text(
                  "The Flyer is the image shown when users click on your event in the calendar",
                  maxLines: 23,
                  style: TextStyle(color: Colors.white),
                ),
                TextFormField(
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  initialValue: parent.currentEventData.value.icon,
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(
                    /*icon: Icon(
                eventidvalidatedstring != null
                  ? Icons.highlight_off
                  : Icons.check_circle_outline,
                color: Colors.white),*/
                    labelText: "Location of Flyer Image",
                    labelStyle: TextStyle(color: Colors.white),
                    hintText: "If left empty defaults to icon",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  onChanged: (value) {
                    parent.currentEventData.value.flyer = value.replaceAll(
                        "gs://ravestreammobileapp.appspot.com/", "");
                  },
                )
              ],
            )
          : Placeholder(),
    );
  }
}
