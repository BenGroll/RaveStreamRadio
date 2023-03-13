import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/database.dart';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ravestreamradioapp/conv.dart';

enum ServerBranches { public, test, develop }

enum GlobalPermission {
  ADMIN,
  MANAGE_EVENTS,
  MANAGE_HOSTS,
  CHANGE_DEV_SETTINGS
}

enum EventStatus { public, friendlist, frozen, draft }

const bool kIsWeb = bool.fromEnvironment('dart.library.js_util');
/*
ValueNotifier<ServerBranches> selectedbranch = kIsWeb 
  ? ValueNotifier(ServerBranches.public) 
  : ValueNotifier(ServerBranches.develop);*/

ValueNotifier<ServerBranches> selectedbranch =
    ValueNotifier(ServerBranches.develop);

Map<String, Widget> saved_pictures = {};
List<dbc.Event> saved_events = [];
Map settings = {"language": "en"};
//List<String> saved_pictures = <String>[];

enum Screens { events, favourites, forums, profile }

const WEB_URL = "https://ravestreammobileapp.web.app/";
const PAYPAL_SANDBOX_CLIENTID =
    "AfS_OQV6tSpHQJbQvM4S63h0S252Tf7Zfcjo4bl1CMc7AZgbRk-kYhF1xYecn_19tbNHBsFk45sinvoJ";
const PAYPAL_SANDBOX_SECRET =
    "EAq_d_co6VFRrSsU7wQiwtmSkRto85MhFZG22KJJC6qnHDdkmUS3QLtdiB5zcjC6k93ZhwprunCSI0_p";
const PAYPAL_SANDBOX_EMAIL = "sb-1s8kv25131713@business.example.com";

ValueNotifier<Screens> currently_selected_screen =
    ValueNotifier<Screens>(Screens.events);
ValueNotifier<dbc.User?> currently_loggedin_as = ValueNotifier<dbc.User?>(null);

int ITEMS_PER_PAGE_IN_EVENTSHOW = 10;

void devFunction() async {
  //copy a collection
  //Map<String, String> ids = await db.getDocIDsFromCollectionAsList("templatehosts");
  /*await db.db
      .collection("content")
      .doc("indexes")
      .update({"templateHostIDs": ids});
  DocumentSnapshot snap = await db.db.doc("dev.events/extasechristmas2k23").get();
  if (snap.data() != null) {
    print(dbc.Event.fromMap(snap.data() as Map<String, dynamic>).toJson());
  }*/
}
