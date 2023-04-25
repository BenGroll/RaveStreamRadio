import 'dart:convert';
import 'package:ravestreamradioapp/extensions.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/database.dart';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/chatting.dart';

/// ++++++++++++++ DEBUG SETTINGS ++++++++++++ //
const bool DISABLE_EVENT_EDITING = true;
const bool DISABLE_CHATWINDOW = false;
const bool DISABLE_MESSAGE_SENDING = true;

late FirebaseApp app;

/// Enum of Different Database Branches
enum ServerBranches { public, test, develop }

/// Map of URLs with dedicated Logo
///
/// Key is regex pattern for url checking, value is logo file path
Map<String, String> urlPatternsForLogos = {
  "instagram.com": "graphics/linkicons/instagramlogo.svg",
  "ravestreamradio.de": "graphics/rsrvector.svg"
};

/// Enum of Possible Permissions. Users can have none, or multiple. [Admin] gives the user every other permission
enum GlobalPermission {
  ADMIN,
  MANAGE_EVENTS,
  MANAGE_HOSTS,
  CHANGE_DEV_SETTINGS,
  MODERATE
}

/// Enum of different statuses events can have.
///
/// Public => Any person can see the event, and possibly buy tickets.
///
/// Friendlist => Only people in the group or friendlist of the host can buy tickets for this event
///
/// Frozen => The event is in review by our moderators, and temporarily hidden from the public.
///
/// Draft => The event exists in the database, however hidden from the public. It can still be edited and later published to the public
enum EventStatus { public, friendlist, frozen, draft }

/// Flag that corresponds to the System this app is ran from. True means its running in a browser, false means it runs on mobile or desktop
const bool kIsWeb = bool.fromEnvironment('dart.library.js_util');
/*
ValueNotifier<ServerBranches> selectedbranch = kIsWeb 
  ? ValueNotifier(ServerBranches.public) 
  : ValueNotifier(ServerBranches.develop);*/

/// ValueNotifier that contains which database branch the api is currently connected to
ValueNotifier<ServerBranches> selectedbranch =
    ValueNotifier(ServerBranches.develop);

/// Cache for saved Pictures. Saves bandwidth
Map<String, Widget> saved_pictures = {};

///
List<Message> saved_messages = [];

/// Cache for events. Saves database costs(obsolete)
List<dbc.Event> saved_events = [];

class UserSettings {
  String lang = "en";
  UserSettings({required this.lang});
  Map<String, dynamic> toMap() {
    return <String, dynamic>{"lang": lang};
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(lang: map["lang"] as String);
  }
}

UserSettings defaultusersettings = UserSettings(lang: "en");

/// Enum that contains the different Home-Page screens
enum Screens { events, favourites, forums, profile }

/// InitialRoute web URL
const WEB_URL = "https://ravestreammobileapp.web.app/";

/// ClientID for paypal sandbox connected to my personal paypal
const PAYPAL_SANDBOX_CLIENTID =
    "AfS_OQV6tSpHQJbQvM4S63h0S252Tf7Zfcjo4bl1CMc7AZgbRk-kYhF1xYecn_19tbNHBsFk45sinvoJ";

/// Secret for paypal sandbox connected to my personal paypal
const PAYPAL_SANDBOX_SECRET =
    "EAq_d_co6VFRrSsU7wQiwtmSkRto85MhFZG22KJJC6qnHDdkmUS3QLtdiB5zcjC6k93ZhwprunCSI0_p";

/// Email for paypal sandbox connected to my personal paypal
const PAYPAL_SANDBOX_EMAIL = "sb-1s8kv25131713@business.example.com";

/// ValueNotifier that contains which screen is currently selected from the Homepage
ValueNotifier<Screens> currently_selected_screen =
    ValueNotifier<Screens>(Screens.events);

/// ValueNotifier that contains the user object the app is currently logged in as.
///
/// null means you are not logged in
ValueNotifier<dbc.User?> currently_loggedin_as = ValueNotifier<dbc.User?>(null);

/// Defines how many events are shown per page
int ITEMS_PER_PAGE_IN_EVENTSHOW = 10;

/// The prefix used to access the different branches of firestore database
String get branchPrefix {
  if (selectedbranch.value == ServerBranches.develop) {
    return "dev.";
  }
  if (selectedbranch.value == ServerBranches.public) {
    return "";
  }
  if (selectedbranch.value == ServerBranches.test) {
    return "test.";
  } else {
    throw Exception("Prefix for selected Branch not set.");
  }
}
