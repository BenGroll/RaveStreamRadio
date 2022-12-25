import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;

class ForumsScreen extends StatefulWidget {
  final dbc.User? loggedinas;
  const ForumsScreen({super.key, required this.loggedinas});

  @override
  State<ForumsScreen> createState() => _ForumsScreenState();
}

class _ForumsScreenState extends State<ForumsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cl.nearly_black,
      appBar: AppBar(
        backgroundColor: cl.deep_black,
        title: const Text("Forums"),
        centerTitle: true,
      ),
    );
  }
}
