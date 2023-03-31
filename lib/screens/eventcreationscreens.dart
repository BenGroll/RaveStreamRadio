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

/// What text to show in the dropdown to host as yourself
const HOST_YOURSELF_ID = "Host as yourself.";

/// Screens
enum Screen { general, description, links, media }

/// Loading Animation
const loader = CircularProgressIndicator(color: Colors.white);

bool isOpenedByRSRTeamMember = false;
ValueNotifier<Screen> current_screen = ValueNotifier<Screen>(Screen.general);
ValueNotifier<bool> eventtitleIsEmpty = ValueNotifier<bool>(true);
ValueNotifier<bool> is_awaiting_upload = ValueNotifier(false);
bool block_upload = false;
bool is_overriding_existing_event = false;

ValueNotifier<dbc.Event> currentEventData = ValueNotifier<dbc.Event>(dbc.Event(
    eventid: "", title: "", locationname: "", description: "", links: {}));
//String? templateHostID;

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
        await db.db.doc("templatehosts/${toValidate.templateHostID}").get();
    if (!hostDocRef.exists) {
      errormessages
          .add("Templatehost ${toValidate.templateHostID} does not exist.");
    }
  }
  if (is_overriding_existing_event) {
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
        return GeneralSettingsPage();
      }
    case Screen.description:
      {
        return DescriptionEditingPage(onChange: (String value) {
          currentEventData.value.description = value;
        });
      }
    case Screen.links:
      {
        return const LinkEditingScreen();
      }
    case Screen.media:
      {
        return const MediaEditingScreen();
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

class EventCreationScreen extends StatelessWidget {
  final String? eventIDToBeEdited;
  EventCreationScreen({super.key, this.eventIDToBeEdited = null});
  @override
  Widget build(BuildContext context) {
    current_screen.value = Screen.general;
    eventtitleIsEmpty.value = true;
    currentEventData.value = dbc.Event(
        eventid: "", title: "", locationname: "", description: "", links: {});
    // Add decision tree
    if (currently_loggedin_as.value == null) {
      return const cw.ErrorScreen(
          errormessage: "You have to be logged in to create or edit events.");
    } else {
      //String docref = "${branchPrefix}users/${currently_loggedin_as.value!.username}";
      currentEventData.value.hostreference = db.db
          .doc("${branchPrefix}users/${currently_loggedin_as.value!.username}");
      if (eventIDToBeEdited == null) {
        // Check if user is calendar manager
        isOpenedByRSRTeamMember =
            db.doIHavePermission(GlobalPermission.MANAGE_EVENTS);
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
                                          const UploadEventDialog());
                                } else {
                                  showDialog(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (context) => UploadingErrorDialog(
                                        errormessages: errorcontent),
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
                        GeneralSettingsPage(),
                        DescriptionEditingPage(onChange: (String value) {
                          currentEventData.value.description = value;
                        }),
                        LinkEditingScreen(),
                        MediaEditingScreen()
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
                    is_overriding_existing_event = true;
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
                                isOpenedByRSRTeamMember = db.doIHavePermission(
                                    GlobalPermission.MANAGE_EVENTS);
                                return ValueListenableBuilder(
                                    valueListenable: current_screen,
                                    builder: (context, screen, child) {
                                      return Scaffold(
                                          backgroundColor: cl.darkerGrey,
                                          appBar: AppBar(
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
                                                                const UploadEventDialog());
                                                      } else {
                                                        showDialog(
                                                          barrierDismissible:
                                                              true,
                                                          context: context,
                                                          builder: (context) =>
                                                              UploadingErrorDialog(
                                                                  errormessages:
                                                                      errorcontent),
                                                        );
                                                      }
                                                    }
                                                  },
                                                  child: Text("Upload",
                                                      style: TextStyle(
                                                          color: Colors.white)))
                                            ],
                                          ),
                                          body: mapScreenToWidget(screen));
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
  GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    eventidvalidator.value = "!EventID can't be empty";
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
                        !isOpenedByRSRTeamMember
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
                                                    currentEventData,
                                                builder: (context,
                                                    eventDatacurrent, foo) {
                                                  print(
                                                      "NewBuild: ${currentEventData.value.templateHostID}");
                                                  return DropdownSearch(
                                                    selectedItem:
                                                        eventDatacurrent
                                                            .templateHostID,
                                                    onChanged: (value) {
                                                      currentEventData.value
                                                              .templateHostID =
                                                          getKeyMatchingValueFromMap(
                                                              snapshot.data ??
                                                                  {},
                                                              value);
                                                      /*templateHostID =
                                                        getKeyMatchingValueFromMap(
                                                            snapshot.data ?? {}, value);*/
                                                      print(currentEventData
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

                        is_overriding_existing_event
                            ? Text(
                                "EventID: ${currentEventData.value.eventid}",
                                style: TextStyle(color: Colors.white),
                              )
                            : TextFormField(
                                initialValue: currentEventData.value.eventid,
                                onChanged: (value) async {
                                  print(
                                      "onCH tH: ${currentEventData.value.templateHostID}");
                                  eventidvalidator.value =
                                      validateEventIDFieldLight(value);
                                  print(
                                      "onCH tH2: ${currentEventData.value.templateHostID}");
                                  currentEventData.value.eventid = value;
                                },
                                onFieldSubmitted: (value) async {
                                  print(
                                      "onFS tH: ${currentEventData.value.templateHostID}");
                                  eventidvalidator.value =
                                      await validateEventIDFieldDB(value);
                                  print(
                                      "onFS tH2: ${currentEventData.value.templateHostID}");
                                  currentEventData.value.eventid = value;
                                },
                                onSaved: (newValue) async {
                                  print(
                                      "onS tH: ${currentEventData.value.templateHostID}");
                                  eventidvalidator.value =
                                      await validateEventIDFieldDB(
                                          newValue ?? "");
                                  print(
                                      "onS tH2: ${currentEventData.value.templateHostID}");
                                  currentEventData.value.eventid =
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
                        is_overriding_existing_event
                            ? SizedBox(height: 0)
                            : Text(
                                eventidvalidatedstring ?? "",
                                style: const TextStyle(color: Colors.grey),
                              )
                      ]));
                }),
            ValueListenableBuilder(
                valueListenable: eventtitleIsEmpty,
                builder: ((context, isEventTitleEmpty, child) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height / 100,
                        horizontal: MediaQuery.of(context).size.width / 50),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: currentEventData.value.title,
                          onChanged: (value) async {
                            eventtitleIsEmpty.value = value.isEmpty;
                            currentEventData.value.title = value;
                          },
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            icon: Icon(
                                isEventTitleEmpty
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
                          isEventTitleEmpty ? "Can't be empty" : "",
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
                                          if (currentEventData.value.begin !=
                                              null) {
                                            initialDate = DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    currentEventData
                                                        .value
                                                        .begin!
                                                        .millisecondsSinceEpoch);
                                          }
                                          DateTime? picked_date = await cw
                                              .pick_date(context, initialDate);
                                          if (picked_date != null) {
                                            currentEventData.value.begin =
                                                Timestamp.fromDate(picked_date);
                                            print(currentEventData.value.begin);
                                            currentEventData.notifyListeners();
                                          }
                                        },
                                        child: const Text(
                                          "Pick begin date",
                                          style: TextStyle(color: Colors.white),
                                        )),
                                    TextButton(
                                        onPressed: () async {
                                          TimeOfDay? initialTime;
                                          if (currentEventData.value.begin !=
                                              null) {
                                            initialTime =
                                                TimeOfDay.fromDateTime(DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        currentEventData
                                                            .value
                                                            .begin!
                                                            .millisecondsSinceEpoch));
                                          }

                                          TimeOfDay? picked_time = await cw
                                              .pick_time(context, initialTime);
                                          if (picked_time != null) {
                                            DateTime currentTime =
                                                currentEventData.value.begin ==
                                                        null
                                                    ? DateTime.now()
                                                    : currentEventData
                                                        .value.begin!
                                                        .toDate();
                                            currentEventData.value.begin =
                                                Timestamp.fromDate(DateTime(
                                                    currentTime.year,
                                                    currentTime.month,
                                                    currentTime.day,
                                                    picked_time.hour,
                                                    picked_time.minute));
                                            currentEventData.notifyListeners();
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
                                          if (currentEventData.value.end !=
                                              null) {
                                            initialDate = DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    currentEventData.value.end!
                                                        .millisecondsSinceEpoch);
                                          }

                                          DateTime? picked_date = await cw
                                              .pick_date(context, initialDate);
                                          if (picked_date != null) {
                                            currentEventData.value.end =
                                                Timestamp.fromDate(picked_date);
                                            print(timestamp2readablestamp(
                                                currentEventData.value.end));
                                            currentEventData.notifyListeners();
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
                                                  .fromMillisecondsSinceEpoch(
                                                      currentEventData
                                                          .value
                                                          .begin!
                                                          .millisecondsSinceEpoch));

                                          TimeOfDay? picked_time = await cw
                                              .pick_time(context, initialTime);
                                          if (picked_time != null) {
                                            DateTime currentTime =
                                                currentEventData.value.end ==
                                                        null
                                                    ? DateTime.now()
                                                    : currentEventData
                                                        .value.end!
                                                        .toDate();
                                            currentEventData.value.end =
                                                Timestamp.fromDate(DateTime(
                                                    currentTime.year,
                                                    currentTime.month,
                                                    currentTime.day,
                                                    picked_time.hour,
                                                    picked_time.minute));
                                            currentEventData.notifyListeners();
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
                          valueListenable: currentEventData,
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
                          valueListenable: currentEventData,
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
              initialValue: currentEventData.value.locationname,
              onChanged: (value) {
                currentEventData.value.locationname = value;
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
          ],
        ));
  }
}

List<Widget> getLinkList(BuildContext context, List<dbc.Link> links) {
  List<Widget> linkso = [];
  links.forEach((element) {
    linkso.add(LinkListCard(link: element));
  });
  linkso.add(AddLinkButton());
  return linkso;
}

class AddLinkButton extends StatelessWidget {
  String label = "";
  String url = "";
  AddLinkButton({super.key});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:cl.darkerGrey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadiusDirectional.circular(8.0))),
        onPressed: () {
          showDialog(
              context: context, builder: (context) => LinkCreateDialog());
        },
        child: Text("Add new link"));
  }
}

class LinkEditingScreen extends StatelessWidget {
  const LinkEditingScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: currentEventData,
        builder: (context, eventdata, foo) {
          return ListView(
            padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.height / 50,
                horizontal: MediaQuery.of(context).size.width / 50),
            children: getLinkList(
                context, dbc.linkListFromMap(eventdata.links ?? {})),
          );
        });
  }
}

class LinkListCard extends StatelessWidget {
  dbc.Link link;
  LinkListCard({required this.link});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        showDialog(
            context: context,
            builder: ((context) => LinkEditDialog(link: link)));
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
  LinkCreateDialog({super.key});

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
              List<dbc.Link> formerlist =
                  dbc.linkListFromMap(currentEventData.value.links ?? {});
              formerlist.add(dbc.Link(title: label, url: url));
              Navigator.of(context).pop();
              currentEventData.value.links = dbc.mapFromLinkList(formerlist);
              currentEventData.notifyListeners();
            },
            child: Text("Add link to event",
                style: TextStyle(color: Colors.white)))
      ],
    );
  }
}

class LinkEditDialog extends StatelessWidget {
  dbc.Link link;
  LinkEditDialog({super.key, required this.link});
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
              List<dbc.Link> formerlist =
                  dbc.linkListFromMap(currentEventData.value.links ?? {});
              Navigator.of(context).pop();
              currentEventData.value.links =
                  dbc.mapFromLinkList(editLinkInList(formerlist, link));
            },
            child: Text("Save changes to Link",
                style: TextStyle(color: Colors.white)))
      ],
    );
  }
}

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

Future uploadEvent(dbc.Event event, BuildContext context) async {
  is_awaiting_upload.value = true;
  if (event.templateHostID != null && event.templateHostID!.isNotEmpty) {
    event.hostreference = null;
  }
  await db.uploadEventToDatabase(event);
  await Future.delayed(Duration(seconds: 2));
  kIsWeb ? Beamer.of(context).popToNamed("/") : Navigator.of(context).pop();
  if (kIsWeb) {
    is_overriding_existing_event
        ? ScaffoldMessenger.of(context)
            .showSnackBar(cw.hintSnackBar("Event edited successfully!"))
        : ScaffoldMessenger.of(context)
            .showSnackBar(cw.hintSnackBar("Event created successfully!"));
  }
  currently_selected_screen.notifyListeners();
  is_awaiting_upload.value = false;
  Navigator.of(context).pop();
}

class UploadEventDialog extends StatelessWidget {
  const UploadEventDialog({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: is_awaiting_upload,
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
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                        onPressed: () {
                          dbc.Event newEventData = currentEventData.value;
                          newEventData.status = EventStatus.draft.name;
                          uploadEvent(newEventData, context);
                        },
                        child: Text("Save(TBA)",
                            style: TextStyle(color: Colors.white))),
                    TextButton(
                        onPressed: () {
                          uploadEvent(currentEventData.value, context);
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
  const UploadingErrorDialog({super.key, required this.errormessages});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cl.darkerGrey,
      title:
          Text("Couldn't upload Event", style: TextStyle(color: Colors.white)),
      content: FutureBuilder(
          future: validateUpload(),
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
  const MediaEditingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width / 30,
          vertical: MediaQuery.of(context).size.height / 40),
      child: isOpenedByRSRTeamMember
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
                  initialValue: currentEventData.value.icon,
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
                    currentEventData.value.icon = value.replaceAll(
                        "gs://ravestreammobileapp.appspot.com/", "");
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
                  initialValue: currentEventData.value.icon,
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
                    currentEventData.value.flyer = value.replaceAll(
                        "gs://ravestreammobileapp.appspot.com/", "");
                  },
                )
              ],
            )
          : Placeholder(),
    );
  }
}
