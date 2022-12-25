import 'package:beamer/beamer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/screens/overviewpages/useroverviewpage.dart';
import 'package:ravestreamradioapp/screens/overviewpages/eventoverviewpage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'shared_state.dart';

Widget buildLinkButtonFromRef(DocumentReference? doc, TextStyle labelstyle) {
  if (doc == null) {
    return Text(" Unknown Link", style: labelstyle);
  }
  if (doc.path.contains("users/")) {
    return UsernameLinkButton(target: doc, style: labelstyle);
  }
  if (doc.path.startsWith("groups/")) {
    return GroupLinkButton(target: doc, style: labelstyle);
  }
  if (doc.path.startsWith("events/")) {
    return EventLinkButton(target: doc, style: labelstyle);
  }
  return Text("Not a linkable entry.");
}

class UsernameLinkButton extends StatelessWidget {
  final DocumentReference target;
  final TextStyle style;
  const UsernameLinkButton(
      {super.key, required this.target, required this.style});

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () {
          print("/users/${target.id}");
          kIsWeb
              ? Beamer.of(context).beamToNamed("/users/${target.id}")
              : Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => UserOverviewPage(username: target.id)));
        },
        child: Text(
          "@${target.id}",
          style: style,
        ));
  }
}

class GroupLinkButton extends StatelessWidget {
  final DocumentReference target;
  final TextStyle style;
  const GroupLinkButton({super.key, required this.target, required this.style});

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => UserOverviewPage(username: target.id)));
        },
        child: Text(
          "@${target.id}",
          style: style,
        ));
  }
}

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

Widget UrlLinkButton(String url, String label, TextStyle style) {
  return TextButton(
      onPressed: () async {
        if (!await canLaunchUrl(Uri.parse(url))) throw 'Could not launch $url';
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
      child: Text(label, style: style));
}
