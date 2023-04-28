import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;
import 'package:ravestreamradioapp/screens/mainscreens/calendar.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/extensions.dart';


class Favourites extends StatefulWidget {
  final dbc.User? loggedinas;
  const Favourites({super.key, required this.loggedinas});

  @override
  State<Favourites> createState() => _FavouritesState();
}

class _FavouritesState extends State<Favourites> {
  @override
  Widget build(BuildContext context) {
    return EventCalendar(loggedinas: currently_loggedin_as.value, mode: CalendarMode.favourites);
  }
}
