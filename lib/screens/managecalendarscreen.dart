import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:beamer/beamer.dart';
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;

enum ManagementScreens { Events, Hosts, Media }

ValueNotifier<ManagementScreens> selectedManagementScreen =
    ValueNotifier<ManagementScreens>(ManagementScreens.Events);

Widget mapScreenToManagementScreen(
    ManagementScreens screen) {
  switch (screen) {
    case ManagementScreens.Events:
      {
        return EventScreen();
      }
    case ManagementScreens.Hosts:
      {
        return HostScreens();
      }
    case ManagementScreens.Media:
      {
        return MediaScreen();
      }
    default:
      {
        return Placeholder();
      }
  }
}

class EventScreen extends StatelessWidget {
  const EventScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return cw.EventTable();
  }
}

class HostScreens extends StatelessWidget {
  const HostScreens({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class MediaScreen extends StatelessWidget {
  const MediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

final scaffoldKey = GlobalKey<ScaffoldState>();

class ManageEventScreen extends StatelessWidget {
  ManageEventScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: selectedManagementScreen,
        builder: (context, screen, child) {
          return mapScreenToManagementScreen(screen);
        });
  }
}
