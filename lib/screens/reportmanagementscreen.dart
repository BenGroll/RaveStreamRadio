import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/extensions.dart';


Widget leadingIcon(dbc.Report e) {
  if (e.target == null) return SizedBox();
  if (e.target!.path.startsWith("${branchPrefix}events"))
    return Icon(
      Icons.local_activity,
      color: Colors.white,
    );
  if (e.target!.path.startsWith("${branchPrefix}users"))
    return Icon(
      Icons.perm_identity,
      color: Colors.white,
    );
  if (e.target!.path.startsWith("${branchPrefix}groups"))
    return Icon(
      Icons.groups,
      color: Colors.white,
    );
  return SizedBox();
}

Widget trailingIcon(dbc.Report e) {
  if (e.state == dbc.ReportState.filed) {
    return Icon(Icons.priority_high, color: Colors.red);
  }
  if (e.state == dbc.ReportState.completed) {
    return Icon(Icons.done, color: Colors.green);
  }
  if (e.state == dbc.ReportState.pending) {
    return Icon(
      Icons.pending,
      color: Colors.yellow
    );
  }
  return SizedBox();
}

class ReportManagementScreen extends StatelessWidget {
  const ReportManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reports"),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.filter_alt_outlined))
        ],
      ),
      backgroundColor: cl.darkerGrey,
      body: FutureBuilder(
          future: db.getAllReports(),
          builder:
              (BuildContext context, AsyncSnapshot<List<dbc.Report>> snap) {
            if (snap.connectionState == ConnectionState.done) {
              return ListView(
                children: snap.data!.map((e) {
                  return ListTile(
                    onTap: () {
                      Beamer.of(context).beamToNamed("/report/${e.id}");
                    },
                    leading: leadingIcon(e),
                    title: Text(
                      e.target?.id ?? "Report has no ID",
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: trailingIcon(e),
                    subtitle: Row(
                      children: [
                        Text(
                          "Filed at ${timestamp2readablestamp(e.timestamp)}",
                          style: TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                  );
                }).toList(),
              );
            } else {
              return CircularProgressIndicator();
            }
          }),
    );
  }
}
