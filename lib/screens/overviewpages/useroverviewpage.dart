import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/extensions.dart';


class UserOverviewPage extends StatelessWidget {
  final String username;
  dbc.User? user;
  UserOverviewPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        minimum: EdgeInsets.fromLTRB(
            0, MediaQuery.of(context).size.height / 50, 0, 0),
        child: FutureBuilder(
          future: db.db.doc("${branchPrefix}users/$username").get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Scaffold(
                backgroundColor: cl.darkerGrey,
                appBar: AppBar(
                  centerTitle: true,
                  title: Text("User: ${snapshot.data!.id}"),
                  actions: [
                    cw.ReportButton(target: "${branchPrefix}users/$username"),
                    cw.StartChatButton(other_person_username: username)
                  ],
                ),
                body: const Center(
                    child: Text(
                  "TBA",
                  style: TextStyle(color: Colors.white),
                )),
              );
            } else {
              return Scaffold(
                  backgroundColor: cl.darkerGrey,
                  body: cw.LoadingIndicator(color: Colors.white));
            }
          },
        ));
  }
}
