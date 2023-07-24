import 'package:beamer/beamer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/linkbuttons.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;
import 'package:ravestreamradioapp/extensions.dart';


class SingleReportScreen extends StatelessWidget {
  String reportid;
  SingleReportScreen({super.key, required this.reportid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cl.darkerGrey,
      appBar: AppBar(
        title: Text("Edit Report", style: cl.df),
        backgroundColor: cl.lighterGrey,
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
                        style: cl.df),
                    Row(
                      children: [
                        Text(
                          "Target: ",
                          style: cl.df,
                        ),
                        buildLinkButtonFromRef(
                            report.target, cl.df)
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "State: ${report.state.name}",
                          style: cl.df,
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
                                              cl.df),
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
                      style: cl.df,
                    ),
                    Expanded(
                      child: Padding(padding: EdgeInsets.all(8.0),
                      child: AspectRatio(aspectRatio: 1, child: Card(
                        color: cl.lighterGrey,
                        shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.height) /
                      75,
                  side: BorderSide(
                    width: 1,
                    color: cl.lighterGrey,
                  )),
                        child: Padding(padding: EdgeInsets.all(8.0),child: Text(
                            "${!report.description!.isEmpty ? report.description : 'No Description included.'}",
                            style: cl.df,
                            maxLines: 1000),
                      )),),)
                    ),
                  ],
                ),
              );
            } else {
              return cw.LoadingIndicator(color: Colors.white);
            }
          }),
    );
  }
}
