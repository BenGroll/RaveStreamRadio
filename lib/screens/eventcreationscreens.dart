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
ValueNotifier<List<dbc.Link>> added_links = ValueNotifier([]);
ValueNotifier<bool> is_awaiting_upload = ValueNotifier(false);

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
                                  barrierDismissible: false,
                                    context: context,
                                    builder: ((context) {
                                      return ValueListenableBuilder(
                                          valueListenable: is_awaiting_upload,
                                          builder:
                                              (context, awaiting_reload, foo) {
                                            return awaiting_reload ? Dialog(
                                              child: Center(child: CircularProgressIndicator(color: Colors.white, backgroundColor: Colors.black))) : AlertDialog(
                                              backgroundColor: cl.deep_black,
                                              title: const Text("Submit Event?",
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                              content: const Text("",
                                                  maxLines: 3,
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                              actions: [
                                                TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text(
                                                      "No, go back.",
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    )),
                                                TextButton(
                                                    onPressed: () async {
                                                      String?
                                                          idmatchessemantics =
                                                          validateEventIDFieldLight(
                                                              eventidcontent);
                                                      String? idalreadytaken =
                                                          await validateEventIDFieldDB(
                                                              eventidcontent);
                                                      bool eventtitleempty =
                                                          eventtitlecontent
                                                              .isEmpty;
                                                      print(idmatchessemantics);
                                                      print(idalreadytaken);
                                                      print(eventtitleempty);
                                                      if ((idalreadytaken !=
                                                              null) ||
                                                          (idmatchessemantics !=
                                                              null) ||
                                                          eventtitleempty) {
                                                        Navigator.of(context)
                                                            .pop();
                                                        showDialog(
                                                            context: context,
                                                            builder: (context) {
                                                              return Dialog(
                                                                backgroundColor:
                                                                    cl.deep_black,
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    idmatchessemantics ==
                                                                            null
                                                                        ? const SizedBox(
                                                                            height:
                                                                                0)
                                                                        : Text(
                                                                            idmatchessemantics,
                                                                            style:
                                                                                const TextStyle(color: Colors.white)),
                                                                    idalreadytaken ==
                                                                            null
                                                                        ? const SizedBox(
                                                                            height:
                                                                                0)
                                                                        : Text(
                                                                            idalreadytaken,
                                                                            style:
                                                                                const TextStyle(color: Colors.white)),
                                                                    eventtitleempty
                                                                        ? const Text(
                                                                            "EventTitle: Can't be empty",
                                                                            style:
                                                                                TextStyle(color: Colors.white))
                                                                        : const SizedBox(height: 0)
                                                                  ],
                                                                ),
                                                              );
                                                            });
                                                        return;
                                                      }
                                                      dbc.Event uploadEventFile = dbc.Event(
                                                          eventid:
                                                              eventidcontent,
                                                          title:
                                                              eventtitlecontent,
                                                          hostreference: db.db.doc(
                                                              "${branchPrefix}users/${currently_loggedin_as.value!.username}"),
                                                          description:
                                                              descriptiontext
                                                                  .value.isEmpty ? null : descriptiontext.value,
                                                          end: end_date.value == null
                                                              ? null
                                                              : Timestamp.fromDate(DateTime(
                                                                  end_date
                                                                      .value!
                                                                      .year,
                                                                  end_date
                                                                      .value!
                                                                      .month,
                                                                  end_date
                                                                      .value!
                                                                      .day,
                                                                  end_time.value?.hour ?? 0,
                                                                  end_time.value?.minute ?? 0)),
                                                          begin: beginning_date.value == null ? null : Timestamp.fromDate(DateTime(beginning_date.value!.year, beginning_date.value!.month, beginning_date.value!.day, beginning_time.value?.hour ?? 0, beginning_time.value?.minute ?? 0)),
                                                          locationname: eventlocationcontent.isEmpty ? null : eventlocationcontent,
                                                          links: linkListToDBMap(added_links.value));
                                                      uploadEvent(
                                                          uploadEventFile,
                                                          context);
                                                    },
                                                    child: const Text(
                                                        "Yes, submit.",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white))),
                                              ],
                                            );
                                          });
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
                                      ? Text(
                                          "If you dont provide at least 'end date', your event will not be visible in default calendar",
                                          style: TextStyle(color: Colors.grey))
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
            TextFormField(
              onChanged: (value) {
                eventlocationcontent = value;
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
        valueListenable: added_links,
        builder: (context, links, foo) {
          return ListView(
            padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.height / 50,
                horizontal: MediaQuery.of(context).size.width / 50),
            children: getLinkList(context, links),
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
      title: Text("Enter Link Data"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            autofocus: true,
            decoration: InputDecoration(hintText: "Label, e.g 'Instagram'"),
            onChanged: (value) {
              label = value;
            },
            maxLines: null,
          ),
          TextFormField(
            autofocus: true,
            decoration: InputDecoration(hintText: "URL"),
            onChanged: (value) {
              url = value;
            },
            maxLines: null,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
            onPressed: () {
              List<dbc.Link> formerlist = added_links.value;
              formerlist.add(dbc.Link(title: label, url: url));
              Navigator.of(context).pop();
              added_links.value = formerlist;
              added_links.notifyListeners();
            },
            child: Text("Add link to event"))
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
      title: Text("Edit Link"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            initialValue: link.title,
            autofocus: true,
            decoration: InputDecoration(hintText: "Label, e.g 'Instagram'"),
            onChanged: (value) {
              link.title = value;
            },
            maxLines: null,
          ),
          TextFormField(
            initialValue: link.url,
            autofocus: true,
            decoration: InputDecoration(hintText: "URL"),
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
              List<dbc.Link> formerlist = added_links.value;
              Navigator.of(context).pop();
              added_links.value = editLinkInList(added_links.value, link);
              added_links.notifyListeners();
            },
            child: Text("Save changes to Link"))
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
  kIsWeb
      ? Beamer.of(context).popToNamed("/events")
      : Navigator.of(context).pop();
  ScaffoldMessenger.of(context)
      .showSnackBar(cw.hintSnackBar("Event created successfully!"));
  currently_selected_screen.notifyListeners();
  Navigator.of(context).pop();
}
