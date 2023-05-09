import 'dart:math';

import 'package:beamer/beamer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/screens/overviewpages/useroverviewpage.dart';
import 'package:ravestreamradioapp/screens/overviewpages/groupoverviewpage.dart';
import 'package:ravestreamradioapp/screens/overviewpages/eventoverviewpage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'shared_state.dart';
import 'package:ravestreamradioapp/extensions.dart';

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
          kIsWeb
              ? Beamer.of(context).beamToNamed("/groups/${target.id}")
              : Navigator.of(context).push(MaterialPageRoute(
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
///
/// Have to use SizedBox or IconButton
Widget UrlLinkButton(String url, String label, TextStyle style) {
  void _onPress() async {
    if (!await canLaunchUrl(Uri.parse(url)));
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Widget matchLogopathWithWidget(String path) {
    pprint(path);
    if (path.endsWith(".svg")) {
      return IconButton(
          onPressed: _onPress,
          icon: SvgPicture.asset(
            path ?? "graphics/rsrvector.svg",
            color: Colors.white,
          ));
    } else {
      return GestureDetector(
          onTap: _onPress, child: Image.asset(path, color: Colors.white));
    }
  }

  String? logopath;
  Map<String, String> toCheckValues = urlPatternsForLogos;
  toCheckValues.entries.forEach((element) {
    if (url.contains(element.key)) {
      logopath = element.value;
    }
  });
  //return Text("TEST");
  return TextButton(
      onPressed: _onPress,
      child: logopath == null
          ? Text(label, style: style)
          : matchLogopathWithWidget(logopath ?? ""));
}

/// Use this when showing a templatehost rather than
class TemplateHostLinkButton extends StatelessWidget {
  String? id;
  TemplateHostLinkButton({required this.id});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(MediaQuery.of(context).size.width / 100, 0, 0, 0),
      child: FutureBuilder(
          future: db.getDemoHostIDs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Text(
                snapshot.data![id] ?? "This should never display",
                style: const TextStyle(color: Colors.white),
              );
            } else {
              return CircularProgressIndicator(color: Colors.white);
            }
          }),
    );
  }
}
