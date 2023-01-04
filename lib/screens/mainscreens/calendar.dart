import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
}

class EventCalendar extends StatelessWidget {
  final dbc.User? loggedinas;

  const EventCalendar({super.key, required this.loggedinas});

  @override
  Widget build(BuildContext context) {
    event_data = [];
    totalelements = 0;
    current_page.value = 0;
    return Scaffold(
      drawer: const cw.NavBar(),
        appBar: AppBar(
          leading: const cw.OpenSidebarButton(),
          actions: [
            IconButton(
            onPressed: () {}, icon: Icon(Icons.filter_alt))],
          title: const Text("Events"), centerTitle: true),
        
        backgroundColor: cl.nearly_black,
        body: FutureBuilder(
            future: db.getEventCount(),
            builder: (context, snapshot) {
              totalelements = snapshot.data ?? 0;
              return ValueListenableBuilder(
                  valueListenable: current_page,
                  builder: ((context, value, child) {
                    if (event_data!.length >=
                        current_page.value * ITEMS_PER_PAGE_IN_EVENTSHOW) {
                      return FutureBuilder(
                          future: db.getEvents(
                              ITEMS_PER_PAGE_IN_EVENTSHOW,
                              event_data!.isEmpty
                                  ? null
                                  : event_data!.last.eventid,
                              "end"),
                          builder: ((context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              //Loading Indicator
                              return const CircularProgressIndicator();
                            } else {
                              snapshot.data?.forEach((element) {
                                event_data!.add(element);
                              });
                              List<dbc.Event> shownevents = [];
                              for (int i = (current_page.value) *
                                      ITEMS_PER_PAGE_IN_EVENTSHOW;
                                  i <
                                      (current_page.value + 1) *
                                          ITEMS_PER_PAGE_IN_EVENTSHOW;
                                  i++) {
                                if (i < event_data!.length) {
                                  shownevents.add(event_data![i]);
                                }
                              }
                              List<Widget> shownitems = [];
                              for (int i = 0; i < shownevents.length; i++) {
                                shownitems.add(
                                    CalendarEventCard(event: shownevents[i]));
                              }
                              totalelements > ITEMS_PER_PAGE_IN_EVENTSHOW
                                  ? shownitems.add(PageIndicator())
                                  : print("");
                              shownitems.add(SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height / 35));
                              return ListView(children: shownitems);
                            }
                          }));
                    } else {
                      //Load List with old data
                      List<dbc.Event> shownevents = [];
                      for (int i = (current_page.value) *
                              ITEMS_PER_PAGE_IN_EVENTSHOW;
                          i <
                              (current_page.value + 1) *
                                  ITEMS_PER_PAGE_IN_EVENTSHOW;
                          i++) {
                        if (i < event_data!.length) {
                          shownevents.add(event_data![i]);
                        }
                      }
                      List<Widget> shownitems = [];
                      for (int i = 0; i < shownevents.length; i++) {
                        shownitems
                            .add(CalendarEventCard(event: shownevents[i]));
                      }
                      shownitems.add(PageIndicator());
                      shownitems.add(SizedBox(
                          height: MediaQuery.of(context).size.height / 35));
                      return ListView(children: shownitems);
                    }
                  }));
            }));
  }
}

class CalendarEventCard extends StatelessWidget {
  final dbc.Event event;
  CalendarEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    ValueNotifier<bool> saved =
        ValueNotifier(db.isEventSaved(event, currently_loggedin_as.value));
    if (isEventHostedByUser(event.eventid, currently_loggedin_as.value)) {
      return SizedBox.shrink(
        child: Dismissible(
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
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Text("Edit event", style: TextStyle(color: Colors.white)),
                    Icon(Icons.settings, color: Colors.white)
                  ]),
            ),
            key: UniqueKey(),
            child: _CalendarEventCardBody(event: event)),
      );
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
            bool was_saved = await db.saveEventToUserReturnWasSaved( event, currently_loggedin_as.value);
                saved.value = !was_saved;
                was_saved
                    ? ScaffoldMessenger.of(context).showSnackBar(
                        cw.hintSnackBar("Deleted event from favorites."))
                    : ScaffoldMessenger.of(context).showSnackBar(
                        cw.hintSnackBar("Added event to favorites."));
              }
              return false;
            },
          child: _CalendarEventCardBody(event: event)
        );
    } else {
      return _CalendarEventCardBody(event: event);
    }
  }
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
          aspectRatio: 2,
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
                                            event.hostreference != null
                                                ? linkbuttons.buildLinkButtonFromRef(
                                                  event.hostreference,
                                                  const TextStyle(color: Colors.white)
                                                  )
                                                : const Text("Unknown User",
                                                    style: TextStyle(
                                                        color: Colors.white))
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
                              Text(
                                event.age == null
                                    ? ""
                                    : "Age: ${event.age ?? ""}",
                                style: const TextStyle(color: Colors.white),
                              ),
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
