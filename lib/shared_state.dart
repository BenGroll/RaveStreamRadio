import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;

enum ServerBranches { public, test, develop }

const bool kIsWeb = bool.fromEnvironment('dart.library.js_util');

ValueNotifier<ServerBranches> selectedbranch = kIsWeb 
  ? ValueNotifier(ServerBranches.public) 
  : ValueNotifier(ServerBranches.develop);

Map<String, Widget> saved_pictures = {};
List<dbc.Event> saved_events = [];

Map settings = {"language": "en"};
//List<String> saved_pictures = <String>[];

enum Screens { events, favourites, forums, profile }

ValueNotifier<Screens> currently_selected_screen =
    ValueNotifier<Screens>(Screens.events);
ValueNotifier<dbc.User?> currently_loggedin_as = ValueNotifier<dbc.User?>(null);

int ITEMS_PER_PAGE_IN_EVENTSHOW = 10;
