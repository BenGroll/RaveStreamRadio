import 'dart:io';

import 'package:beamer/beamer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/screens/homescreen.dart';
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/screens/mainscreens/calendar.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:flutter/scheduler.dart';

enum Screen { general, description, links }

ValueNotifier<Screen> current_screen = ValueNotifier<Screen>(Screen.general);
ValueNotifier<bool> eventtitleIsEmpty = ValueNotifier<bool>(true);
ValueNotifier<DateTime?> beginning_date = ValueNotifier<DateTime?>(null);
ValueNotifier<TimeOfDay?> beginning_time = ValueNotifier<TimeOfDay?>(null);
ValueNotifier<DateTime?> end_date = ValueNotifier<DateTime?>(null);
ValueNotifier<TimeOfDay?> end_time = ValueNotifier<TimeOfDay?>(null);
String eventidcontent = "";
String eventtitlecontent = "";
String eventlocationcontent = "";
ValueNotifier<String> descriptiontext = ValueNotifier("");

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
    default:
      return Container();
  }
}

String? validateEventIDFieldLight(String content) {
  if (content.isEmpty) {
    return "Can't be empty.";
  }
  String allowed = "abcdefghijklmnopqrstuvwxyz0123456789";
  bool notallowed = false;
  content.characters.forEach((element) {
    if (!allowed.contains(element)) {
      notallowed = true;
    }
  });
  if (notallowed) {
    return "Only a-z and 0-9 allowed.";
  }

  return null;
}

Future<String?> validateEventIDFieldDB(String content) async {
  bool isFree = await db.db
      .collection("${branchPrefix}events")
      .doc(content)
      .get()
      .then((value) => !value.exists);
  return isFree ? null : "Eventid already taken.";
}

class EventCreationScreen extends StatelessWidget {
  EventCreationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    current_screen.value = Screen.general;
    eventtitleIsEmpty.value = true;
    beginning_date.value = null;
    beginning_time.value = null;
    end_date.value = null;
    end_time.value = null;
    return ValueListenableBuilder(
        valueListenable: current_screen,
        builder: (context, snapshot, foo) {
          return WillPopScope(
              onWillPop: () async {
                return await showDialog(
                    barrierDismissible: false,
                    context: context,
                    // ignore: prefer_const_constructors
                    builder: ((context) => AlertDialog(
                          backgroundColor: cl.deep_black,
                          title: const Text("Leave Event creation?",
                              style: TextStyle(color: Colors.white)),
                          content: const Text("All progress will be lost.",
                              style: TextStyle(color: Colors.white)),
                          actionsAlignment: MainAxisAlignment.spaceEvenly,
                          actions: [
                            TextButton(
                                onPressed: (() {
                                  Navigator.of(context).pop(true);
                                }),
                                child: const Text("Yes, leave.",
                                    style: TextStyle(color: Colors.white))),
                            TextButton(
                                onPressed: (() {
                                  Navigator.of(context).pop(false);
                                }),
                                child: const Text("No, stay.",
                                    style: TextStyle(color: Colors.white)))
                          ],
                        )));
              },
              child: Scaffold(
                appBar: AppBar(
                  centerTitle: true,
                  title: const Text("Create Event"),
                  actions: [
                    IconButton(
                        onPressed: () {
                          switch (current_screen.value) {
                            case Screen.general:
                              {
                                current_screen.value = Screen.description;
                                break;
                              }
                            case Screen.description:
                              {
                                current_screen.value = Screen.links;
                                break;
                              }
                            case Screen.links:
                              {
                                showDialog(
                                    context: context,
                                    builder: ((context) {
                                      return AlertDialog(
                                        backgroundColor: cl.deep_black,
                                        title: const Text("Submit Event?",
                                            style:
                                                TextStyle(color: Colors.white)),
                                        content: const Text("",
                                            maxLines: 3,
                                            style:
                                                TextStyle(color: Colors.white)),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child:
                                                  const Text("No, go back.",style: TextStyle(
                                                    color: Colors.white
                                                  ),)),
                                          TextButton(
                                              onPressed: () async {
                                                /*showDialog(
                                                    barrierDismissible: false,
                                                    context: context,
                                                    builder: ((context) {
                                                      return AlertDialog(
                                                        backgroundColor:
                                                            cl.deep_black,
                                                        title: const Text(
                                                          "Uploading event...",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                      );
                                                    }));*/
                                                await db.uploadEventToDatabase(
                                                    dbc.Event(
                                                  eventid: eventidcontent,
                                                  title: eventtitlecontent,
                                                  hostreference: db.db.doc(
                                                      "${branchPrefix}users/${currently_loggedin_as.value!.username}"),
                                                  description:
                                                      descriptiontext.value,
                                                  end: end_date.value == null
                                                      ? null
                                                      : Timestamp.fromDate(
                                                          DateTime(
                                                              end_date
                                                                  .value!.year,
                                                              end_date
                                                                  .value!.month,
                                                              end_date
                                                                  .value!.day,
                                                              end_time.value
                                                                      ?.hour ??
                                                                  0,
                                                              end_time.value
                                                                      ?.minute ??
                                                                  0)),
                                                  begin: beginning_date
                                                              .value ==
                                                          null
                                                      ? null
                                                      : Timestamp.fromDate(DateTime(
                                                          beginning_date
                                                              .value!.year,
                                                          beginning_date
                                                              .value!.month,
                                                          beginning_date
                                                              .value!.day,
                                                          beginning_time.value
                                                                  ?.hour ??
                                                              0,
                                                          beginning_time.value
                                                                  ?.minute ??
                                                              0)),
                                                ));
                                                Navigator.of(context).pop();
                                                kIsWeb
                                                    ? Beamer.of(context)
                                                        .popToNamed("/events")
                                                    : Navigator.of(context)
                                                        .pop();
                                              },
                                              child: const Text("Yes, submit.",
                                                  style: TextStyle(
                                                      color: Colors.white))),
                                        ],
                                      );
                                    }));
                                break;
                              }
                            default:
                          }
                        },
                        icon: const Icon(Icons.arrow_forward))
                  ],
                ),
                backgroundColor: cl.nearly_black,
                bottomNavigationBar: Theme(
                  data: Theme.of(context).copyWith(canvasColor: cl.deep_black),
                  child: BottomNavigationBar(
                    selectedItemColor: Colors.white,
                    unselectedItemColor: Colors.white,
                    // ignore: prefer_const_literals_to_create_immutables
                    items: [
                      const BottomNavigationBarItem(
                          icon: SizedBox(height: 0), label: "General"),
                      const BottomNavigationBarItem(
                          icon: SizedBox(height: 0), label: "Description"),
                      const BottomNavigationBarItem(
                          icon: SizedBox(height: 0), label: "Links")
                    ],
                    currentIndex: current_screen.value.index,
                    onTap: (value) {
                      current_screen.value = Screen.values[value];
                    },
                  ),
                ),
                body: mapScreenToWidget(current_screen.value),
              ));
        });
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
                        TextFormField(
                          onChanged: (value) async {
                            eventidvalidator.value =
                                validateEventIDFieldLight(value);
                            eventidcontent = value;
                          },
                          onFieldSubmitted: (value) async {
                            eventidvalidator.value =
                                await validateEventIDFieldDB(value);
                            eventidcontent = value;
                          },
                          onSaved: (newValue) async {
                            eventidvalidator.value =
                                await validateEventIDFieldDB(newValue ?? "");
                            eventidcontent = newValue ?? "";
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
                          onChanged: (value) async {
                            eventtitleIsEmpty.value = value.isEmpty;
                            eventtitlecontent = value;
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
                                                  initialDate: DateTime.now(),
                                                  firstDate: DateTime.now(),
                                                  lastDate: DateTime(
                                                    DateTime.now().year + 20,
                                                  ));
                                          if (picked_date != null) {
                                            beginning_date.value = picked_date;
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
                                                  initialTime: const TimeOfDay(
                                                      hour: 0, minute: 0));
                                          if (picked_time != null) {
                                            beginning_time.value = picked_time;
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
                                                  initialDate: DateTime.now(),
                                                  firstDate: DateTime.now(),
                                                  lastDate: DateTime(
                                                      DateTime.now().year +
                                                          20));
                                          if (picked_date != null) {
                                            end_date.value = picked_date;
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
                                                  initialTime: const TimeOfDay(
                                                      hour: 0, minute: 0));
                                          if (picked_time != null) {
                                            end_time.value = picked_time;
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
                          valueListenable: beginning_date,
                          builder: (context, date, child) {
                            return ValueListenableBuilder(
                                valueListenable: beginning_time,
                                builder: (context, time, child) {
                                  return date == null
                                      ? SizedBox(height: 0)
                                      : Text(
                                          "Begins at: ${timestamp2readablestamp(Timestamp.fromDate(DateTime(beginning_date.value!.year, beginning_date.value!.month, beginning_date.value!.day, beginning_time.value?.hour ?? 0, beginning_time.value?.minute ?? 0)))}",
                                          style: TextStyle(color: Colors.white),
                                        );
                                });
                          },
                        ),
                        ValueListenableBuilder(
                          valueListenable: end_date,
                          builder: (context, date, child) {
                            return ValueListenableBuilder(
                                valueListenable: end_time,
                                builder: (context, time, child) {
                                  return date == null
                                      ? SizedBox(height: 0)
                                      : Text(
                                          "Ends at: ${timestamp2readablestamp(Timestamp.fromDate(DateTime(end_date.value!.year, end_date.value!.month, end_date.value!.day, end_time.value?.hour ?? 0, end_time.value?.minute ?? 0)))}",
                                          style: TextStyle(color: Colors.white),
                                        );
                                });
                          },
                        )
                      ],
                    ),
                  );
                })),
                TextFormField()
          ],
        ));
  }
}

class DescriptionEditingPage extends StatelessWidget {
  const DescriptionEditingPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.multiline,
      maxLines: null,
      autofocus: true,
      expands: true,
      cursorColor: Colors.white,
      onChanged: (value) {
        descriptiontext.value = value;
      },
      onSubmitted: (value) {
        descriptiontext.value = value;
      },
    );
  }
}
