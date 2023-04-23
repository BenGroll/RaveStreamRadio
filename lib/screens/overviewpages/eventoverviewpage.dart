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
import 'package:ravestreamradioapp/extensions.dart';

class EventOverviewPage extends StatelessWidget {
  final String eventid;
  ValueNotifier<Map<String, bool>?> eventUserSpecificData =
      ValueNotifier<Map<String, bool>?>(null);
  EventOverviewPage(this.eventid);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: db.getEvent(eventid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.done) {
            if (snap.data != null) {
              ValueNotifier<dbc.Event?> event = ValueNotifier(snap.data);
              return RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(Duration(seconds: 1))
                      .then((value) async {
                    event.value = await db.getEvent(eventid);
                  });
                },
                child: SafeArea(
                  minimum: EdgeInsets.fromLTRB(
                      0, MediaQuery.of(context).size.height / 50, 0, 0),
                  child: event.value == null
                      ? Container(
                          child: Text("Couldn't load Event",
                              style: TextStyle(color: Colors.white)))
                      : ValueListenableBuilder(
                          valueListenable: event,
                          builder: (context, eventdata, foo) {
                            return FutureBuilder(
                                future: db.getEventUserspecificData(
                                    event.value ?? dbc.demoEvent,
                                    currently_loggedin_as.value),
                                builder: (context, snapshot) {
                                  //pprint(stringToTextSpanList("Hello Friends!\n Lol"));
                                  if (snapshot.connectionState ==
                                      ConnectionState.done) {
                                    eventUserSpecificData.value = snapshot.data;
                                    return ValueListenableBuilder(
                                        valueListenable: eventUserSpecificData,
                                        builder: (context, bar, foo) {
                                          List<Widget> linkButtons = [];
                                          event.value!.links
                                              ?.forEach((key, value) {
                                            if (key != "sales") {
                                              linkButtons.add(UrlLinkButton(
                                                  value,
                                                  key,
                                                  const TextStyle(
                                                      color: Colors.grey)));
                                            }
                                          });
                                          return Scaffold(
                                              backgroundColor: cl.darkerGrey,
                                              appBar: AppBar(
                                                backgroundColor: cl.darkerGrey,
                                                centerTitle: true,
                                                title: Text(
                                                    event.value!.eventid,
                                                    maxLines: 2),
                                                actions: [
                                                  ReportButton(
                                                      target:
                                                          "${branchPrefix}events/$eventid"),
                                                  currently_loggedin_as.value ==
                                                          null
                                                      ? const SizedBox()
                                                      : IconButton(
                                                          onPressed: () async {
                                                            List<DocumentReference>
                                                                saved_events =
                                                                currently_loggedin_as
                                                                    .value!
                                                                    .saved_events;
                                                            if (eventUserSpecificData
                                                                        .value![
                                                                    "user_has_saved"] ??
                                                                false) {
                                                              saved_events.remove(
                                                                  db.db.doc(
                                                                      "${branchPrefix}events/${event.value!.eventid}"));
                                                            } else {
                                                              saved_events.add(
                                                                  db.db.doc(
                                                                      "${branchPrefix}events/${event.value!.eventid}"));
                                                            }
                                                            Map<String, dynamic>
                                                                currentUserData =
                                                                currently_loggedin_as
                                                                    .value!
                                                                    .toMap();
                                                            currentUserData[
                                                                    "saved_events"] =
                                                                saved_events;
                                                            db.db
                                                                .doc(
                                                                    "${branchPrefix}users/${currently_loggedin_as.value!.username}")
                                                                .set(
                                                                    currentUserData);
                                                            currently_loggedin_as
                                                                    .value!
                                                                    .saved_events =
                                                                saved_events;
                                                            eventUserSpecificData
                                                                    .value =
                                                                await db.getEventUserspecificData(
                                                                    event.value ??
                                                                        dbc
                                                                            .demoEvent,
                                                                    currently_loggedin_as
                                                                        .value);
                                                          },
                                                          icon: eventUserSpecificData
                                                                          .value![
                                                                      "user_has_saved"] ??
                                                                  false
                                                              ? const Icon(Icons
                                                                  .favorite)
                                                              : const Icon(Icons
                                                                  .favorite_border_outlined)),
                                                ],
                                              ),
                                              body: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              30,
                                                      vertical: 8.0),
                                                  child: ListView(children: [
                                                    Center(
                                                        child: EventTitle(
                                                            event: event
                                                                    .value ??
                                                                dbc.demoEvent,
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .height /
                                                                    20))),
                                                    Row(children: [
                                                      Expanded(
                                                          flex: 3,
                                                          child: AspectRatio(
                                                              aspectRatio: 2,
                                                              child: ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                          MediaQuery.of(context).size.width /
                                                                              30),
                                                                  child: FutureImageBuilder(
                                                                      futureImage:
                                                                          getEventFlyer(event.value ??
                                                                              dbc.demoEvent))))),
                                                    ]),
                                                    Padding(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          horizontal: 16.0,
                                                          vertical: 8.0),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          SizedBox.shrink(
                                                            child: const Text("by",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white)),
                                                          ),
                                                          event.value!.templateHostID ==
                                                                  null
                                                              ? buildLinkButtonFromRef(
                                                                  event.value!
                                                                      .hostreference,
                                                                  TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize: MediaQuery.of(context)
                                                                            .size
                                                                            .height /
                                                                        45,
                                                                  ))
                                                              : TemplateHostLinkButton(id: event.value!.templateHostID)
                                                        ],
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: event.value!
                                                                  .description !=
                                                              null
                                                          ? Padding(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                      16.0),
                                                              child: RichText(
                                                                  maxLines: 50,
                                                                  softWrap:
                                                                      true,
                                                                  text: TextSpan(
                                                                      style: const TextStyle(
                                                                          color: Colors
                                                                              .white),
                                                                      children: (event.value!.description == null || event.value!.description!.isEmpty)
                                                                          ? null
                                                                          : stringToTextSpanList(event.value!.description ??
                                                                              ""))))
                                                          : const SizedBox(
                                                              height: 0),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 16.0,
                                                              vertical: 8.0),
                                                      child: Column(children: [
                                                        Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            event.value!.locationname !=
                                                                    null
                                                                ? Container(
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width /
                                                                        2.4,
                                                                    height: MediaQuery.of(context)
                                                                            .size
                                                                            .width /
                                                                        3,
                                                                    decoration: BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                                8.0),
                                                                        color: cl
                                                                            .lighterGrey),
                                                                    child:
                                                                        Padding(
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                              4.0),
                                                                      child:
                                                                          Column(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children: [
                                                                          Text(
                                                                              'Location',
                                                                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                                                          Text(
                                                                            event.value!.locationname ??
                                                                                "Unknown",
                                                                            style:
                                                                                const TextStyle(color: Colors.white),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                          ),
                                                                          Text(
                                                                              ' '),
                                                                        ],
                                                                      ),
                                                                    ))
                                                                : const SizedBox(
                                                                    height: 0),
                                                            event.value!.begin !=
                                                                        null ||
                                                                    event.value!
                                                                            .end !=
                                                                        null
                                                                ? Container(
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width /
                                                                        2.4,
                                                                    height: MediaQuery.of(context)
                                                                            .size
                                                                            .width /
                                                                        3,
                                                                    decoration: BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                                8.0),
                                                                        color: cl
                                                                            .lighterGrey),
                                                                    child:
                                                                        Padding(
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                              4.0),
                                                                      child:
                                                                          Column(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text(
                                                                              'Duration',
                                                                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                                                          Text(
                                                                              "Begin: ${timestamp2readablestamp(event.value!.begin)}",
                                                                              style: TextStyle(fontSize: MediaQuery.of(context).size.width / 30, color: Colors.white)),
                                                                          Text(
                                                                              "End:    ${timestamp2readablestamp(event.value!.end)}",
                                                                              style: TextStyle(fontSize: MediaQuery.of(context).size.width / 30, color: Colors.white)),
                                                                          Text(
                                                                              ''),
                                                                        ],
                                                                      ),
                                                                    ))
                                                                : const SizedBox(
                                                                    height: 0),
                                                          ],
                                                        ),
                                                        Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        12.0),
                                                            child: Row(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  event.value!.minAge !=
                                                                          null
                                                                      ? Container(
                                                                          width: MediaQuery.of(context).size.width /
                                                                              2.4,
                                                                          height: MediaQuery.of(context).size.width /
                                                                              3,
                                                                          decoration: BoxDecoration(
                                                                              borderRadius: BorderRadius.circular(
                                                                                  8.0),
                                                                              color: cl
                                                                                  .lighterGrey),
                                                                          child:
                                                                              Padding(
                                                                            padding:
                                                                                EdgeInsets.all(4.0),
                                                                            child:
                                                                                Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                                                              Text('Min. Age', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                                                              Text("${event.value!.minAge}", style: const TextStyle(color: Colors.white)),
                                                                              Text(' ')
                                                                            ]),
                                                                          ))
                                                                      : const SizedBox(
                                                                          height:
                                                                              0),
                                                                  // Condition for genre missing
                                                                  Container(
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width /
                                                                          2.4,
                                                                      height:
                                                                          MediaQuery.of(context).size.width /
                                                                              3,
                                                                      decoration: BoxDecoration(
                                                                          borderRadius: BorderRadius.circular(
                                                                              8.0),
                                                                          color: cl
                                                                              .lighterGrey),
                                                                      child:
                                                                          Padding(
                                                                        padding:
                                                                            EdgeInsets.all(4.0),
                                                                        child:
                                                                            Column(
                                                                          children: [
                                                                            Text(
                                                                              'Genre',
                                                                              style: TextStyle(
                                                                                color: Colors.white,
                                                                                fontSize: 16,
                                                                                fontWeight: FontWeight.bold,
                                                                              ),
                                                                              textAlign: TextAlign.center,
                                                                            ),
                                                                            Padding(
                                                                              padding: EdgeInsets.symmetric(vertical: 6.0),
                                                                              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                                                                                Text(
                                                                                    "" //genre missing
                                                                                    ,
                                                                                    style: const TextStyle(color: Colors.white)),
                                                                                Text(''),
                                                                              ]),
                                                                            )
                                                                          ],
                                                                        ),
                                                                      )) //: const SizedBox(height: 0)
                                                                ])),
                                                        Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        4.0),
                                                            child: Row(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  linkButtons !=
                                                                          []
                                                                      ? Container(
                                                                          width: MediaQuery.of(context).size.width -
                                                                              61,
                                                                          height: MediaQuery.of(context).size.width /
                                                                              3,
                                                                          decoration: BoxDecoration(
                                                                              borderRadius: BorderRadius.circular(
                                                                                  8.0),
                                                                              color: cl
                                                                                  .lighterGrey),
                                                                          child:
                                                                              Padding(
                                                                            padding:
                                                                                EdgeInsets.all(4.0),
                                                                            child:
                                                                                Column(
                                                                              children: [
                                                                                Text('Links', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                                                                Padding(
                                                                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                                                                  child: Column(
                                                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                                                    children: [
                                                                                      Wrap(children: linkButtons),
                                                                                      event.value!.links?.containsKey("sales") ?? false ? Text("Ticketlink", style: TextStyle(color: Colors.white)) : const SizedBox(height: 0),
                                                                                      event.value!.links?.containsKey("sales") ?? false ? UrlLinkButton(event.value!.links!["sales"] ?? "", "Entry/Tickets", const TextStyle(color: Colors.white)) : const SizedBox(height: 0)
                                                                                    ],
                                                                                  ),
                                                                                )
                                                                              ],
                                                                            ),
                                                                          ))
                                                                      : const SizedBox(
                                                                          height:
                                                                              0),
                                                                ]))
                                                      ]),
                                                    ),
                                                  ])));
                                        });
                                  } else {
                                    return Scaffold(
                                        backgroundColor: cl.lighterGrey,
                                        body: const CircularProgressIndicator(
                                            color: Colors.white));
                                  }
                                });
                          }),
                ),
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
