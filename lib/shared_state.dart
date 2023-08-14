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
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:ravestreamradioapp/messaging.dart';

final remoteConfig = FirebaseRemoteConfig.instance;

/// ++++++++++++++ DEBUG SETTINGS ++++++++++++ //
bool DISABLE_EVENT_EDITING = remoteConfig.getBool("DISABLE_EVENT_EDITING");
bool DISABLE_CHATWINDOW = remoteConfig.getBool("DISABLE_CHATWINDOW");
bool DISABLE_MESSAGE_SENDING = remoteConfig.getBool("DISABLE_MESSAGE_SENDING");
bool DISABLE_GROUP_CREATION = remoteConfig.getBool("DISABLE_GROUP_CREATION");
bool SHOW_FEEDS = remoteConfig.getBool("SHOW_FEEDS");

String IMPRINT = remoteConfig.getString("IMPRINT");
String Policy = remoteConfig.getString("POLICY");
String ANDROID_DOWNLOADLINK = remoteConfig.getString("ANDROID_DOWNLOADLINK");
String IOS_DOWNLOADLINK = remoteConfig.getString("IOS_DOWNLOADLINK");
String WEB_DOWNLOADLINK = remoteConfig.getString("WEB_DOWNLOADLINK");

int LOWEST_COMPATIBLE_VERSION =
    remoteConfig.getInt("LOWEST_COMPATIBLE_VERSION");
int DEFAULT_MINAGE = 18;

late FirebaseApp app;
late String? fcmToken;
late MessagingAPI FCMAPI = MessagingAPI();

//! This Versions Versioncode. Change for Update Detection !//
const VERSIONCODE = 35;
const BUILDVERSION = "2.3.30";

ValueNotifier<RemoteConfig?> remoteConfigValues =
    ValueNotifier<RemoteConfig?>(null);

class RemoteConfig {
  Map<String, dynamic> downloadLinks;
  int versioncode;
  Map<String, String> replaceChars;
  RemoteConfig(
      {required this.downloadLinks,
      required this.versioncode,
      required this.replaceChars});
}

double DISPLAY_LONG_SIDE(context) {
  return MediaQuery.of(context).size.height > MediaQuery.of(context).size.width
      ? MediaQuery.of(context).size.height
      : MediaQuery.of(context).size.width;
}

double DISPLAY_SHORT_SIDE(context) {
  return MediaQuery.of(context).size.height < MediaQuery.of(context).size.width
      ? MediaQuery.of(context).size.height
      : MediaQuery.of(context).size.width;
}

/// Enum of Different Database Branches
enum ServerBranches { public, test, develop }

/// Map of URLs with dedicated Logo
///
/// Key is regex pattern for url checking, value is logo file path
Map<String, String> urlPatternsForLogos = {
  "instagram.com": "graphics/instagramlogo.svg",
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

/// ValueNotifier that contains which database branch the api is currently connected to
ValueNotifier<ServerBranches> selectedbranch =
    ValueNotifier(ServerBranches.develop);

/// Cache for saved Pictures. Saves bandwidth
Map<String, Widget> saved_pictures = {};

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
    return "";
  }
}

String get currentLogFilePath {
  DateTime now = DateTime.now();
  DateTime logFileStartTimestamp =
      now.subtract(Duration(days: now.weekday - 1));
  DateTime logFileEndTimestamp = now.add(Duration(days: 7 - now.weekday));
  return "logs/${logFileStartTimestamp.day.toString().padLeft(2, '0')}.${logFileStartTimestamp.month.toString().padLeft(2, '0')}.${logFileStartTimestamp.year.toString().padLeft(2, '0')}-${logFileEndTimestamp.day.toString().padLeft(2, '0')}.${logFileEndTimestamp.month.toString().padLeft(2, '0')}.${logFileEndTimestamp.year.toString().padLeft(2, '0')}";
}

String get currentLogFileDay {
  DateTime now = DateTime.now();
  return "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year.toString().padLeft(2, '0')}";
}

//! Add to index.html
/*
<link rel="apple-touch-icon" sizes="57x57" href="/apple-icon-57x57.png">
<link rel="apple-touch-icon" sizes="60x60" href="/apple-icon-60x60.png">
<link rel="apple-touch-icon" sizes="72x72" href="/apple-icon-72x72.png">
<link rel="apple-touch-icon" sizes="76x76" href="/apple-icon-76x76.png">
<link rel="apple-touch-icon" sizes="114x114" href="/apple-icon-114x114.png">
<link rel="apple-touch-icon" sizes="120x120" href="/apple-icon-120x120.png">
<link rel="apple-touch-icon" sizes="144x144" href="/apple-icon-144x144.png">
<link rel="apple-touch-icon" sizes="152x152" href="/apple-icon-152x152.png">
<link rel="apple-touch-icon" sizes="180x180" href="/apple-icon-180x180.png">
<link rel="icon" type="image/png" sizes="192x192"  href="/android-icon-192x192.png">
<link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">
<link rel="icon" type="image/png" sizes="96x96" href="/favicon-96x96.png">
<link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png">
<link rel="manifest" href="/manifest.json">
<meta name="msapplication-TileColor" content="#ffffff">
<meta name="msapplication-TileImage" content="/ms-icon-144x144.png">
<meta name="theme-color" content="#ffffff">
*/

Future<dynamic> sync(List<Future> futures) async {
  return Future.wait(futures);
}
