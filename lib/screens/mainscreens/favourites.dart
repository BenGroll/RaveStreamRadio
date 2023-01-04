import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;

class Favourites extends StatefulWidget {
  final dbc.User? loggedinas;
  const Favourites({super.key, required this.loggedinas});

  @override
  State<Favourites> createState() => _FavouritesState();
}

class _FavouritesState extends State<Favourites> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const cw.NavBar(),
      backgroundColor: cl.nearly_black,
      appBar: AppBar(
        leading: const cw.OpenSidebarButton(),
        backgroundColor: cl.deep_black,
        title: const Text("Favourites"),
        centerTitle: true,
      ),
    );
  }
}
