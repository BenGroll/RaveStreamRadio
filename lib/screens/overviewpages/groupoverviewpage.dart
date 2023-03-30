import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/commonwidgets.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/shared_state.dart';

class GroupOverviewPage extends StatelessWidget {
  final String groupid;
  dbc.Group? group;
  GroupOverviewPage({super.key, required this.groupid});

  @override
  Widget build(BuildContext context) {
    bool is_founder = false;
    return SafeArea(
        minimum: EdgeInsets.fromLTRB(
            0, MediaQuery.of(context).size.height / 50, 0, 0),
        child: FutureBuilder(
          future: db.db.doc("${branchPrefix}groups/$groupid").get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Scaffold(
                backgroundColor: cl.darkerGrey,
                appBar: AppBar(
                    centerTitle: true,
                    title: Text("Group: ${snapshot.data!.id}"),
                    actions: [
                      ReportButton(target: "${branchPrefix}groups/$groupid")
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
                  body: const Center(
                      child: CircularProgressIndicator(color: Colors.white)));
            }
          },
        ));
  }
}
