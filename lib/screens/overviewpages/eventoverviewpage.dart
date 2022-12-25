import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/commonwidgets.dart';
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/filesystem.dart';
import 'package:ravestreamradioapp/linkbuttons.dart';
import 'package:ravestreamradioapp/screens/homescreen.dart' as home;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:ravestreamradioapp/shared_state.dart';

ValueNotifier<Map<String, bool>?> eventUserSpecificData =
    ValueNotifier<Map<String, bool>?>(null);

class EventOverviewPage extends StatelessWidget {
  final String eventid;
  EventOverviewPage(this.eventid);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: db.getEvent(eventid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.done) {
            if (snap.data != null) {
              dbc.Event event = snap.data ?? dbc.demoEvent;
              return SafeArea(
                minimum: EdgeInsets.fromLTRB(
                    0, MediaQuery.of(context).size.height / 50, 0, 0),
                child: FutureBuilder(
                    future: db.getEventUserspecificData(
                        event, currently_loggedin_as.value),
                    builder: (context, snapshot) {
                      //print(stringToTextSpanList("Hello Friends!\n Lol"));
                      if (snapshot.connectionState == ConnectionState.done) {
                        eventUserSpecificData.value = snapshot.data;
                        return ValueListenableBuilder(
                            valueListenable: eventUserSpecificData,
                            builder: (context, bar, foo) {
                              List<Widget> linkButtons = [];
                              event.links?.forEach((key, value) {
                                if (key != "sales") {
                                  linkButtons.add(UrlLinkButton(value, key,
                                      const TextStyle(color: Colors.grey)));
                                }
                              });
                              return Scaffold(
                                backgroundColor: cl.nearly_black,
                                appBar: AppBar(
                                  centerTitle: true,
                                  title: Text("Event: ${event.eventid}"),
                                  actions: [
                                    currently_loggedin_as.value == null
                                        ? const SizedBox()
                                        : IconButton(
                                            onPressed: () async {
                                              List<DocumentReference>
                                                  saved_events =
                                                  currently_loggedin_as
                                                      .value!.saved_events;
                                              if (eventUserSpecificData.value![
                                                      "user_has_saved"] ??
                                                  false) {
                                                saved_events.remove(db.db.doc(
                                                    "${branchPrefix}events/${event.eventid}"));
                                              } else {
                                                saved_events.add(db.db.doc(
                                                    "${branchPrefix}events/${event.eventid}"));
                                              }
                                              Map<String, dynamic>
                                                  currentUserData =
                                                  currently_loggedin_as.value!
                                                      .toMap();
                                              currentUserData["saved_events"] =
                                                  saved_events;
                                              db.db
                                                  .doc(
                                                      "${branchPrefix}users/${currently_loggedin_as.value!.username}")
                                                  .set(currentUserData);
                                              currently_loggedin_as.value!
                                                  .saved_events = saved_events;
                                              eventUserSpecificData.value =
                                                  await db
                                                      .getEventUserspecificData(
                                                          event,
                                                          currently_loggedin_as
                                                              .value);
                                            },
                                            icon: eventUserSpecificData.value![
                                                        "user_has_saved"] ??
                                                    false
                                                ? const Icon(Icons.favorite)
                                                : const Icon(Icons
                                                    .favorite_border_outlined)),
                                  ],
                                ),
                                body: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.of(context).size.width /
                                              30),
                                  child: ListView(
                                    children: [
                                      Center(
                                          child: EventTitle(
                                              event: event,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .height /
                                                          20))),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          event.locationname != null
                                              ? Text(event.locationname ?? "")
                                              : const SizedBox(height: 0),
                                        ],
                                      ),
                                      Row(children: [
                                        Expanded(
                                            flex: 3,
                                            child: AspectRatio(
                                                aspectRatio: 1,
                                                child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                30),
                                                    child: FutureImageBuilder(
                                                        futureImage:
                                                            getEventIcon(
                                                                event))))),
                                      ]),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            const Text("by",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                            buildLinkButtonFromRef(
                                                event.hostreference,
                                                TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .height /
                                                          45,
                                                )),
                                          ],
                                        ),
                                      ),
                                      const Divider(
                                          color:
                                              Color.fromARGB(255, 66, 66, 66)),
                                      event.description != null
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: RichText(
                                                  maxLines: 50,
                                                  softWrap: true,
                                                  text: TextSpan(
                                                      children:
                                                          stringToTextSpanList(
                                                              event.description ??
                                                                  "..."))),
                                            )
                                          : const SizedBox(height: 0),
                                      event.locationname != null
                                          ? Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Expanded(
                                                    child: Divider(
                                                        color: Color.fromARGB(
                                                            255, 66, 66, 66))),
                                                Text("Location",
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                                Expanded(
                                                    child: Divider(
                                                        color: Color.fromARGB(
                                                            255, 66, 66, 66))),
                                              ],
                                            )
                                          : const SizedBox(height: 0),
                                      event.locationname != null
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Card(
                                                  color: cl.nearly_black,
                                                  child: Text(
                                                    event.locationname ??
                                                        "Unknown",
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  )),
                                            )
                                          : const SizedBox(height: 0),
                                      event.age != null
                                          ? Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Expanded(
                                                    child: Divider(
                                                        color: Color.fromARGB(
                                                            255, 66, 66, 66))),
                                                Text("Duration",
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                                Expanded(
                                                    child: Divider(
                                                        color: Color.fromARGB(
                                                            255, 66, 66, 66))),
                                              ],
                                            )
                                          : const SizedBox(height: 0),
                                      event.begin != null || event.end != null
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Card(
                                                  color: cl.nearly_black,
                                                  child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                            "Begin: ${timestamp2readablestamp(event.begin)}",
                                                            style: TextStyle(
                                                                fontSize: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    30,
                                                                color: Colors
                                                                    .white)),
                                                        Text(
                                                            "End:    ${timestamp2readablestamp(event.end)}",
                                                            style: TextStyle(
                                                                fontSize: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    30,
                                                                color: Colors
                                                                    .white))
                                                      ])),
                                            )
                                          : const SizedBox(height: 0),
                                      event.age != null
                                          ? Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Expanded(
                                                    child: Divider(
                                                        color: Color.fromARGB(
                                                            255, 66, 66, 66))),
                                                Text("Age",
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                                Expanded(
                                                    child: Divider(
                                                        color: Color.fromARGB(
                                                            255, 66, 66, 66))),
                                              ],
                                            )
                                          : const SizedBox(height: 0),
                                      event.age != null
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Card(
                                                  color: cl.nearly_black,
                                                  child: Text(
                                                      "Age: ${event.age}",
                                                      style: const TextStyle(
                                                          color:
                                                              Colors.white))),
                                            )
                                          : const SizedBox(),
                                      linkButtons != []
                                          ? Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                  Expanded(
                                                      child: Divider(
                                                          color: Color.fromARGB(
                                                              255,
                                                              66,
                                                              66,
                                                              66))),
                                                  Text("Links",
                                                      style: TextStyle(
                                                          color: Colors.white)),
                                                  Expanded(
                                                      child: Divider(
                                                          color: Color.fromARGB(
                                                              255,
                                                              66,
                                                              66,
                                                              66))),
                                                ])
                                          : const SizedBox(height: 0),
                                      linkButtons != []
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Card(
                                                  color: cl.nearly_black,
                                                  child: Wrap(
                                                    alignment:
                                                        WrapAlignment.center,
                                                    children: linkButtons,
                                                  )),
                                            )
                                          : const SizedBox(),
                                      event.links?.containsKey("sales") ?? false
                                          ? Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                  Expanded(
                                                      child: Divider(
                                                          color: Color.fromARGB(
                                                              255,
                                                              66,
                                                              66,
                                                              66))),
                                                  Text("Ticketlink",
                                                      style: TextStyle(
                                                          color: Colors.white)),
                                                  Expanded(
                                                      child: Divider(
                                                          color: Color.fromARGB(
                                                              255,
                                                              66,
                                                              66,
                                                              66))),
                                                ])
                                          : const SizedBox(height: 0),
                                      event.links?.containsKey("sales") ?? false
                                          ? Center(
                                              child: UrlLinkButton(
                                                  event.links!["sales"] ?? "",
                                                  "Entry/Tickets",
                                                  const TextStyle(
                                                      color: Colors.white)),
                                            )
                                          : const SizedBox(height: 0)
                                    ],
                                  ),
                                ),
                              );
                            });
                      } else {
                        return Scaffold(
                            backgroundColor: cl.nearly_black,
                            body: const CircularProgressIndicator(
                                color: Colors.white));
                      }
                    }),
              );
            } else {
              return Text("Event couldnt be loaded.");
            }
          } else {
            return CircularProgressIndicator(color: Colors.white);
          }
        });
  }
}
