// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/commonwidgets.dart';
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/filesystem.dart';
import 'package:ravestreamradioapp/linkbuttons.dart' as linkbuttons;
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/screens/overviewpages/eventoverviewpage.dart';
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:beamer/beamer.dart';

List<dbc.Event>? event_data = [];
int totalelements = 0;
ValueNotifier<int> current_page = ValueNotifier<int>(0);

Future reloadEventPage() async {
  event_data = [];
  totalelements = await db.getEventCount().then((value) => value);
  current_page.value = -1;
  current_page.value = 0;
  currently_selected_screen.notifyListeners();
}

class EventFilterBottomSheet extends StatelessWidget {
  ValueNotifier<db.EventFilters> filters;
  EventFilterBottomSheet({super.key, required this.filters});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cl.nearly_black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: null,
        title: Text("Filters", style: TextStyle(color: Colors.white)),
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.undo))],
      ),
      body: ValueListenableBuilder(
          valueListenable: filters,
          builder: (context, enabledFilters, foo) {
            print(enabledFilters);
            return ListView(
              children: [
                ListTile(
                  dense: false,
                  title: Text("Only After:",
                      style: TextStyle(color: Colors.white)),
                  trailing:
                      IconButton(onPressed: () {}, icon: Icon(Icons.undo)),
                ),
                ListTile(
                  dense: true,
                  title: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ElevatedButton(
                            onPressed: () {},
                            child: Text(
                                filters.value.onlyAfter == null
                                    ? "Select onlyAfter"
                                    : timestamp2readablestamp(
                                        filters.value.onlyAfter),
                                style: TextStyle(color: Colors.white)))
                      ],
                    ),
                  ),
                ),
                ListTile(
                  dense: false,
                  title: Text("Only Before:",
                      style: TextStyle(color: Colors.white)),
                  trailing:
                      IconButton(onPressed: () {}, icon: Icon(Icons.undo)),
                ),
                ListTile(
                  dense: true,
                  title: Text("Select Only Before",
                      style: TextStyle(color: Colors.white)),
                ),
                ListTile(
                  dense: false,
                  title:
                      Text("Can go with this Age:", style: TextStyle(color: Colors.white)),
                  trailing:
                      IconButton(onPressed: () {
                        filters.value.canGoByAge = 18;
                            filters.notifyListeners();
                      }, icon: Icon(Icons.undo)),
                ),
                ListTile(
                  dense: true,
                  title: Row(
                    children: [
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  (enabledFilters.canGoByAge != null &&
                                          enabledFilters.canGoByAge! < 18)
                                      ? cl.deep_black
                                      : cl.greynothighlight),
                          onPressed: () {
                            filters.value.canGoByAge = 17;
                            filters.notifyListeners();
                          },
                          child: Text("U18")),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  (enabledFilters.canGoByAge != null &&
                                          enabledFilters.canGoByAge! >= 18 && enabledFilters.canGoByAge! < 21)
                                      ? cl.deep_black
                                      : cl.greynothighlight),
                          onPressed: () {
                            filters.value.canGoByAge = 18;
                            filters.notifyListeners();
                          },
                          child: Text("18+")),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  (enabledFilters.canGoByAge != null &&
                                          enabledFilters.canGoByAge! >= 21)
                                      ? cl.deep_black
                                      : cl.greynothighlight),
                          onPressed: () {
                            filters.value.canGoByAge = 21;
                            filters.notifyListeners();
                          },
                          child: Text("21+"))
                    ],
                  ),
                ),
                db.doIHavePermission(GlobalPermission.MODERATE) ? 
                ListTile(
                  dense: false,
                  title: Text("Status:", style: TextStyle(color: Colors.white)),
                  trailing:
                      IconButton(onPressed: () {}, icon: Icon(Icons.undo)),
                ) : const SizedBox(height: 0),
                db.doIHavePermission(GlobalPermission.MODERATE) ?
                ListTile(
                  dense: true,
                  title: Row(
                    children: [
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  (enabledFilters.byStatus != null &&
                                          enabledFilters.byStatus!.contains("public"))
                                      ? cl.deep_black
                                      : cl.greynothighlight),
                          onPressed: () {
                            filters.value.byStatus.contains("public") ? filters.value.byStatus.remove("public") : filters.value.byStatus.add("public");
                            filters.notifyListeners();
                          },
                          child: Text("Public")),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  ( enabledFilters.byStatus.contains("friendlist"))
                                      ? cl.deep_black
                                      : cl.greynothighlight),
                          onPressed: () {
                            filters.value.byStatus.contains("friendlist") ? filters.value.byStatus.remove("friendlist") : filters.value.byStatus.add("friendlist");
                            filters.notifyListeners();
                          },
                          child: Text("Friendlist")),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  (
                                    enabledFilters.byStatus.contains("frozen"))
                                      ? cl.deep_black
                                      : cl.greynothighlight),
                          onPressed: () {
                            filters.value.byStatus.contains("frozen") ? filters.value.byStatus.remove("frozen") : filters.value.byStatus.add("frozen");
                            filters.notifyListeners();
                          },
                          child: Text("Frozen")),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  (
                                          enabledFilters.byStatus.contains("draft"))
                                      ? cl.deep_black
                                      : cl.greynothighlight),
                          onPressed: () {
                            filters.value.byStatus.contains("draft") ? filters.value.byStatus.remove("draft") : filters.value.byStatus.add("draft");
                            filters.notifyListeners();
                          },
                          child: Text("Drafts")),
                    ],
                  )
                ) : const SizedBox(height: 0),
              ],
            );
          }),
    );
  }
}

enum CalendarMode { normal, drafts }

class EventCalendar extends StatelessWidget {
  final dbc.User? loggedinas;
  final CalendarMode mode;
  EventCalendar(
      {super.key, required this.loggedinas, this.mode = CalendarMode.normal});
  @override
  Widget build(BuildContext context) {
      ValueNotifier<db.EventFilters> filters = ValueNotifier(db.EventFilters(byStatus: mode == CalendarMode.normal ? ["public"] : ["draft"]));
    event_data = [];
    totalelements = 0;
    current_page.value = 0;
    GlobalKey<ScaffoldState> scaffkey = GlobalKey<ScaffoldState>();
    Scaffold scaff = Scaffold(
        drawer: cw.NavBar(),
        backgroundColor: cl.nearly_black,
        body: RefreshIndicator(
            backgroundColor: cl.deep_black,
            color: Colors.white,
            onRefresh: () => Future.delayed(Duration(seconds: 1))
                .then((value) => reloadEventPage()),
            child: ValueListenableBuilder(
                valueListenable: current_page,
                builder: ((context, value, child) {
                  return FutureBuilder(
                      future: db.fetchEventsFromIndexFile(),
                      builder: ((context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return CircularProgressIndicator();
                        } else {
                          return ValueListenableBuilder(
                              valueListenable: filters,
                              builder: (BuildContext context,
                                  db.EventFilters filters, foo) {
                                List<dbc.Event> events = snapshot.data ?? [];
                                return ListView(
                                  children: db
                                      .queriefyEventList(events, filters)
                                      .map((e) => CalendarEventCard(e))
                                      .toList(),
                                );
                              });
                        }
                      }));
                }))),
        appBar: CalendarAppBar(
          context,
          filters,
          title: mode == CalendarMode.drafts ? "Your Drafts" : "Events",
        ));
    return scaff;
  }
}

class CalendarEventCard extends StatelessWidget {
  late dbc.Event event;
  CalendarEventCard(dbc.Event event) {
    this.event = event;
  }
  @override
  Widget build(BuildContext context) {
    ValueNotifier<bool> saved =
        ValueNotifier(db.isEventSaved(event, currently_loggedin_as.value));
    if (isEventHostedByUser(event, currently_loggedin_as.value)) {
      return Dismissible(
          direction: DismissDirection.horizontal,
          onDismissed: (direction) async {},
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              bool was_saved = await db.saveEventToUserReturnWasSaved(
                  event, currently_loggedin_as.value);
              saved.value = !was_saved;
              was_saved
                  ? ScaffoldMessenger.of(context).showSnackBar(
                      cw.hintSnackBar("Deleted event from favorites."))
                  : ScaffoldMessenger.of(context).showSnackBar(
                      cw.hintSnackBar("Added event to favorites."));
            }
            if (direction == DismissDirection.endToStart) {
              // Open Editing Screen vor Event
              Beamer.of(context).beamToNamed("/editevent/${event.eventid}");
            }
            return false;
          },
          background: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width / 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              ValueListenableBuilder(
                  valueListenable: saved,
                  builder: (context, value, child) => Icon(
                      saved.value ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width / 10)),
              ValueListenableBuilder(
                  valueListenable: saved,
                  builder: (context, value, foo) {
                    return Text(
                        value ? "Delete from favorites" : "Add to favorites",
                        style: TextStyle(color: cl.greynothighlight));
                  })
            ]),
          ),
          secondaryBackground: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width / 10),
            child:
                Row(mainAxisAlignment: MainAxisAlignment.end, children: const [
              Text("Edit event", style: TextStyle(color: Colors.white)),
              Icon(Icons.settings, color: Colors.white)
            ]),
          ),
          key: UniqueKey(),
          child: _CalendarEventCardBody(event: event));
    } else if (currently_loggedin_as.value != null) {
      return Dismissible(
          key: UniqueKey(),
          background: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width / 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              ValueListenableBuilder(
                  valueListenable: saved,
                  builder: (context, value, child) => Icon(
                      saved.value ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width / 10)),
              ValueListenableBuilder(
                  valueListenable: saved,
                  builder: (context, value, foo) {
                    return Text(
                        value ? "Delete from favorites" : "Add to favorites",
                        style: TextStyle(color: cl.greynothighlight));
                  })
            ]),
          ),
          direction: DismissDirection.startToEnd,
          onDismissed: (direction) async {},
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              bool was_saved = await db.saveEventToUserReturnWasSaved(
                  event, currently_loggedin_as.value);
              saved.value = !was_saved;
              was_saved
                  ? ScaffoldMessenger.of(context).showSnackBar(
                      cw.hintSnackBar("Deleted event from favorites."))
                  : ScaffoldMessenger.of(context).showSnackBar(
                      cw.hintSnackBar("Added event to favorites."));
            }
            return false;
          },
          child: _CalendarEventCardBody(event: event));
    } else {
      return Dismissible(
          direction: DismissDirection.none,
          key: UniqueKey(),
          child: _CalendarEventCardBody(event: event));
    }
  }
}

double getAspectRatioForEventCard(dbc.Event event) {
  const double SINGLELINESIZE = 0.25;
  const double CARDSIZEWOTEXTS = 2.4;
  double finalaspect = CARDSIZEWOTEXTS;
  if (event.minAge != 0) finalaspect -= SINGLELINESIZE;
  if (event.locationname != null) finalaspect -= SINGLELINESIZE;
  return finalaspect;
}

class _CalendarEventCardBody extends StatelessWidget {
  final dbc.Event event;
  const _CalendarEventCardBody({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height / 80,
          horizontal: MediaQuery.of(context).size.height / 120),
      child: AspectRatio(
          aspectRatio: getAspectRatioForEventCard(event),
          child: Card(
              elevation: 3,
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.height) /
                      75,
                  side: const BorderSide(
                    width: 1,
                    color: Color.fromARGB(26, 255, 255, 255),
                  )),
              child: InkWell(
                onTap: () {
                  kIsWeb
                      ? Beamer.of(context)
                          .beamToNamed("/events/${event.eventid}")
                      : Navigator.of(context).push(MaterialPageRoute(
                          builder: ((context) =>
                              EventOverviewPage(event.eventid))));
                },
                customBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.height) /
                        75,
                    side: const BorderSide(
                      width: 1,
                      color: Color.fromARGB(26, 255, 255, 255),
                    )),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                                flex: 1,
                                child: AspectRatio(
                                    aspectRatio: 1,
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            MediaQuery.of(context).size.width /
                                                50),
                                        child: FutureImageBuilder(
                                            futureImage:
                                                getEventIcon(event))))),
                            Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                          child: EventTitle(
                                              event: event,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          15))),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Text("by",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                            event.templateHostID != null
                                                ? Padding(
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                100,
                                                            0,
                                                            0,
                                                            0),
                                                    child: FutureBuilder(
                                                        future:
                                                            db.getDemoHostIDs(),
                                                        builder: (context,
                                                            snapshot) {
                                                          if (snapshot
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .done) {
                                                            return Text(
                                                              snapshot.data![event
                                                                      .templateHostID] ??
                                                                  "This should never display",
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                            );
                                                          } else {
                                                            return CircularProgressIndicator(
                                                                color: Colors
                                                                    .white);
                                                          }
                                                        }),
                                                  )
                                                : (event.hostreference != null
                                                    ? linkbuttons
                                                        .buildLinkButtonFromRef(
                                                            event.hostreference,
                                                            const TextStyle(
                                                                color: Colors
                                                                    .white))
                                                    : Padding(
                                                        padding:
                                                            EdgeInsets.fromLTRB(
                                                                MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    100,
                                                                0,
                                                                0,
                                                                0),
                                                        child: const Text(
                                                            "Unknown User",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white)),
                                                      ))
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            event.begin != null
                                                ? Text(
                                                    "Begins: ${timestamp2readablestamp(event.begin)}",
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontSize: 13,
                                                        color: Colors.white),
                                                  )
                                                : const SizedBox(height: 0),
                                            event.end != null
                                                ? Text(
                                                    "Ends: ${timestamp2readablestamp(event.end)}",
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontSize: 13,
                                                        color: Colors.white),
                                                  )
                                                : const SizedBox(height: 0)
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ))
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              event.minAge != 0
                                  ? Text(
                                      "Minimum Age: ${event.minAge}",
                                      style:
                                          const TextStyle(color: Colors.white),
                                    )
                                  : const SizedBox(height: 0),
                              Text(
                                "Location: ${event.locationname ?? "Unknown"}",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ))),
    );
  }
}

class PageIndicator extends StatelessWidget {
  final int pagecount = (totalelements / ITEMS_PER_PAGE_IN_EVENTSHOW).ceil();
  PageIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: current_page,
        builder: ((context, value, child) {
          List<Widget> pageactions = [];
          if (current_page.value != 0) {
            pageactions.add(TextButton(
                onPressed: () {
                  if (current_page.value != 0) {
                    current_page.value = current_page.value - 1;
                  }
                },
                child: Text(
                  "<",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.height / 40),
                )));
          }
          for (int i = 0; i < pagecount; i++) {
            pageactions.add(TextButton(
                onPressed: () {},
                child: Text(
                  i.toString(),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: i == current_page.value
                          ? MediaQuery.of(context).size.height / 35
                          : MediaQuery.of(context).size.height / 40,
                      fontWeight: i == current_page.value
                          ? FontWeight.bold
                          : FontWeight.w300),
                )));
          }
          pageactions.add(current_page.value >= pagecount - 1
              ? SizedBox()
              : TextButton(
                  onPressed: () {
                    current_page.value = current_page.value + 1;
                  },
                  child: Text(
                    ">",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.height / 40),
                  )));
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: pageactions),
          );
        }));
  }
}
