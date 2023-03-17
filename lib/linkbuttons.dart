import 'package:beamer/beamer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/screens/overviewpages/useroverviewpage.dart';
import 'package:ravestreamradioapp/screens/overviewpages/groupoverviewpage.dart';
import 'package:ravestreamradioapp/screens/overviewpages/eventoverviewpage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'shared_state.dart';


/// Tests if the document contains a user, a group or event, and returns the corresponding linkbutton
Widget buildLinkButtonFromRef(DocumentReference? doc, TextStyle labelstyle) {
  if (doc == null) {
    return Text(" Unknown Link", style: labelstyle);
  }
  if (doc.path.contains("users/")) {
    return UsernameLinkButton(target: doc, style: labelstyle);
  }
  if (doc.path.contains("groups/")) {
    return GroupLinkButton(target: doc, style: labelstyle);
  }
  if (doc.path.contains("events/")) {
    return EventLinkButton(target: doc, style: labelstyle);
  }
  return Text("Not a linkable entry.");
}

/// Button that shows username and links to User-Overviewpage 
class UsernameLinkButton extends StatelessWidget {
  final DocumentReference target;
  final TextStyle style;
  const UsernameLinkButton(
      {super.key, required this.target, required this.style});

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () {
          kIsWeb
              ? Beamer.of(context).beamToNamed("/users/${target.id}@events")
              : Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => UserOverviewPage(username: target.id)));
        },
        child: Text(
          "@${target.id}",
          style: style,
        ));
  }
}

/// Button that shows GroupID and links to Group-Overviewpage 
class GroupLinkButton extends StatelessWidget {
  final DocumentReference target;
  final TextStyle style;
  const GroupLinkButton({super.key, required this.target, required this.style});

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () {
          kIsWeb ? Beamer.of(context).beamToNamed("/groups/${target.id}") : 
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  GroupOverviewPage(groupid: "${target.id}")));
        },
        child: Text(
          "@${target.id}",
          style: style,
        ));
  }
}

/// Button that shows eventid and links to Event-Overviewpage 
class EventLinkButton extends StatelessWidget {
  final DocumentReference target;
  final TextStyle style;
  const EventLinkButton({super.key, required this.target, required this.style});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: target.get(),
        builder: (context, snapshot) {
          return TextButton(
              onPressed: () async {
                Beamer.of(context).beamToNamed("/events/${target.id}");
              },
              child: Text(
                "@${target.id}",
                style: style,
              ));
        });
  }
}

/// Button that contains an url.
/// 
/// If link corresponds to an installed app, opens App.
/// Else opens link in external Browser 
Widget UrlLinkButton(String url, String label, TextStyle style) {
  return TextButton(
      onPressed: () async {
        if (!await canLaunchUrl(Uri.parse(url))) throw 'Could not launch $url';
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
      child: Text(label, style: style));
}
