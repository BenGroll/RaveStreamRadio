// ignore_for_file: prefer_const_constructors, sort_child_properties_last
import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/screens/aboutus.dart';
import 'package:ravestreamradioapp/screens/groupcreationscreen.dart';
import 'package:ravestreamradioapp/screens/mainscreens/calendar.dart';
import 'package:ravestreamradioapp/screens/mainscreens/favourites.dart';
import 'package:ravestreamradioapp/screens/mainscreens/groups.dart';
import 'package:ravestreamradioapp/screens/mainscreens/profile.dart';
import 'package:ravestreamradioapp/screens/eventcreationscreens.dart';
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;
import 'package:ravestreamradioapp/screens/privacypolicy.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/extensions.dart';
import 'package:ravestreamradioapp/chatting.dart' as chats;
import 'package:ravestreamradioapp/database.dart' as db;

Screens map_Index_to_Screen(int index) {
  switch (index) {
    case 0:
      {
        return Screens.events;
      }
    case 1:
      {
        return Screens.favourites;
      }
    case 3:
      {
        return Screens.forums;
      }
    case 4:
      {
        return Screens.profile;
      }
    default:
      {
        return currently_selected_screen.value;
      }
  }
}

int map_Screen_to_Index(Screens screen) {
  switch (screen) {
    case Screens.events:
      {
        return 0;
      }
    case Screens.favourites:
      {
        return 1;
      }
    case Screens.forums:
      {
        return 3;
      }
    case Screens.profile:
      {
        return 4;
      }
    default:
      {
        return 2;
      }
  }
}

/// Controls the tooltip that gets shown when holding down on the FloatingButton
String get FloatingActionButtonTooltip {
  switch (currently_selected_screen.value) {
    case Screens.events:
      {
        return "Host new Event";
      }
    case Screens.favourites:
      {
        return "Find friends";
      }
    case Screens.forums:
      {
        return "Create new Group";
      }
    case Screens.profile:
      {
        return "ASDSAD";
      }
    default:
      {
        return "Useless Tooltip";
      }
  }
}

Widget map_Widget_to_Screen(Screens screen) {
  switch (screen) {
    case Screens.events:
      {
        return EventCalendar(
            loggedinas: currently_loggedin_as.value, mode: CalendarMode.normal);
      }
    case Screens.favourites:
      {
        return Favourites(loggedinas: currently_loggedin_as.value);
      }
    case Screens.forums:
      {
        return GroupsScreen(loggedinas: currently_loggedin_as.value);
      }
    case Screens.profile:
      {
        return ProfileScreen(loggedinas: currently_loggedin_as.value);
      }
    default:
      {
        return EventCalendar(loggedinas: currently_loggedin_as.value);
      }
  }
}

AppBar? mapScreenToAppBar(
    Screens screen, dbc.User? loggedinas, BuildContext context) {
  switch (screen) {
    case Screens.events:
      {
        return null;
      }
    case Screens.favourites:
      {
        return null;
      }
    case Screens.forums:
      {
        return null;
      }
    case Screens.profile:
      {
        return null;
      }
    default:
      {
        return AppBar();
      }
  }
}

/// HomeScreen Manager
class HomeScreen extends StatelessWidget {
  dbc.User? loggedinas;
  final Screens startingscreen;
  HomeScreen(
      {super.key,
      required this.loggedinas,
      this.startingscreen = Screens.events});
  @override
  Widget build(BuildContext context) {
    currently_selected_screen.value = startingscreen;
    currently_loggedin_as.value = loggedinas;
    return ValueListenableBuilder(
        valueListenable: currently_loggedin_as,
        builder: ((context, value, child) {
          return ValueListenableBuilder(
              valueListenable: currently_selected_screen,
              builder: ((context, screen, child) {
                return FutureBuilder(
                    future: db.getRemoteConfig(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return cw.LoadingIndicator(color: Colors.white);
                      }
                      return Scaffold(
                        drawer: cw.NavBar(),
                        endDrawer:
                            currently_selected_screen.value == Screens.forums
                                ? chats.ChatsDrawer()
                                : currently_selected_screen.value == Screens.profile
                                ? cw.ProfileDrawer()
                                : null
                                ,
                        appBar: mapScreenToAppBar(
                            screen, currently_loggedin_as.value, context),
                        body: map_Widget_to_Screen(
                            currently_selected_screen.value),
                        floatingActionButtonLocation:
                            FloatingActionButtonLocation.centerDocked,
                        floatingActionButton:
                            (screen == Screens.events ||
                                    screen == Screens.forums)
                                ? Tooltip(
                                    message: FloatingActionButtonTooltip,
                                    child: FloatingActionButton(
                                      backgroundColor: cl.darkerGrey,
                                      onPressed: () {
                                        ValueNotifier<bool> has_accepted =
                                            ValueNotifier(false);
                                        if (currently_selected_screen.value ==
                                            Screens.events) {
                                          if (currently_loggedin_as.value !=
                                              null) {
                                            showDialog(
                                                context: context,
                                                builder:
                                                    (context) => AlertDialog(
                                                          backgroundColor:
                                                              cl.lighterGrey,
                                                          title: Text("AGBs",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white)),
                                                          content: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Text(
                                                                  "To publish events you have to accept our AGBs.",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white)),
                                                              TextButton(
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .push(MaterialPageRoute(
                                                                            builder: (context) =>
                                                                                PrivacyPolicy()));
                                                                  },
                                                                  child: Text(
                                                                      "View AGBs",
                                                                      style: TextStyle(
                                                                          color: Color.fromARGB(
                                                                              255,
                                                                              110,
                                                                              178,
                                                                              255)))),
                                                              ValueListenableBuilder(
                                                                  valueListenable:
                                                                      has_accepted,
                                                                  builder:
                                                                      (context,
                                                                          accepted,
                                                                          foo) {
                                                                    return Theme(
                                                                      data: Theme.of(
                                                                              context)
                                                                          .copyWith(
                                                                              unselectedWidgetColor: Colors.white),
                                                                      child: Checkbox(
                                                                          checkColor: Colors
                                                                              .white,
                                                                          activeColor: Colors
                                                                              .white,
                                                                          value:
                                                                              accepted,
                                                                          onChanged: (value) =>
                                                                              has_accepted.value = value ?? has_accepted.value),
                                                                    );
                                                                  })
                                                            ],
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                },
                                                                child: Text(
                                                                    "Discard",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white))),
                                                            ValueListenableBuilder(
                                                                valueListenable:
                                                                    has_accepted,
                                                                builder:
                                                                    (contex,
                                                                        value,
                                                                        foo) {
                                                                  return TextButton(
                                                                    child: Text(
                                                                        "Proceed",
                                                                        style: TextStyle(
                                                                            color: value
                                                                                ? Colors.white
                                                                                : Color.fromARGB(255, 163, 163, 163))),
                                                                    onPressed:
                                                                        () {
                                                                      if (value) {
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                        Beamer.of(context)
                                                                            .beamToNamed("/hostevent");
                                                                      } else {
                                                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                                            content:
                                                                                Text("You haven't accepted our AGBs")));
                                                                      }
                                                                    },
                                                                  );
                                                                })
                                                          ],
                                                        ));
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(cw.hintSnackBar(
                                                    "You have to be logged in to create Event"));
                                          }
                                        } else if (currently_selected_screen
                                                .value ==
                                            Screens.forums) {
                                          if (currently_loggedin_as.value !=
                                              null) {
                                            DISABLE_GROUP_CREATION
                                                ? ScaffoldMessenger.of(context)
                                                    .showSnackBar(cw.hintSnackBar(
                                                        "Group Creating is currently WIP and will be added in the near future."))
                                                : Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            GroupCreationScreen()));
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(cw.hintSnackBar(
                                                    "Has to be logged in to create Group"));
                                          }
                                        }
                                      },
                                      child: Icon(Icons.add),
                                    ),
                                  )
                                : null,
                        bottomNavigationBar: BottomAppBar(
                          shape: CircularNotchedRectangle(),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          notchMargin: 6,
                          child: Theme(
                            data: Theme.of(context)
                                .copyWith(canvasColor: cl.darkerGrey),
                            child: BottomNavigationBar(
                              backgroundColor: cl.darkerGrey,
                              selectedItemColor: Colors.white,
                              unselectedItemColor: Colors.white,
                              items: [
                                BottomNavigationBarItem(
                                    label: "Events",
                                    icon: Icon(
                                        currently_selected_screen.value ==
                                                Screens.events
                                            ? Icons.calendar_month
                                            : Icons.calendar_month_outlined)),
                                /*BottomNavigationBarItem(
                                  label: "News",
                                  icon: Icon(currently_selected_screen.value ==
                                          Screens.events
                                      ? Icons.article
                                      : Icons.article_outlined)),*/
                                BottomNavigationBarItem(
                                    label: "Favourites",
                                    icon: Icon(
                                        currently_selected_screen.value ==
                                                Screens.favourites
                                            ? Icons.favorite
                                            : Icons.favorite_border)),
                                BottomNavigationBarItem(
                                    label: "",
                                    icon: Icon(Icons.add,
                                        color:
                                            Color.fromARGB(0, 255, 255, 255))),

                                /*BottomNavigationBarItem(
                                  label: "Chats",
                                  icon: Icon(currently_selected_screen.value ==
                                          Screens.forums
                                      ? Icons.question_answer
                                      : Icons.question_answer_outlined)),*/
                                BottomNavigationBarItem(
                                    label: "Social",
                                    icon: Icon(
                                        currently_selected_screen.value ==
                                                Screens.forums
                                            ? Icons.groups
                                            : Icons.groups_outlined)),
                                BottomNavigationBarItem(
                                    label: "Profile",
                                    icon: Icon(
                                        currently_selected_screen.value ==
                                                Screens.profile
                                            ? Icons.person
                                            : Icons.person_outline)),
                              ],
                              currentIndex: map_Screen_to_Index(
                                  currently_selected_screen.value),
                              onTap: ((value) {
                                currently_selected_screen.value =
                                    map_Index_to_Screen(value);
                              }),
                            ),
                          ),
                        ),
                        backgroundColor: cl.darkerGrey,
                      );
                    });
              }));
        }));
  }
}
