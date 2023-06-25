import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ravestreamradioapp/screens/aboutus.dart';
import 'package:ravestreamradioapp/screens/downloadLandingPage.dart';
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
import 'package:ravestreamradioapp/extensions.dart';
import 'package:ravestreamradioapp/chatting.dart' show ChatWindow;

/// All named Routes are to be included here
Map<Pattern, dynamic Function(BuildContext, BeamState, Object?)> webroutes = {
  // Routes for web navigation
  "/": (context, state, data) =>
      const BeamPage(child: main.MainRoute(), title: "Events"),
  "/events": (context, state, data) => const BeamPage(child: main.MainRoute(), title: "Events"),
  "/favorites": (context, state, data) =>
      const BeamPage(child: main.MainRoute(startingscreen: Screens.favourites), title: "Favourites"),
  "/groups": (context, state, data) =>
      const BeamPage(child: main.MainRoute(startingscreen: Screens.forums), title: "Social"),
  "/groups/:groupidPOPTO": (context, state, data) {
    final groupid = state.pathParameters["groupidPOPTO"]?.split("@")[0];
    final popto = state.pathParameters["groupidPOPTO"]?.split("@")[1];
    return BeamPage(
        key: ValueKey("Group - $groupid"),
        //type: BeamPageType.scaleTransition,
        title: "Group: @$groupid",
        child: groupid == null
            ? const Text("Empty Userid")
            : GroupOverviewPage(groupid: groupid));
  },
  "/profile": (context, state, data) =>
      const BeamPage(child: main.MainRoute(startingscreen: Screens.profile), title: "Profile"),
  //"/users": (context, state, data) => const Text("No user provided"),
  "/users/:username": (context, state, data) {
    final username = state.pathParameters["username"];
    return BeamPage(
        key: ValueKey("User - $username"),
        //type: BeamPageType.scaleTransition,
        //keepQueryOnPop: true,
        title: "User: @$username",
        child: username == null
            ? const Text("Empty Userid")
            : UserOverviewPage(username: username));
  },
  "/events/:eventid": (context, state, data) {
    final eventid = state.pathParameters["eventid"]!;
    return BeamPage(
      title: "Event: @$eventid",
        key: ValueKey("Event - $eventid"),
        popToNamed: "/",
        type: BeamPageType.scaleTransition,
        child: eventid.isEmpty
            ? const Text("Event not found.")
            : EventOverviewPage(eventid));
  },
  "/login": (context, state, data) => BeamPage(child: LoginScreen(), title: "Login"),
  "/hostevent": (context, state, data) => BeamPage(child: EventCreationScreen(), title: "Host Event"),
  "/editevent/:eventid": (context, state, data) {
    final eventid = state.pathParameters["eventid"]!;
    return BeamPage(
        key: ValueKey("EditEvent - $eventid"),
        title: "Edit @$eventid",
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
  "/download": (context, state, data) => const BeamPage(child: DownloadLandingPage(), title: "Download"),
  "/createaccount": (context, state, data) => BeamPage(child: CreateAccountScreen(),  title: "Create Account"),
  "/policy": (context, state, data) => BeamPage(child: const PrivacyPolicy(), title: "Privacy Policy"),
  "/imprint": (context, state, data) => const BeamPage(child: ImPrint(), title: "Imprint"),
  "/social": (context, state, data) => BeamPage(child: const AboutUsPage(), title: "Social"),
  "/dev": (context, state, data) => const BeamPage(child: DevSettingsScreen(), title: "DevOpts"),
  "/manage": (context, state, data) => BeamPage(child: ManageEventScreen(), title: "Manage"),
  "/drafts": (context, state, data) => const BeamPage(child: const DraftCalendar(), title: "Drafts"),
  "/moderate": (context, state, data) => const BeamPage(child: ReportManagementScreen(), title: "Moderate"),
  "/chat/:chatid": (context, state, data) {
    final chatid = state.pathParameters["chatid"];
    return BeamPage(
        key: ValueKey("Chat - $chatid"),
        //type: BeamPageType.scaleTransition,
        title: "Chat",
        child: chatid == null
            ? Text("Chat not Found")
            : ChatWindow(id: chatid,));
  },
  "/report/:reportid": (context, state, data) {
    final reportid = state.pathParameters["reportid"];
    return BeamPage(
      title: "Report: $reportid",
        key: ValueKey("Report - $reportid"),
        //type: BeamPageType.scaleTransition,
        popToNamed: "/moderate",
        child: reportid == null
            ? Text("Report not Found")
            : SingleReportScreen(reportid: reportid));
  }
};
