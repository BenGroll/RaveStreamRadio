import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/databaseclasses.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:beamer/beamer.dart';
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;
import 'package:ravestreamradioapp/extensions.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';

/// Screens in Management Tab
enum ManagementScreens { Events, Hosts, Media }

/// Selected Screen in Management tab
ValueNotifier<ManagementScreens> selectedManagementScreen =
    ValueNotifier<ManagementScreens>(ManagementScreens.Events);

Widget mapScreenToManagementScreen(ManagementScreens screen) {
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

/// Screen "Events" in Management Tab
class EventScreen extends StatelessWidget {
  const EventScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return cw.EventTable();
  }
}

class ManagingScreensDrawer extends StatelessWidget {
  const ManagingScreensDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: cl.lighterGrey,
      child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          // ignore: prefer_const_literals_to_create_immutables
          children: !db.doIHavePermission(GlobalPermission.MANAGE_EVENTS)
              ? []
              : [
                  ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                    tileColor: cl.lighterGrey,
                    onTap: () {
                      selectedManagementScreen.value = ManagementScreens.Events;
                      //managescreen.scaffoldKey.currentState!.closeDrawer();
                    },
                    title: Text("Events",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.height / 40)),
                  ),
                  ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                    tileColor: cl.lighterGrey,
                    onTap: () {
                      selectedManagementScreen.value = ManagementScreens.Hosts;
                      //managescreen.scaffoldKey.currentState!.closeDrawer();
                    },
                    title: Text("Hosts",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.height / 40)),
                  ),
                  ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                    tileColor: cl.lighterGrey,
                    onTap: () {
                      selectedManagementScreen.value = ManagementScreens.Media;
                      //managescreen.scaffoldKey.currentState!.closeDrawer();
                    },
                    title: Text("Media",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.height / 40)),
                  ),
                ]),
    );
  }
}

/// Screen "Hosts" in Management Tab
class HostScreens extends StatelessWidget {
  ValueNotifier<Map<String, String>?> demoHosts =
      ValueNotifier<Map<String, String>?>(null);
  List<ListTile> hostIDMapToListTileList(
      Map<String, String> hosts, BuildContext context) {
    List<ListTile> tiles = [];
    List<String> hostIDS = hosts.keys.toList()..sort();
    hostIDS.forEach((key) {
      tiles.add(ListTile(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) =>
                    ViewHostPage(isEditingHostID: key, toNotify: demoHosts)));
          },
          title: Text(hosts[key] ?? "", style: TextStyle(color: Colors.white)),
          subtitle: Text("@$key",
              style: TextStyle(color: Color.fromARGB(255, 184, 184, 184))),
          trailing:
              Icon(Icons.settings, color: Color.fromARGB(255, 207, 207, 207))));
    });
    return tiles;
  }

  HostScreens({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: cl.darkerGrey,
        drawer: ManagingScreensDrawer(),
        appBar: AppBar(
          centerTitle: true,
          title: Text("Hosts"),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) =>
                          ViewHostPage(toNotify: demoHosts)));
                },
                icon: Icon(Icons.add, color: Colors.white))
          ],
        ),
        body: FutureBuilder(
            future: db.getDemoHostIDs(),
            builder: (BuildContext context,
                AsyncSnapshot<Map<String, String>> snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return cw.LoadingIndicator(color: Colors.white);
              } else {
                demoHosts.value = snapshot.data;
                return ValueListenableBuilder(
                    valueListenable: demoHosts,
                    builder: (context, hosts, foo) {
                      return ListView(
                        padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width / 40),
                        children: hostIDMapToListTileList(hosts ?? {}, context),
                      );
                    });
              }
            }));
  }
}

class ViewHostPage extends StatelessWidget {
  String? isEditingHostID;
  ValueNotifier<Host?> currentHostData = ValueNotifier(null);
  ValueNotifier toNotify;
  ViewHostPage({super.key, this.isEditingHostID, required this.toNotify});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: isEditingHostID == null
            ? Future.delayed(Duration.zero).then((value) => null)
            : db.loadDemoHostFromDB(isEditingHostID ?? ""),
        builder: (BuildContext context, AsyncSnapshot<Host?> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return cw.LoadingIndicator(color: Colors.white);
          } else {
            if (snapshot.hasData && snapshot.data != null) {
              currentHostData.value = snapshot.data;
            }
            if (isEditingHostID != null && currentHostData.value == null) {
              return Scaffold(
                  body: Center(child: Text("Couldn't find $isEditingHostID.")));
            } else {
              ValueNotifier<String> name =
                  ValueNotifier<String>(currentHostData.value?.name ?? "");
              ValueNotifier<String> id =
                  ValueNotifier<String>(currentHostData.value?.id ?? "");
              ValueNotifier<HostCategory?> category =
                  ValueNotifier<HostCategory?>(
                      currentHostData.value?.category ?? null);
              ValueNotifier<String?> logopath =
                  ValueNotifier<String?>(currentHostData.value?.logopath);
              ValueNotifier<bool> permit =
                  ValueNotifier<bool>(currentHostData.value?.permit ?? false);
              ValueNotifier<bool> official_logo = ValueNotifier<bool>(
                  currentHostData.value?.official_logo ?? false);
              ValueNotifier<List<Link>> links = ValueNotifier<List<Link>>(
                  currentHostData.value?.links ?? <Link>[]);

              Host craftHost() {
                return Host(
                    id: id.value,
                    name: name.value,
                    links: links.value,
                    category: category.value,
                    permit: permit.value,
                    official_logo: official_logo.value);
              }

              Future<List<String>> verifyHostUpload() async {
                List<String> errors = [];
                if (name.value.isEmpty) {
                  errors.add("Hostname can't be empty.");
                } else {
                  if (isEditingHostID == null) {
                    DocumentSnapshot snap =
                        await db.db.doc("demohosts/${id.value}").get();
                    if (snap.exists) {
                      errors.add("A host with this id already exists.");
                    }
                  }
                }
                if (id.value.isEmpty) {
                  errors.add("ID can't be empty.");
                }
                if (!id.value.isValidDocumentid) {
                  errors.add("ID contains a character not a-z, 0-9 or '_'");
                }
                if (errors.isEmpty) {
                  try {
                    craftHost();
                  } catch (e) {
                    print("Fehler beim konvertieren von Host: $e");
                    errors
                        .add("Couldnt convert to Host. Contact the developer.");
                  }
                }
                return errors;
              }

              return Scaffold(
                backgroundColor: cl.darkerGrey,
                appBar: AppBar(
                  title: Text(isEditingHostID == null
                      ? "Create new Host"
                      : isEditingHostID ?? "This should never display"),
                  actions: [
                    IconButton(
                        onPressed: () async {
                          await showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: cl.lighterGrey,
                                  content: FutureBuilder(
                                      future: verifyHostUpload(),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<List<String>> errors) {
                                        if (errors.connectionState !=
                                            ConnectionState.done) {
                                          return cw.LoadingIndicator(
                                              color: Colors.white);
                                        } else {
                                          if (errors.data!.isEmpty) {
                                            Host hostToUpload = craftHost();
                                            return FutureBuilder(
                                                future: Future.delayed(
                                                        Duration(seconds: 2))
                                                    .then((as) =>
                                                        db.uploadHost(hostToUpload)),
                                                builder: (context, upload) {
                                                  if (upload.connectionState !=
                                                      ConnectionState.done) {
                                                    return Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: const [
                                                        Text("Upload is valid!",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white)),
                                                        Text(
                                                            "Uploading now....",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white)),
                                                        cw.LoadingIndicator(
                                                            color: Colors.white)
                                                      ],
                                                    );
                                                  } else {
                                                    return Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                              "Upload successfull!",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white)),
                                                          TextButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                                toNotify.value[
                                                                        hostToUpload
                                                                            .id] =
                                                                    hostToUpload
                                                                        .name;
                                                                toNotify
                                                                    .notifyListeners();
                                                              },
                                                              child: Text(
                                                                  "Finish",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white)))
                                                        ]);
                                                  }
                                                });
                                          } else {
                                            List<Widget> errorwidgets = errors
                                                .data!
                                                .map((e) => Text(e,
                                                    style: TextStyle(
                                                        color: Colors.white)))
                                                .toList();
                                            errorwidgets.add(TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text(
                                                    "Press here to go back",
                                                    style: TextStyle(
                                                        color: Colors.white))));
                                            return Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: errorwidgets);
                                          }
                                        }
                                      }),
                                );
                              });
                        },
                        icon: Icon(Icons.save))
                  ],
                ),
                body: Column(
                  children: [
                    ListTile(
                        trailing: TextButton(
                          child: ValueListenableBuilder(
                              valueListenable: name,
                              builder: (context, nameValue, foo) {
                                return Text(
                                    nameValue.isEmpty
                                        ? "No Name Set"
                                        : nameValue,
                                    style: TextStyle(color: Colors.white));
                              }),
                          //! Continue Here
                          onPressed: () {
                            showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (BuildContext context) =>
                                    cw.SimpleStringEditDialog(to_notify: name));
                          },
                        ),
                        title: Text("Name",
                            style: TextStyle(color: Colors.white))),
                    ListTile(
                        trailing: isEditingHostID == null
                            ? TextButton(
                                child: ValueListenableBuilder(
                                    valueListenable: id,
                                    builder: (context, idValue, foo) {
                                      return Text(
                                          idValue.isEmpty
                                              ? "No Name Set"
                                              : idValue,
                                          style:
                                              TextStyle(color: Colors.white));
                                    }),
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (BuildContext context) =>
                                          cw.SimpleStringEditDialog(
                                              to_notify: id));
                                },
                              )
                            : Text(id.value,
                                style: TextStyle(color: Colors.white)),
                        title:
                            Text("ID", style: TextStyle(color: Colors.white))),
                    ListTile(
                        trailing: ValueListenableBuilder(
                            valueListenable: category,
                            builder: (context, categoryValue, foo) {
                              return DropdownButton(
                                dropdownColor: cl.lighterGrey,
                                value: categoryValue,
                                items: HostCategory.values
                                    .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e.name,
                                            style: TextStyle(
                                                color: Colors.white))))
                                    .toList(),
                                onChanged: (value) {
                                  category.value = value;
                                },
                              );
                            }),
                        title: Text("Category",
                            style: TextStyle(color: Colors.white))),
                    ListTile(
                        trailing: Text(
                            logopath.value?.replaceAll(
                                    "gs://ravestreammobileapp.appspot.com/",
                                    "") ??
                                "No Logopath set.",
                            style: TextStyle(color: Colors.white)),
                        title: Text("Logopath",
                            maxLines: null,
                            softWrap: true,
                            style: TextStyle(color: Colors.white))),
                    ListTile(
                        trailing: ValueListenableBuilder(
                            valueListenable: permit,
                            builder: (context, permitValue, foo) {
                              return DropdownButton(
                                  dropdownColor: cl.lighterGrey,
                                  value: permitValue,
                                  onChanged: (value) {
                                    permit.value = value ?? permit.value;
                                  },
                                  items: const [
                                    DropdownMenuItem(
                                        value: true,
                                        child: Text("Yes",
                                            style: TextStyle(
                                                color: Colors.white))),
                                    DropdownMenuItem(
                                        value: false,
                                        child: Text("No",
                                            style:
                                                TextStyle(color: Colors.white)))
                                  ]);
                            }),
                        title: Text("Permit:",
                            style: TextStyle(color: Colors.white))),
                    ListTile(
                        trailing: ValueListenableBuilder(
                            valueListenable: official_logo,
                            builder: (context, officiallogoValue, foo) {
                              return DropdownButton(
                                  dropdownColor: cl.lighterGrey,
                                  value: officiallogoValue,
                                  onChanged: (value) {
                                    official_logo.value = value ?? permit.value;
                                  },
                                  items: const [
                                    DropdownMenuItem(
                                        value: true,
                                        child: Text("Yes",
                                            style: TextStyle(
                                                color: Colors.white))),
                                    DropdownMenuItem(
                                        value: false,
                                        child: Text("No",
                                            style:
                                                TextStyle(color: Colors.white)))
                                  ]);
                            }),
                        title: Text("Official Logo",
                            style: TextStyle(color: Colors.white))),
                    ListTile(
                        trailing: Text("${links.value.length} link(s).",
                            style: TextStyle(color: Colors.white)),
                        title: Text("Links",
                            style: TextStyle(color: Colors.white)))
                  ],
                ),
              );
            }
          }
        });
  }
}

/// Screen "Media" in  Management Tab
class MediaScreen extends StatelessWidget {
  const MediaScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: ManagingScreensDrawer(),
        appBar: AppBar(centerTitle: true, title: Text("Media")),
        body: Placeholder());
  }
}

final scaffoldKey = GlobalKey<ScaffoldState>();

/// Maps currently selected Screen to body of the scaffold
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
