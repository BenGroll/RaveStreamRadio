import 'package:beamer/beamer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/linkbuttons.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;

class SingleReportScreen extends StatelessWidget {
  String reportid;
  SingleReportScreen({super.key, required this.reportid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cl.darkerGrey,
      appBar: AppBar(
        title: Text("Edit Report", style: TextStyle(color: Colors.white)),
        backgroundColor: cl.darkerGrey,
      ),
      body: FutureBuilder(
          future: db.db.doc("${branchPrefix}reports/$reportid").get(),
          builder: (context, reportSnap) {
            if (reportSnap.connectionState == ConnectionState.done) {
              dbc.Report report =
                  dbc.Report.fromMap(reportSnap.data?.data() ?? {});
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Report ID: ${reportid}",
                        style: TextStyle(color: Colors.white)),
                    Row(
                      children: [
                        Text(
                          "Target: ",
                          style: TextStyle(color: Colors.white),
                        ),
                        buildLinkButtonFromRef(
                            report.target, TextStyle(color: Colors.white))
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "State: ${report.state.name}",
                          style: TextStyle(color: Colors.white),
                        ),
                        IconButton(
                            onPressed: () async {
                              await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: cl.darkerGrey,
                                      title: Text("Change Status",
                                          style:
                                              TextStyle(color: Colors.white)),
                                      actions: [
                                        TextButton(
                                            onPressed: () async {
                                              await db.db
                                                  .doc(
                                                      "${branchPrefix}reports/${report.id}")
                                                  .update({
                                                    "state": "filed",
                                                    "finishedat" : Timestamp.now(),
                                                    "finishedby" : db.db.doc("${branchPrefix}users/${currently_loggedin_as.value!.username}")
                                                    });
                                              
                                              Navigator.of(context).pop();
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                    cw.hintSnackBar("Report was updated to 'Filed'")
                                                  );
                                              kIsWeb
                                                  ? Navigator.of(context).pop()
                                                  : Beamer.of(context)
                                                      .beamToNamed("/moderate");
                                            },
                                            child: Text("Filed",
                                                style: TextStyle(
                                                    color: Colors.white))),
                                        TextButton(
                                            onPressed: () async {
                                              await db.db
                                                  .doc(
                                                      "${branchPrefix}reports/${report.id}")
                                                  .update({
                                                    "state": "pending",
                                                    "finishedat" : Timestamp.now(),
                                                    "finishedby" : db.db.doc("${branchPrefix}users/${currently_loggedin_as.value!.username}")
                                                    });
                                              Navigator.of(context).pop();
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                    cw.hintSnackBar("Report was updated to 'Complete'")
                                                  );
                                              kIsWeb
                                                  ? Navigator.of(context).pop()
                                                  : Beamer.of(context)
                                                      .beamToNamed("/moderate");
                                            },
                                            child: Text("Pending",
                                                style: TextStyle(
                                                    color: Colors.white))),
                                        TextButton(
                                            onPressed: () async {
                                              await db.db
                                                  .doc(
                                                      "${branchPrefix}reports/${report.id}")
                                                  .update({
                                                    "state": "completed",
                                                    "finishedat" : Timestamp.now(),
                                                    "finishedby" : db.db.doc("${branchPrefix}users/${currently_loggedin_as.value!.username}")
                                                    
                                              }).then((value) => value);
                                              Navigator.of(context).pop();
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                    cw.hintSnackBar("Report was updated to 'Complete'")
                                                  );
                                              kIsWeb
                                                  ? Navigator.of(context).pop()
                                                  : Beamer.of(context)
                                                      .beamToNamed("/moderate");
                                            },
                                            child: Text("Completed",
                                                style: TextStyle(
                                                    color: Colors.white)))
                                      ],
                                    );
                                  });
                            },
                            icon: Icon(
                              Icons.settings,
                              color: Colors.white,
                            ))
                      ],
                    ),
                    Text(
                      "Description: ",
                      style: TextStyle(color: Colors.white),
                    ),
                    Expanded(
                      child: Card(
                        child: Text(
                            "${report.description?.isEmpty ?? 'No Description included.'}",
                            style: TextStyle(color: Colors.white),
                            maxLines: 1000),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return CircularProgressIndicator();
            }
          }),
    );
  }
}
