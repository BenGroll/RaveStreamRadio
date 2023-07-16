import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ravestreamradioapp/commonwidgets.dart';
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/filesystem.dart';
import 'package:ravestreamradioapp/linkbuttons.dart';
import 'package:ravestreamradioapp/screens/homescreen.dart' as home;
import 'package:ravestreamradioapp/screens/mainscreens/calendar.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/extensions.dart';
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;

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
                      0, DISPLAY_LONG_SIDE(context) / 50, 0, 0),
                  child: event.value == null
                      ? Container(
                          child: Text("Couldn't load Event",
                              style: TextStyle(color: Colors.white)))
                      : ValueListenableBuilder(
                          valueListenable: event,
                          builder: (context, eventdata, foo) {
                            try {
                              return FutureBuilder(
                                  future: db.getEventUserspecificData(
                                      event.value ?? dbc.demoEvent,
                                      currently_loggedin_as.value),
                                  builder: (context, snapshot) {
                                    //pprint(stringToTextSpanList("Hello Friends!\n Lol"));
                                    if (snapshot.connectionState ==
                                        ConnectionState.done) {
                                      eventUserSpecificData.value =
                                          snapshot.data;
                                      return ValueListenableBuilder(
                                          valueListenable:
                                              eventUserSpecificData,
                                          builder: (context, bar, foo) {
                                            List<Widget> linkButtons = [];
                                            if (eventdata?.links != null) {
                                              eventdata!.links!
                                                  .forEach((key, value) {
                                                    linkButtons.add(UrlLinkButton(value, key, TextStyle(color: Colors.white)));
                                                  });
                                        }
                                            GlobalKey<ScaffoldState> _key =
                                                GlobalKey();
                                            return Scaffold(
                                                key: _key,
                                                endDrawer: event.value != null
                                                    ? cw.EventOverviewpageSideDrawer(
                                                        event: event.value ??
                                                            dbc.demoEvent)
                                                    : null,
                                                backgroundColor: cl.darkerGrey,
                                                appBar: AppBar(
                                                  backgroundColor:
                                                      cl.lighterGrey,
                                                  centerTitle: true,
                                                  title: GestureDetector(
                                                    onLongPress: () {
                                                      event.value != null
                                                          ? Clipboard.setData(
                                                              ClipboardData(
                                                                  text: event
                                                                      .value!
                                                                      .eventid))
                                                          : null;
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(SnackBar(
                                                              content: Text(
                                                                  "Copied Title to Clipboard")));
                                                    },
                                                    child:
                                                        SingleChildScrollView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      child: Text(
                                                          event.value!.eventid,
                                                          maxLines: 2),
                                                    ),
                                                  ),
                                                  actions: [
                                                    ValueListenableBuilder(
                                                        valueListenable:
                                                            currently_loggedin_as,
                                                        builder: (context,
                                                            userLoggedIn, foo) {
                                                          return IconButton(
                                                              onPressed:
                                                                  () async {
                                                                List<DocumentReference>
                                                                    saved_events =
                                                                    currently_loggedin_as
                                                                        .value!
                                                                        .saved_events;
                                                                if (saved_events
                                                                    .contains(db
                                                                        .db
                                                                        .doc(
                                                                            "${branchPrefix}events/${event.value!.eventid}"))) {
                                                                  saved_events
                                                                      .remove(db
                                                                          .db
                                                                          .doc(
                                                                              "${branchPrefix}events/${event.value!.eventid}"));
                                                                } else {
                                                                  saved_events.add(
                                                                      db.db.doc(
                                                                          "${branchPrefix}events/${event.value!.eventid}"));
                                                                }
                                                                Map<String,
                                                                        dynamic>
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
                                                                currently_loggedin_as
                                                                    .notifyListeners();
                                                              },
                                                              icon: currently_loggedin_as
                                                                          .value
                                                                          ?.saved_events
                                                                          .contains(db.db.doc(
                                                                              "${branchPrefix}events/$eventid")) ??
                                                                      false
                                                                  ? Icon(
                                                                      Icons
                                                                          .bookmark,
                                                                      color: Colors
                                                                          .white)
                                                                  : Icon(Icons
                                                                      .bookmark_border));
                                                        }),
                                                    IconButton(
                                                        onPressed: () {
                                                          _key.currentState!
                                                              .openEndDrawer();
                                                        },
                                                        icon: Icon(Icons.menu,
                                                            color:
                                                                Colors.white))
                                                  ],
                                                ),
                                                body: Padding(
                                                    padding: EdgeInsets.symmetric(
                                                        horizontal:
                                                            DISPLAY_SHORT_SIDE(
                                                                    context) /
                                                                30,
                                                        vertical: 8.0),
                                                    child: ListView(children: [
                                                      event.value?.status ==
                                                              "frozen"
                                                          ? Text(
                                                              "This event is currently hidden from the public by moderation.",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .red))
                                                          : Container(),
                                                      Center(
                                                          child: EventTitle(
                                                              event: event
                                                                      .value ??
                                                                  dbc.demoEvent,
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize:
                                                                      DISPLAY_LONG_SIDE(
                                                                              context) /
                                                                          20))),
                                                      ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  DISPLAY_SHORT_SIDE(
                                                                          context) /
                                                                      30),
                                                          child: FutureImageBuilder(
                                                              futureImage:
                                                                  getEventFlyer(
                                                                      event.value ??
                                                                          dbc.demoEvent))),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .symmetric(
                                                                horizontal:
                                                                    16.0,
                                                                vertical: 8.0),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: [
                                                            const Text(
                                                                  "by",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white)),
                                                            event.value!.templateHostID ==
                                                                    null
                                                                ? buildLinkButtonFromRef(
                                                                    event.value!
                                                                        .hostreference,
                                                                    TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          DISPLAY_LONG_SIDE(context) /
                                                                              45,
                                                                    ))
                                                                : TemplateHostLinkButton(
                                                                    id: event
                                                                        .value!
                                                                        .templateHostID)
                                                          ],
                                                        ),
                                                      ),
                                                      event.value!.description !=
                                                              null
                                                          ? Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .all(
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
                                                      Padding(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal:
                                                                    16.0,
                                                                vertical: 8.0),
                                                        child: Column(
                                                            children: [
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
                                                                          width: DISPLAY_SHORT_SIDE(context) /
                                                                              2.4,
                                                                          height: DISPLAY_SHORT_SIDE(context) /
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
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                                              children: [
                                                                                Text('Location', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                                                                Text(
                                                                                  event.value!.locationname ?? "Unknown",
                                                                                  style: const TextStyle(color: Colors.white),
                                                                                  textAlign: TextAlign.center,
                                                                                ),
                                                                                Text(' '),
                                                                              ],
                                                                            ),
                                                                          ))
                                                                      : const SizedBox(
                                                                          height:
                                                                              0),
                                                                  event.value!.begin !=
                                                                              null ||
                                                                          event.value!.end !=
                                                                              null
                                                                      ? Container(
                                                                          width: DISPLAY_SHORT_SIDE(context) /
                                                                              2.4,
                                                                          height: DISPLAY_SHORT_SIDE(context) /
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
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Text('Duration', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                                                                Text("Begin: ${timestamp2readablestamp(event.value!.begin)}", style: TextStyle(fontSize: DISPLAY_SHORT_SIDE(context) / 30, color: Colors.white)),
                                                                                Text("End:    ${timestamp2readablestamp(event.value!.end)}", style: TextStyle(fontSize: DISPLAY_SHORT_SIDE(context) / 30, color: Colors.white)),
                                                                                Text(''),
                                                                              ],
                                                                            ),
                                                                          ))
                                                                      : const SizedBox(
                                                                          height:
                                                                              0),
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
                                                                                width: DISPLAY_SHORT_SIDE(context) / 2.4,
                                                                                height: DISPLAY_SHORT_SIDE(context) / 3,
                                                                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0), color: cl.lighterGrey),
                                                                                child: Padding(
                                                                                  padding: EdgeInsets.all(4.0),
                                                                                  child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                                                                    Text('Min. Age', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                                                                    Text("${event.value!.minAge}", style: const TextStyle(color: Colors.white)),
                                                                                    Text(' ')
                                                                                  ]),
                                                                                ))
                                                                            : const SizedBox(height: 0),
                                                                        // Condition for genre missing
                                                                        Container(
                                                                            width: DISPLAY_SHORT_SIDE(context) /
                                                                                2.4,
                                                                            height: DISPLAY_SHORT_SIDE(context) /
                                                                                3,
                                                                            decoration:
                                                                                BoxDecoration(borderRadius: BorderRadius.circular(8.0), color: cl.lighterGrey),
                                                                            child: Padding(
                                                                              padding: EdgeInsets.all(4.0),
                                                                              child: Column(
                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                children: [
                                                                                  Text(
                                                                                    'Genre',
                                                                                    style: TextStyle(
                                                                                      color: Colors.white,
                                                                                      fontSize: 18,
                                                                                      fontWeight: FontWeight.bold,
                                                                                    ),
                                                                                    textAlign: TextAlign.center,
                                                                                  ),
                                                                                  Text("${event.value?.genre ?? 'No Genre Set'}", style: const TextStyle(color: Colors.white)),
                                                                                  Text(''),
                                                                                ],
                                                                              ),
                                                                            )) //: const SizedBox(height: 0)
                                                                      ])),
                                                              Padding(
                                                                  padding: EdgeInsets
                                                                      .symmetric(
                                                                          vertical:
                                                                              0.0),
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
                                                                                width: DISPLAY_SHORT_SIDE(context) - 61,
                                                                                height: DISPLAY_SHORT_SIDE(context) / 3,
                                                                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0), color: cl.lighterGrey),
                                                                                child: Padding(
                                                                                  padding: EdgeInsets.all(4.0),
                                                                                  child: Column(
                                                                                    children: [
                                                                                      Text('Links', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                                                                      Padding(
                                                                                        padding: EdgeInsets.symmetric(vertical: 8.0),
                                                                                        child: Column(
                                                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
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
                                                                            : const SizedBox(height: 0),
                                                                      ]))
                                                            ]),
                                                      ),
                                                    ])));
                                          });
                                    } else {
                                      return Scaffold(
                                          backgroundColor: cl.lighterGrey,
                                          body: cw.LoadingIndicator(
                                              color: Colors.white));
                                    }
                                  });
                            } catch (e, stack) {
                              print(e);
                              print("Stack : $stack");
                              return Container();
                            }
                          }),
                ),
              );
            } else {
              /*Navigator.of(context).maybePop();
              reloadEventPage();*/
              return Scaffold(
                  appBar: AppBar(),
                  backgroundColor: cl.darkerGrey,
                  body: Center(
                      child: Text("This Event doesn't exist (anymore)",
                          style: TextStyle(color: Colors.white))));
            }
          } else {
            return cw.LoadingIndicator(color: Colors.white);
          }
        });
  }
}
