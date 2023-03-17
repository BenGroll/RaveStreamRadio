import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ravestreamradioapp/screens/aboutus.dart';
import 'package:ravestreamradioapp/screens/eventcreationscreens.dart';
import 'package:ravestreamradioapp/screens/loginscreen.dart';
import 'package:ravestreamradioapp/screens/managecalendarscreen.dart';
import 'package:ravestreamradioapp/screens/overviewpages/eventoverviewpage.dart';
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/screens/overviewpages/reportoverviewpage.dart';
import 'package:ravestreamradioapp/screens/overviewpages/useroverviewpage.dart';
import 'package:ravestreamradioapp/screens/reportmanagementscreen.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/main.dart' as main;
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:beamer/beamer.dart';
import 'package:ravestreamradioapp/screens/overviewpages/groupoverviewpage.dart';
import 'screens/privacypolicy.dart';
import 'screens/imprint.dart';
import 'package:ravestreamradioapp/screens/devsettingsscreen.dart';
import 'package:ravestreamradioapp/screens/draftscreen.dart';

/// All named Routes are to be included here
Map<Pattern, dynamic Function(BuildContext, BeamState, Object?)> webroutes = {
  // Routes for web navigation
  "/": (context, state, data) =>
      const BeamPage(child: main.MainRoute(), title: "Events"),
  "/events": (context, state, data) => const BeamPage(child: main.MainRoute()),
  "/favorites": (context, state, data) =>
      const BeamPage(child: main.MainRoute(startingscreen: Screens.favourites)),
  "/groups": (context, state, data) =>
      const BeamPage(child: main.MainRoute(startingscreen: Screens.forums)),
  "/groups/:groupidPOPTO": (context, state, data) {
    final groupid = state.pathParameters["groupidPOPTO"]?.split("@")[0];
    final popto = state.pathParameters["groupidPOPTO"]?.split("@")[1];
    return BeamPage(
        key: ValueKey("Group - $groupid"),
        //type: BeamPageType.scaleTransition,
        title: "@$groupid",
        child: groupid == null
            ? const Text("Empty Userid")
            : GroupOverviewPage(groupid: groupid));
  },
  "/profile": (context, state, data) =>
      const BeamPage(child: main.MainRoute(startingscreen: Screens.profile)),
  //"/users": (context, state, data) => const Text("No user provided"),
  "/users/:username": (context, state, data) {
    final username = state.pathParameters["username"];
    return BeamPage(
        key: ValueKey("User - $username"),
        //type: BeamPageType.scaleTransition,
        //keepQueryOnPop: true,
        title: "@$username",
        child: username == null
            ? const Text("Empty Userid")
            : UserOverviewPage(username: username));
  },
  "/events/:eventid": (context, state, data) {
    final eventid = state.pathParameters["eventid"]!;
    return BeamPage(
        key: ValueKey("Event - $eventid"),
        popToNamed: "/events",
        type: BeamPageType.scaleTransition,
        child: eventid.isEmpty
            ? const Text("Event not found.")
            : EventOverviewPage(eventid));
  },
  "/login": (context, state, data) => LoginScreen(),
  "/hostevent": (context, state, data) => EventCreationScreen(),
  "/editevent/:eventid": (context, state, data) {
    final eventid = state.pathParameters["eventid"]!;
    return BeamPage(
        key: ValueKey("EditEvent - $eventid"),
        //popToNamed: "/events",
        type: BeamPageType.scaleTransition,
        child: eventid.isEmpty
            ? const Text("Event not found")
            : WillPopScope(
                onWillPop: () async {
                  Beamer.of(context).beamBack();
                  return false;
                },
                child: EventCreationScreen(eventIDToBeEdited: eventid)));
  },
  "/createaccount": (context, state, data) => CreateAccountScreen(),
  "/policy": (context, state, data) => const PrivacyPolicy(),
  "/imprint": (context, state, data) => const ImPrint(),
  "/social": (context, state, data) => const AboutUsPage(),
  "/dev": (context, state, data) => const DevSettingsScreen(),
  "/manage": (context, state, data) => ManageEventScreen(),
  "/drafts": (context, state, data) => const DraftCalendar(),
  "/moderate": (context, state, data) => ReportManagementScreen(),
  "/report/:reportid": (context, state, data) {
    final reportid = state.pathParameters["reportid"];
    return BeamPage(
        key: ValueKey("Report - $reportid"),
        //type: BeamPageType.scaleTransition,
        popToNamed: "/moderate",
        child: reportid == null
            ? Text("Report not Found")
            : SingleReportScreen(reportid: reportid));
  }
};
