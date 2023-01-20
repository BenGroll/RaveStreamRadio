import 'dart:io';

import 'package:beamer/beamer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/screens/homescreen.dart';
import 'package:ravestreamradioapp/commonwidgets.dart';
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/screens/mainscreens/calendar.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:flutter/scheduler.dart';

enum Screen { general, description, links }

const loader = CircularProgressIndicator(color: Colors.white);

bool isOpenedByRSRTeamMember = false;
ValueNotifier<Screen> current_screen = ValueNotifier<Screen>(Screen.general);
ValueNotifier<bool> eventtitleIsEmpty = ValueNotifier<bool>(true);
ValueNotifier<bool> is_awaiting_upload = ValueNotifier(false);
bool block_upload = false;
bool is_overriding_existing_event = false;

ValueNotifier<dbc.Event> currentEventData = ValueNotifier<dbc.Event>(dbc.Event(
    eventid: "", title: "", locationname: "", description: "", links: {}));

/// if it returns an empty list, the validate is without error.
///
/// The List contains the seperate error messages
Future<List<String>> validateUpload() async {
  dbc.Event toValidate = currentEventData.value;
  List<String> errormessages = [];
  if (toValidate.exModHostname == null && toValidate.hostreference == null) {
    errormessages.add("Event needs a host specified.");
  }
  if (validateEventIDFieldLight(currentEventData.value.eventid) != null) {
    errormessages
        .add(validateEventIDFieldLight(currentEventData.value.eventid)!);
  }
  if (is_overriding_existing_event) {
  } else {
    if (await validateEventIDFieldDB(currentEventData.value.eventid) != null) {
      errormessages.add("EventID is taken. Choose another one");
    }
  }
  if (currentEventData.value.title == null ||
      currentEventData.value.title!.isEmpty) {
    errormessages.add("You have to give your event a title.");
  }
  return errormessages;
}

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
        return const DescriptionEditingPage();
      }
    case Screen.links:
      {
        return const LinkEditingScreen();
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
      return const ErrorScreen(
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
          length: 3,
          child: ValueListenableBuilder(
              valueListenable: current_screen,
              builder: (context, screen, child) {
                return Scaffold(
                    backgroundColor: cl.deep_black,
                    appBar: AppBar(
                      bottom: const TabBar(tabs: [
                        Tab(
                          child: Text("1. General"),
                        ),
                        Tab(
                          child: Text("2. Description"),
                        ),
                        Tab(
                          child: Text("3. Links"),
                        ),
                      ]),
                      actions: [
                        TextButton(
                            onPressed: () async {
                              print("HERE");
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
                                print(errorcontent);
                                if (errorcontent.isEmpty) {
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) =>
                                          const UploadEventDialog());
                                } else {
                                  print("HERE2");
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
                        DescriptionEditingPage(),
                        LinkEditingScreen()
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
                  return ErrorScreen(
                      errormessage:
                          "Snapshot from 'db.hasPermissionToEditEvent' has no data.");
                } else {
                  if (canEditSnap.data!) {
                    // User has permission to edit event
                    is_overriding_existing_event = true;
                    return DefaultTabController(
                      length: 3,
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
                                          backgroundColor: cl.deep_black,
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
                                return ErrorScreen(
                                    errormessage:
                                        "Snapshot from 'db.getEvent' has no data or data is null.");
                              }
                            } else {
                              return loader;
                            }
                          }),
                    );
                  } else {
                    return ErrorScreen(
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
                        isOpenedByRSRTeamMember
                            ? SizedBox(height: 0)
                            : TextFormField(
                                initialValue:
                                    currentEventData.value.exModHostname,
                                onChanged: (value) async {
                                  currentEventData.value.exModHostname = value;
                                },
                                onFieldSubmitted: (value) async {
                                  currentEventData.value.exModHostname = value;
                                },
                                onSaved: (newValue) async {
                                  currentEventData.value.exModHostname =
                                      newValue ?? "";
                                },
                                style: const TextStyle(color: Colors.white),
                                cursorColor: Colors.white,
                                decoration: const InputDecoration(
                                  icon: Icon(Icons.perm_identity,
                                      color: Colors.white),
                                  labelText: "Hostname",
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
                                  hintText: "Enter Name of the host",
                                  hintStyle:
                                      const TextStyle(color: Colors.grey),
                                ),
                              ),
                        TextFormField(
                          initialValue: currentEventData.value.eventid,
                          onChanged: (value) async {
                            eventidvalidator.value =
                                validateEventIDFieldLight(value);
                            currentEventData.value.eventid = value;
                          },
                          onFieldSubmitted: (value) async {
                            eventidvalidator.value =
                                await validateEventIDFieldDB(value);
                            currentEventData.value.eventid = value;
                          },
                          onSaved: (newValue) async {
                            eventidvalidator.value =
                                await validateEventIDFieldDB(newValue ?? "");
                            currentEventData.value.eventid = newValue ?? "";
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
                            labelStyle: const TextStyle(color: Colors.white),
                            hintText: "only letters and numbers allowed.",
                            hintStyle: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        Text(
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
                                color: cl.nearly_black,
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
                                          DateTime? picked_date =
                                              await showDatePicker(
                                                  context: context,
                                                  initialDate: currentEventData
                                                              .value.begin ==
                                                          null
                                                      ? DateTime.now()
                                                      : currentEventData
                                                          .value.begin!
                                                          .toDate(),
                                                  firstDate: DateTime.now(),
                                                  lastDate: DateTime(
                                                    DateTime.now().year + 20,
                                                  ));
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
                                          TimeOfDay? picked_time =
                                              await showTimePicker(
                                                  context: context,
                                                  initialTime: currentEventData
                                                              .value.begin ==
                                                          null
                                                      ? const TimeOfDay(
                                                          hour: 0, minute: 0)
                                                      : TimeOfDay.fromDateTime(
                                                          currentEventData
                                                              .value.begin!
                                                              .toDate()));
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
                                color: cl.nearly_black,
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
                                          DateTime? picked_date =
                                              await showDatePicker(
                                                  context: context,
                                                  initialDate: currentEventData
                                                              .value.end ==
                                                          null
                                                      ? DateTime.now()
                                                      : currentEventData
                                                          .value.end!
                                                          .toDate(),
                                                  firstDate: DateTime.now(),
                                                  lastDate: DateTime(
                                                      DateTime.now().year +
                                                          20));
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
                                          TimeOfDay? picked_time =
                                              await showTimePicker(
                                                  context: context,
                                                  initialTime: currentEventData
                                                              .value.end ==
                                                          null
                                                      ? const TimeOfDay(
                                                          hour: 0, minute: 0)
                                                      : TimeOfDay.fromDateTime(
                                                          currentEventData
                                                              .value.end!
                                                              .toDate()));
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
                            print(eventData.begin);
                            print(eventData.end);
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

class DescriptionEditingPage extends StatelessWidget {
  const DescriptionEditingPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: currentEventData.value.description,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.multiline,
      maxLines: null,
      autofocus: true,
      expands: true,
      cursorColor: Colors.white,
      onChanged: (value) {
        currentEventData.value.description = value;
      },
    );
  }
}

List<Widget> getLinkList(BuildContext context, List<dbc.Link> links) {
  List<Widget> linkso = [];
  links.forEach((element) {
    linkso.add(LinkListCard(link: element));
  });
  linkso.add(AddLinkButton());
  print("linkwidgets: $linkso");
  return linkso;
}

class AddLinkButton extends StatelessWidget {
  String label = "";
  String url = "";
  AddLinkButton({super.key});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
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
      backgroundColor: cl.deep_black,
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
              currentEventData.value.links = dbc.mapToLinkList(formerlist);
              currentEventData.notifyListeners();
              print(currentEventData.value.links);
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
      backgroundColor: cl.deep_black,
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
                  dbc.mapToLinkList(editLinkInList(formerlist, link));
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
  await db.uploadEventToDatabase(event);
  await Future.delayed(Duration(seconds: 2));
  kIsWeb
      ? Beamer.of(context).popToNamed("/events")
      : Navigator.of(context).pop();
  is_overriding_existing_event 
  ? ScaffoldMessenger.of(context)
      .showSnackBar(hintSnackBar("Event edited successfully!"))
  : ScaffoldMessenger.of(context)
      .showSnackBar(hintSnackBar("Event created successfully!"));
  currently_selected_screen.notifyListeners();
  Navigator.of(context).pop();
  is_awaiting_upload.value = false;
}

class UploadEventDialog extends StatelessWidget {
  const UploadEventDialog({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: is_awaiting_upload,
        builder: (context, uploading, foo) {
          return AlertDialog(
            backgroundColor: cl.deep_black,
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
                        onPressed: () {},
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
      backgroundColor: cl.deep_black,
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
