// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/debugsettings.dart';
import 'package:ravestreamradioapp/filesystem.dart' as files;
import 'package:ravestreamradioapp/screens/homescreen.dart' as home;
import 'package:ravestreamradioapp/shared_state.dart';
import 'testdbscenario.dart';
import 'package:ravestreamradioapp/extensions.dart'
    show Queriefy, pprint, JsonSafe;
import 'dart:convert';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_functions/cloud_functions.dart' as fn;

var db = FirebaseFirestore.instance;

/// Adds dbc.demoUser to database of current branch
///
/// (Deprecated)
Future addTestUser() async {
  await db
      .collection("${branchPrefix}users")
      .doc(dbc.demoUser.username)
      .set(dbc.demoUser.toMap())
      .then((value) {
    pprint("Users set");
  });
  return Future.delayed(Duration.zero);
}

/// Adds dbc.demoEvent to database of current branch
///
/// (Deprecated)
Future addTestEvent() async {
  /*pprint(
      "demoEvent guestlist Runtime Type: ${dbc.demoEvent.guestlist.runtimeType}");*/
  await db
      .collection("${branchPrefix}events")
      .doc(dbc.demoEvent.eventid)
      .set(dbc.demoEvent.toMap())
      .then((value) {
    pprint("Events Set");
  });
  return Future.delayed(Duration.zero);
}

/// adds dbc.demoGroup to database of current branch
///
/// (Deprecated)
Future addTestGroup() async {
  await db
      .collection("${branchPrefix}groups")
      .doc(dbc.demoGroup.groupid)
      .set(dbc.demoGroup.toMap())
      .then((value) {
    pprint("Groups set");
  });
  return Future.delayed(Duration.zero);
}

/// Uploads event to database
///
/// Also adds it to the events list of the host automatically
Future uploadEventToDatabase(dbc.Event event) async {
  final storage = FirebaseStorage.instanceFor(app: app);
  await db
      .collection("${branchPrefix}events")
      .doc(event.eventid)
      .set(event.toMap());
  if (event.hostreference != null) {
    Map<String, dynamic>? hostdata = await event.hostreference!
        .get()
        .then((value) => value.data() as Map<String, dynamic>);
    if (hostdata == null) {
      return Future.delayed(Duration.zero);
    }
    List hostedevents = hostdata["events"];
    hostedevents.add(db.doc("${branchPrefix}events/${event.eventid}"));
    hostdata["events"] = hostedevents;
    event.hostreference!.set(hostdata);
  }
  Map eventIndexFile = await json.decode(
      await readEventIndexesJson().then((value) => value.fromDBSafeString));
  dbc.Event? eventBefore = eventIndexFile.containsKey(event.eventid)
      ? dbc.Event.fromMap(eventIndexFile[event.eventid])
      : null;
  eventIndexFile[event.eventid] = event.toJsonCompatibleMap();
  List<Future> futures = [];
  futures.add(storage.ref("indexes/${branchPrefix}eventsIndex.json").putString(
      eventMapToJson(forceStringDynamicMapFromObject(eventIndexFile)).dbsafe));
  if (eventBefore != null) {
    futures.add(addLogEntry(
        "Updated Event ${eventBefore.toString()} => ${eventIndexFile[event.eventid].toString()}",
        category: LogEntryCategory.event,
        action: LogEntryAction.update));
  } else {
    futures.add(addLogEntry(
        "Added Event ${eventIndexFile[event.eventid].toString()}",
        category: LogEntryCategory.event,
        action: LogEntryAction.add));
  }
  futures.add(addEventToIndexFile(event));
  await Future.wait(futures);
  return;
}

/// Adds demoevents, demousers and demogroups to current branch.
///
/// Testscenario is in lib\testdbscenario.dart
Future setTestDBScenario() async {
  testuserlist.forEach((element) async {
    await db
        .doc("${branchPrefix}users/${element.username}")
        .set(element.toMap());
  });
  testgrouplist.forEach((element) async {
    await db
        .doc("${branchPrefix}groups/${element.groupid}")
        .set(element.toMap());
  });
  testeventlist.forEach((dbc.Event element) async {
    await uploadEventToDatabase(element);
  });
  return Future.delayed(Duration.zero);
}

/// TBA for Web
/// Returns Failed attempt on Web until Filesystem alternative is worked out
/// Only typesafe on web, doesnt work.
Future<dbc.User?> tryUserLogin(String username, String password) async {
  try {
    if (username.isEmpty || password.isEmpty) {
      return null;
    }
    DocumentSnapshot<Map<String, dynamic>> doc =
        await db.doc("${branchPrefix}users/$username").get();

    if (doc.data() == null) {
      return null;
    }
    if (doc["password"] != password) {
      return null;
    }
    dbc.User constructedUser = dbc.User.fromMap(doc.data() ?? {});
    if (fcmToken != null && !constructedUser.deviceTokens.contains(fcmToken)) {
      constructedUser.deviceTokens.add(fcmToken!);
      db.doc(constructedUser.path).update({
        "deviceTokens": FieldValue.arrayUnion([fcmToken])
      });
    }
    return constructedUser;
  } catch (e) {
    pprint(e);
  }
}

/// Tries to login with saved login credrntials
///
/// Returns dbc.User Object if successfull, null on fail
///
/// TBA for web, only typesafe, defaults to failed login on web
Future<dbc.User?> doStartupLoginDataCheck() async {
  //Uncomment the following line to manually change the saved logindata
  //await files.writeLoginData("", "");
  //Uncomment the following line to manually add an event
  //await setTestDBScenario();
  //pprint(await saveEventToUserReturnWasSaved(dbc.demoEvent, dbc.demoUser));
  //await db.doc("dev.users/admin").set(testuserlist.first.toMap());
  Map savedlogindata = kIsWeb
      ? await files.readLoginDataWeb()
      : await files.readLoginDataMobile();
  //return await tryUserLogin(savedlogindata["username"], savedlogindata["password"]);
  return await tryUserLogin(
      savedlogindata["username"], savedlogindata["password"]);
}

/// Fetch User from database
Future<dbc.User?> getUser(String username) async {
  if (username.isEmpty) return null;
  if (username == currently_loggedin_as.value?.username) {
    AggregateQuerySnapshot snap = await db
        .collection("${branchPrefix}users")
        .where("username", isEqualTo: currently_loggedin_as.value!.username)
        .where("lastEditedInMs",
            isGreaterThan: currently_loggedin_as.value!.lastEditedInMs)
        .count()
        .get();
    print("Docs with equal name and lastedtedInMs: ${snap.count}");
    if (snap.count == 0) {
      print("UserObject on Track. No db snapshot needed.");

      return currently_loggedin_as.value;
    }
  }
  DocumentSnapshot userdoc =
      await db.doc("${branchPrefix}users/$username").get();
  if (userdoc.exists && userdoc.data() != null) {
    print("UserObject not on Track. DB snapshot needed.");
    if (username == currently_loggedin_as.value?.username) {
      currently_loggedin_as.value!.lastEditedInMs =
          Timestamp.now().millisecondsSinceEpoch;
      print("Current User Check updated.!");
    }
    return dbc.User.fromMap(userdoc.data() as Map<String, dynamic>);
  } else {
    return null;
  }
}

/// Returns total count of Events ending after today
/// TBA Get event count from given query, not only default query
Future<int> getEventCount() async {
  int itemcount = await db
      .collection("${branchPrefix}events")
      .where("end", isGreaterThanOrEqualTo: Timestamp.now())
      .count()
      .get()
      .then((value) => value.count);
  return itemcount;
}

/// Deprecated (use readEventsFromIndexFile instead)
///
/// General Query to get List of Events
///
/// Query filters can be specified by the [filters] parameter
///
/// Query size can be specified by the [queryLimit] param
Future<List<dbc.Event>> getEvents() async {
  Query query = db.collection("${branchPrefix}events");
  QuerySnapshot snapshot = await query.get();
  List<Map<String, dynamic>>? maplist = querySnapshotToMapList(snapshot);
  print("Maplist: ${maplist.length}");
  List<dbc.Event> events = [];
  maplist.forEach((element) {
    events.add(dbc.Event.fromMap(element));
  });
  return events;
}

///
/// [lastelemEventid] is used as a cursor for paginating results. Leaving it empty means you are at page 0.
///
/// When set, [onlyAfter] filters to only show Events that end after the given Timestamp.
/// This is an Inequality Field.
///
/// When set, [onlyBefore] filters to only show Events that begin before the given Timestamp.
/// This is an Inequality Field.
///
/// When Set, [canGoByAge] filters to only show Events allowing people with given age entry.
/// This is an Inequality Field.
///
/// Only one of the Inequality fields can be used. If more are set, none get set.
///
/// Set [orderbyField] to the name of the field you want to order by.
///
/// Class that contains all possible event filters
///
/// [lastelemEventid] is for paginating query results
///
/// Provide a List<Array>[byStatus] to only include Events with a status in this array. Leaving this empty includes Events of all stati
class EventFilters {
  String? lastelemEventid;
  Timestamp? onlyAfter;
  Timestamp? onlyBefore;
  int? canGoByAge;
  String orderbyField;
  List<String> byStatus;
  bool onlyHostedByMe;
  String? searchString;
  List<String>? fromIDList;
  EventFilters(
      {this.lastelemEventid,
      this.onlyAfter,
      this.onlyBefore,
      this.canGoByAge = 18,
      this.orderbyField = "end",
      required this.byStatus,
      this.onlyHostedByMe = false,
      this.searchString,
      this.fromIDList});

  @override
  String toString() {
    return 'Filter(lastelemEventid: $lastelemEventid, onlyAfter: ${timestamp2readablestamp(onlyAfter)}, onlyBefore: ${timestamp2readablestamp(onlyBefore)}, canGoByAge: $canGoByAge, orderByField: $orderbyField, byStatus: $byStatus, onlyHostedByMe: $onlyHostedByMe, searchString: $searchString)';
  }
}

/// Gets the list of events for current branch from firestore.
Future<List<dbc.Event>> fetchEventsFromIndexFile(BuildContext context) async {
  await getRemoteConfig();
  if (!kIsWeb &&
      remoteConfigValues.value != null &&
      remoteConfigValues.value!.versioncode > VERSIONCODE) {
    await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => WillPopScope(
              onWillPop: () async {
                return false;
              },
              child: AlertDialog(
                backgroundColor: cl.darkerGrey,
                title: Center(child: Text("Outdated App!", style: cl.df)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Your app isn't the newest version.", style: cl.df),
                    Text("You have to update it.", style: cl.df),
                    TextButton(
                        onPressed: () async {
                          if (Platform.isAndroid) {
                            if (!await canLaunchUrl(Uri.parse(remoteConfigValues
                                .value!.downloadLinks["android"]))) ;
                            await launchUrl(
                                Uri.parse(remoteConfigValues
                                    .value!.downloadLinks["android"]),
                                mode: LaunchMode.externalApplication);
                          }
                          if (Platform.isIOS) {
                            if (!await canLaunchUrl(Uri.parse(remoteConfigValues
                                .value!.downloadLinks["ios"]))) ;
                            await launchUrl(
                                Uri.parse(remoteConfigValues
                                    .value!.downloadLinks["ios"]),
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Text("Download!",
                            style: TextStyle(color: Colors.red)))
                  ],
                ),
              ),
            ));
  }
  String eventIndexesJson = await readEventIndexesJson();
  List<dbc.Event> eventList = getEventListFromIndexes(eventIndexesJson.dbsafe);
  AggregateQuery eventsInDB =
      await db.collection("${branchPrefix}events").count();
  int docsInDB = await eventsInDB.get().then((value) => value.count);
  print("@db Events detected in Index file: ${eventList.length}");
  print("@db Events detected in Database: $docsInDB");
  /*eventList.forEach((element) {
    pprint(element.status);
  });*/
  if (eventList.length != docsInDB) {
    print(
        "@db Eventcount in db and index file doesnt match.\nPerforming self-diagnostic fix.");
    List<dbc.Event> events = await getEvents();
    print("Fetched Events: ${events.length}");
    String jsonindexString =
        eventMapToJson(eventListToJsonCompatibleMap(events));
    await writeEventIndexes(jsonindexString.dbsafe);
    await Future.delayed(Duration(seconds: 1));
    return await fetchEventsFromIndexFile(context);
  }
  return eventList;
}

/// Filter and order the list of events
List<dbc.Event> queriefyEventList(List<dbc.Event> events, EventFilters filters,
    [int? queryLimit]) {
  List<dbc.Event> eventList = events;
  if (filters.searchString != null) {
    eventList = eventList.whereContainsString(filters.searchString ?? "");
  }
  if (filters.fromIDList != null) {
    eventList = eventList.whereIsInIDList(filters.fromIDList ?? []);
  }

  List<dbc.Event> buffer = [];
  eventList.forEach((element) {
    if (element.end != null &&
        element.end!.millisecondsSinceEpoch >
            Timestamp.now().millisecondsSinceEpoch) {
      buffer.add(element);
    } else if (element.end == null && element.begin != null) {
      if (element.begin!
              .toDate()
              .add(Duration(hours: 12))
              .millisecondsSinceEpoch >
          Timestamp.now().millisecondsSinceEpoch) {
        buffer.add(element);
      }
    }
  });
  eventList = buffer;
  eventList = eventList.whereIsInValues("status", filters.byStatus);
  if (filters.canGoByAge != null) {
    eventList =
        eventList.whereIsLessThanOrEqualTo("minAge", filters.canGoByAge);
  }
  if (filters.onlyHostedByMe) {
    List<dbc.Event> newList = [];
    eventList.forEach((element) {
      if (element.hostreference != null &&
          currently_loggedin_as.value != null) {
        if (element.hostreference!.path.contains("users/")) {
          if (element.hostreference!.id ==
              currently_loggedin_as.value!.username) {
            newList.add(element);
          }
        } else if (element.hostreference!.path.contains("events/")) {
          /// TBA For after Groups are done
        }
      }
      if (element.templateHostID != null &&
          doIHavePermission(GlobalPermission.MANAGE_EVENTS)) {
        newList.add(element);
      }
    });
    eventList = newList;
  }
  if (filters.byStatus == ["draft"]) {
  } else {
    eventList.sort((a, b) {
      int sort_a = 0;
      int sort_b = 0;
      if (a.end != null) {
        sort_a = a.end!.millisecondsSinceEpoch;
      }
      if (a.begin != null) {
        sort_a = a.begin!.millisecondsSinceEpoch;
      }
      if (b.end != null) {
        sort_b = b.end!.millisecondsSinceEpoch;
      }
      if (b.begin != null) {
        sort_b = b.begin!.millisecondsSinceEpoch;
      }
      return sort_a.compareTo(sort_b);
    });
  }
  return eventList;
}

/// Gets info from
Future<Map<String, bool>?> getEventUserspecificData(
    dbc.Event event, dbc.User? currentuser) async {
  Map<String, bool> data = {
    "user_has_saved": false,
    "user_can_edit": false,
  };
  if (currentuser == null) {
    return null;
  }
  if (currentuser.saved_events
      .contains(db.doc("${branchPrefix}events/${event.eventid}"))) {
    data["user_has_saved"] = true;
  }
  if (event.hostreference ==
      db.doc("${branchPrefix}users/${currentuser.username}")) {
    data["user_can_edit"] = true;
  }
  return data;
}

/// Returns true if [user] has the [event] saved
bool isEventSaved(dbc.Event event, dbc.User? user) {
  if (user == null) {
    return false;
  }
  for (int i = 0; i < user.saved_events.length; i++) {
    if (user.saved_events[i].id.contains(event.eventid)) {
      return true;
    }
  }
  return false;
}

/// Add [event] to [user]'s saved events list
///
/// Returns whether the event was saved before
Future<bool> saveEventToUserReturnWasSaved(
    dbc.Event event, dbc.User? user) async {
  if (user == null) {
    return false;
  }
  Map<String, bool>? event_userspecific_data =
      await getEventUserspecificData(event, user);
  List<DocumentReference> saved_events = user.saved_events;
  if (event_userspecific_data!["user_has_saved"] ?? false) {
    saved_events.remove(db.doc("${branchPrefix}events/${event.eventid}"));
  } else {
    saved_events.add(db.doc("${branchPrefix}events/${event.eventid}"));
  }
  DocumentSnapshot usersnap =
      await db.doc("${branchPrefix}users/${user.username}").get();
  if (usersnap.data() == null) {
    return false;
  }
  Map<String, dynamic> updatedData =
      usersnap.data() as Map<String, dynamic>? ?? {};
  if (updatedData == {}) {
    return false;
  }
  dbc.User updatedUserData = dbc.User.fromMap(updatedData);
  updatedUserData.saved_events = saved_events;
  db
      .doc("${branchPrefix}users/${updatedUserData.username}")
      .set(updatedUserData.toMap());
  if (currently_loggedin_as.value != null &&
      currently_loggedin_as.value!.username == user.username) {
    currently_loggedin_as.value!.saved_events = updatedUserData.saved_events;
  }
  return event_userspecific_data["user_has_saved"] ?? false;
}

/// Gets event from database
Future<dbc.Event?> getEvent(String eventid) async {
  for (int i = 0; i < saved_events.length; i++) {
    if (saved_events[i].eventid == eventid) return saved_events[i];
  }
  DocumentSnapshot snap = await db.doc("${branchPrefix}events/$eventid").get();
  if (snap.exists && snap.data() != null) {
    return dbc.Event.fromMap(snap.data() as Map<String, dynamic>);
  }
  return null;
}

/// Returns a list of groups the given [username] has joined
Future<List<dbc.Group>> showJoinedGroupsForUser(String username) async {
  dbc.User? user = await getUser(username);
  if (user == null) return [];
  List<DocumentReference> docrefs = user.joined_groups;
  List<dbc.Group> groups = [];

  for (int i = 0; i < docrefs.length; i++) {
    dbc.Group singlegroup = await dbc.Group.fromMap(await docrefs[i]
        .get()
        .then((value) => value.data() as Map<String, dynamic>));
    groups.add(singlegroup);
  }
  return groups;
}
/*
bool userIsAdminOfGroup(dbc.User user, String groupid) {
  for (int i = 0; i < user.joined_groups.length; i++) {
    DocumentReference docRef = user.joined_groups[i];
    if (docRef.id)
  }
}
*/

/// Returns whether [user] has given group pinned or not
bool hasGroupPinned(dbc.Group group, dbc.User user) {
  for (int i = 0; i < user.pinned_groups.length; i++) {
    if (user.pinned_groups[i].id == group.groupid) {
      return true;
    }
  }
  return false;
}

/// Checks if currently loggedin user has a certain permission
///
/// Return false if user is not logged in
bool doIHavePermission(GlobalPermission permit) {
  if (currently_loggedin_as.value == null) return false;
  if (dbc
      .dbPermissionsToGlobal(currently_loggedin_as.value!.permissions)
      .contains(GlobalPermission.ADMIN)) return true;
  return dbc
      .dbPermissionsToGlobal(currently_loggedin_as.value!.permissions)
      .contains(permit);
}

Future<dbc.Event?> currentlyEditedEvent(String? eventid) async {
  return eventid == null ? null : getEvent(eventid);
}

/// Returns if currently loggedin user has permission to edit given [event]
bool hasPermissionToEditEventObject(dbc.Event event) {
  if (currently_loggedin_as.value == null) {
    return false;
  }
  if (doIHavePermission(GlobalPermission.MANAGE_EVENTS) &&
      event.templateHostID != null &&
      event.templateHostID!.isNotEmpty) {
    return true;
  }
  if (currently_loggedin_as.value!.events
      .contains("${branchPrefix}events/${event.eventid}")) {
    return true;
  }
  if (event.hostreference != null &&
      event.hostreference!.id == currently_loggedin_as.value!.username) {
    return true;
  }
  return false;
}

/// Return if currently logged in user has permission to edit event
Future<bool> hasPermissionToEditEvent(String eventID) async {
  if (currently_loggedin_as.value == null) {
    return false;
  }
  if (doIHavePermission(GlobalPermission.MANAGE_EVENTS)) {
    dbc.Event? event = await getEvent(eventID);
    if (event == null) return false;
    if (event.templateHostID != null) {
      return true;
    }
  }
  dbc.Event? event = await getEvent(eventID);
  if (event == null) return false;
  return isEventHostedByUser(event, currently_loggedin_as.value);
}

/// Get list of Hosts presaved by the calendar team
Future<List<dbc.Host>> getDemoHosts() async {
  if (doIHavePermission(GlobalPermission.MANAGE_HOSTS) ||
      doIHavePermission(GlobalPermission.MANAGE_EVENTS)) {
    QuerySnapshot query =
        await db.collection("demohosts").orderBy("name").get();
    List<Map<String, dynamic>> queryMaps = querySnapshotToMapList(query);
    List<dbc.Host> hosts = [];
    queryMaps.forEach((element) {
      hosts.add(dbc.Host.fromMap(element));
    });
    return hosts;
  } else {
    return [];
  }
}

/// Include Document IDS as parameter in every Demohosts document
Future writeIDStoDemoHosts() async {
  if (doIHavePermission(GlobalPermission.MANAGE_HOSTS) ||
      doIHavePermission(GlobalPermission.MANAGE_EVENTS)) {
    List<DocumentSnapshot> docs =
        await db.collection("demohosts").get().then((value) => value.docs);
    List<Future> calllist = [];
    docs.forEach((DocumentSnapshot element) {
      calllist.add(db
          .collection("demohosts")
          .doc(element.id)
          .update({"id": element.id}));
    });
    await Future.wait(calllist);
    return;
  }
  return;
}

/// Copy a collection
Future createCopyOfCollection(String collectionToCopyID,
    String destinationCollectionID, BuildContext context) async {
  CollectionReference collection = db.collection(collectionToCopyID);
  int collectionSizeInDocuments =
      await collection.count().get().then((value) => value.count);
  QuerySnapshot collectionQuery = await collection.get();
  ValueNotifier<int> doneFiles = ValueNotifier<int>(-1);
  bool proceed = false;
  await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Costs"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Document Reads: $collectionSizeInDocuments"),
              Text("Document Writes: $collectionSizeInDocuments")
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  doneFiles.value = 0;
                  proceed = true;
                  Navigator.of(context).pop();
                },
                child: Text("Proceed")),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Cancel"))
          ],
        );
      });
  if (!proceed) return;
  showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return ValueListenableBuilder(
            valueListenable: doneFiles,
            builder: (context, value, child) {
              return AlertDialog(
                content: Text("$value/$collectionSizeInDocuments done"),
                actions: [
                  TextButton(
                      onPressed: () {
                        if (value == collectionSizeInDocuments) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text("Finish!"))
                ],
              );
            });
      });
  List<Map<String, dynamic>> collectionMap =
      querySnapshotToMapList(collectionQuery, include_documentid: true); //####
  collectionMap.forEach((element) async {
    String? docid = element["documentidcarryover"];
    if (element.containsKey("documentidcarryover"))
      element.remove("documentidcarryover");
    await db
        .collection(destinationCollectionID)
        .doc(element["uniqueDocID"])
        .set(element);
    doneFiles.value += 1;
  });
  return;
}

/// Get list of all documentIDS from a collection
Future<Map<String, String>> getDocIDsFromCollectionAsList(
    String collection) async {
  CollectionReference colRef = db.collection(collection);
  QuerySnapshot qSnap = await colRef.get();
  Map<String, String> docIDs = {};
  qSnap.docs.forEach((element) {
    docIDs[element.id] = element["name"] ?? "No name";
  });
  return docIDs;
}

/// Get demohost Ids
Future<Map<String, String>> getDemoHostIDs() async {
  DocumentSnapshot indexesSnap = await db.doc("content/indexes").get();
  if (indexesSnap.data() != null) {
    return forceStringStringMapFromStringDynamic(
            indexesSnap["templateHostIDs"]) ??
        {};
  }
  return {};
}

/// Write the database events to the index.json
Future writeEventIndexes(String eventjsonstring) async {
  Reference storageRef = FirebaseStorage.instance.ref();
  Reference pathReference =
      storageRef.child("indexes/${branchPrefix}eventsIndex.json");
  UploadTask task = pathReference.putString(eventjsonstring.dbsafe);
  await task;
  if (!kIsWeb) {
    await files.writeIndexFile(
        "${branchPrefix}eventsIndex.json", json.decode(eventjsonstring));
  }
  return;
}

Future<String?> checkForNewerCachedIndexFile(String filename) async {
  if (kIsWeb) return null;
  Reference storageRef = FirebaseStorage.instance.ref();
  Reference pathReference = storageRef.child("indexes/$filename");
  DateTime? cachedIndexFileLastWritten =
      await files.getSavedIndexFileLastChanged(filename);
  //String? cachedIndexFileContent = await files.getSavedIndexFile(filename);
  print("Cached event last written: $cachedIndexFileLastWritten");
  DateTime? serverLastUpdated =
      await pathReference.getMetadata().then((value) => value.updated);
  if (cachedIndexFileLastWritten != null &&
      serverLastUpdated != null &&
      cachedIndexFileLastWritten.millisecondsSinceEpoch >
          serverLastUpdated.millisecondsSinceEpoch) {
    print("Cached Event File is newer!");
    return await files.getSavedIndexFile(filename);
  } else {
    return null;
  }
}

/// Read the index.json
Future<String> readEventIndexesJson() async {
  String filename = "${branchPrefix}eventsIndex.json";
  Reference storageRef = FirebaseStorage.instance.ref();
  Reference pathReference = storageRef.child("indexes/$filename");
  if (!kIsWeb) {
    String? indexFilecontent = await checkForNewerCachedIndexFile(filename);
    if (indexFilecontent != null) {
      return indexFilecontent;
    }
  }
  Stopwatch stop = Stopwatch()..start();
  Uint8List? data = await pathReference.getData(100 * 1024 * 1024);
  String newerData =
      String.fromCharCodes(data ?? Uint8List.fromList([0])).fromDBSafeString;
  if (!kIsWeb) {
    await files.writeIndexFile(filename, json.decode(newerData));
  }
  return newerData;
}

/// Read the event list from a index.json in String format
List<dbc.Event> getEventListFromIndexes(String indexJsonString) {
  Map<String, dynamic> indexMap = json.decode(indexJsonString.fromDBSafeString);
  List<dbc.Event> eventlist = [];
  indexMap.keys.forEach((element) {
    eventlist.add(dbc.Event.fromJson(json.encode(indexMap[element])));
  });
  return eventlist;
}

Future<int> getFiledReportCount() async {
  int itemcount = await db
      .collection("${branchPrefix}reports")
      .where("state", isEqualTo: "filed")
      .count()
      .get()
      .then((value) => value.count);
  return itemcount;
}

Future<int> getPendingReportCount() async {
  int itemcount = await db
      .collection("${branchPrefix}reports")
      .where("state", isEqualTo: "pending")
      .count()
      .get()
      .then((value) => value.count);
  return itemcount;
}

Future<Map<String, int>> getOpenReportsCount() async {
  Map<String, int> values = {
    "filed": await getFiledReportCount(),
    "pending": await getPendingReportCount()
  };
  return values;
}

Future<List<dbc.Report>> getAllReports() async {
  List<dbc.Report> reports = [];
  QuerySnapshot snap = await db.collection("${branchPrefix}reports").get();
  snap.docs.forEach((element) {
    Map<String, dynamic> map =
        forceStringDynamicMapFromObject(element.data() ?? {});
    map["id"] = element.id;
    reports.add(dbc.Report.fromMap(map));
  });
  return reports;
}

Future<dbc.Host?> loadDemoHostFromDB(String id) async {
  DocumentSnapshot docRef = await db.doc("demohosts/$id").get();
  if (docRef.exists && docRef.data() != null) {
    Map<String, dynamic> map =
        forceStringDynamicMapFromObject(docRef.data() ?? {});
    return dbc.Host.fromMap(map);
  } else {
    return null;
  }
}

Future uploadHost(dbc.Host host) async {
  DocumentReference ref = db.doc("demohosts/${host.id}");
  DocumentSnapshot snap = await ref.get();
  Map? beforeHost = snap.exists ? snap.data() as Map : null;
  // Add it to the index tracker
  DocumentSnapshot snap2 = await db.doc("content/indexes").get();
  Map<String, dynamic> map =
      forceStringDynamicMapFromObject(snap2.data() as Map);
  Map<String, dynamic> jgkh = map["templateHostIDs"];
  jgkh[host.id] = host.name;

  List<Future> futures = [];
  futures.add(ref.set(host.toMap()));
  futures.add(db.doc("content/indexes").update({"templateHostIDs": jgkh}));
  if (beforeHost != null) {
    dbc.Host before =
        dbc.Host.fromMap(forceStringDynamicMapFromObject(beforeHost));
    futures.add(addLogEntry(
        "Updated Host : ${before.toString()} => ${host.toMap()}",
        category: LogEntryCategory.host,
        action: LogEntryAction.update));
  } else {
    futures.add(addLogEntry("Added Host : ${host.toMap()}",
        category: LogEntryCategory.host, action: LogEntryAction.add));
  }
  return Future.wait(futures);
}

Future deleteHost(String hostID) async {
  DocumentSnapshot snap = await db.doc("content/indexes").get();
  Map<String, dynamic> map =
      forceStringDynamicMapFromObject(snap.data() as Map);
  Map<String, dynamic> jgkh = map["templateHostIDs"];
  jgkh.remove(hostID);
  List<Future> futures = [
    db.doc("demohosts/$hostID").delete(),
    db.doc("content/indexes").update({"templateHostIDs": jgkh}),
    addLogEntry("Deleted Host $hostID",
        category: LogEntryCategory.host, action: LogEntryAction.delete)
  ];
  return;
}

Future<dbc.Group?> getGroup(String groupID) async {
  DocumentSnapshot snap = await db.doc("${branchPrefix}groups/$groupID").get();
  if (snap.exists && snap.data() != null) {
    Map<String, dynamic> data =
        forceStringDynamicMapFromObject(snap.data() as Map);
    data = forceStringDynamicMapFromObject(data);
    return dbc.Group.fromMap(data);
  } else {
    return null;
  }
}

enum LogEntryCategory { host, media, event, report, unknown }

enum LogEntryAction { add, delete, update, unknown }

LogEntryAction string2Act(String name) {
  switch (name) {
    case "add":
      return LogEntryAction.add;
    case "delete":
      return LogEntryAction.delete;
    case "update":
      return LogEntryAction.update;
    default:
      return LogEntryAction.unknown;
  }
}

LogEntryCategory string2Cat(String name) {
  switch (name) {
    case "host":
      return LogEntryCategory.host;
    case "media":
      return LogEntryCategory.media;
    case "event":
      return LogEntryCategory.event;
    case "report":
      return LogEntryCategory.report;
    default:
      return LogEntryCategory.unknown;
  }
}

class LogEntry {
  String changes;
  Timestamp exact_time;
  String user;
  LogEntryCategory category;
  LogEntryAction action;
  LogEntry(
      {required this.changes,
      required this.exact_time,
      required this.user,
      required this.category,
      required this.action});
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'changes': changes,
      'exact_time': exact_time.millisecondsSinceEpoch,
      'user': user,
      'category': category.name,
      'action': action.name
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
        changes: map["changes"],
        exact_time: map["exact_time"].fromMillisecondsSinceEpoch,
        user: map["user"],
        category: string2Cat(map["category"]),
        action: string2Act(map["action"]));
  }
}

Future addLogEntry(String changes,
    {LogEntryCategory category = LogEntryCategory.unknown,
    LogEntryAction action = LogEntryAction.unknown}) async {
  DocumentReference ref = db.doc(currentLogFilePath);
  bool logWeekExists = await ref.get().then((value) => value.exists);
  if (logWeekExists) {
    return await ref.update({
      currentLogFileDay.replaceAll(".", "_"): FieldValue.arrayUnion([
        LogEntry(
                action: action,
                category: category,
                changes: changes,
                exact_time: Timestamp.now(),
                user: currently_loggedin_as.value!.username)
            .toMap()
      ])
    });
  } else {
    return await ref.set({
      currentLogFileDay.replaceAll(".", "_"): [
        LogEntry(
                action: action,
                category: category,
                changes: changes,
                exact_time: Timestamp.now(),
                user: currently_loggedin_as.value!.username)
            .toMap()
      ]
    });
  }
}

Future deleteEvent(String eventID) async {
  return Future.wait([
    db.doc("${branchPrefix}events/$eventID").delete(),
    addLogEntry("Deleted Event: $eventID",
        action: LogEntryAction.delete, category: LogEntryCategory.event),
    removeEventFromIndexFile(null, eventID)
  ]);
}

Future<List<dbc.Group>> queryGroups() async {
  if (currently_loggedin_as.value == null) return [];
  List<DocumentReference> joined_groups =
      currently_loggedin_as.value!.joined_groups;
  List<DocumentReference> followed_groups =
      currently_loggedin_as.value!.followed_groups;
  List<DocumentReference> allGroups = joined_groups..addAll(followed_groups);
  allGroups = allGroups.toSet().toList();
  List<Future<DocumentSnapshot>> futures = [];
  allGroups.forEach((element) {
    futures.add(element.get());
  });
  List<DocumentSnapshot> snaps = await Future.wait(futures);
  List<dbc.Group> groups = snaps
      .map((e) =>
          dbc.Group.fromMap(forceStringDynamicMapFromObject(e.data() as Map)))
      .toList();
  return groups;
}

Future createUserIndexFiles() async {
  QuerySnapshot snaps = await db.collection("${branchPrefix}users").get();
  List<dbc.User> list = snaps.docs
      .map((QueryDocumentSnapshot e) =>
          dbc.User.fromMap(forceStringDynamicMapFromObject(e.data() as Map)))
      .toList();
  Map<String, String> strings = {};
  list.forEach((element) {
    strings[element.username] = element.alias ?? element.username;
  });
  Reference ref =
      FirebaseStorage.instance.ref("/indexes/${branchPrefix}users.json");
  await ref.putString(json.encode(strings).dbsafe);
}

Future addEventToIndexFile(dbc.Event event) async {
  Reference events =
      FirebaseStorage.instance.ref("/indexes/${branchPrefix}events.json");
  String da = await events
      .getData(4096 * 4096)
      .then((value) => String.fromCharCodes(value ?? Uint8List.fromList([])));
  Map eventMap = jsonDecode(da.fromDBSafeString);
  eventMap[event.eventid] = event.title ?? event.eventid;
  return await events.putString(json.encode(eventMap).dbsafe);
}

Future removeEventFromIndexFile([dbc.Event? event, String? id]) async {
  Reference events =
      FirebaseStorage.instance.ref("/indexes/${branchPrefix}events.json");
  String da = await events
      .getData(4096 * 4096)
      .then((value) => String.fromCharCodes(value ?? Uint8List.fromList([])));
  Map eventMap = jsonDecode(da.fromDBSafeString);
  if (eventMap.keys.contains(event?.eventid ?? id)) {
    eventMap.remove(event?.eventid ?? id);
  }
  return await events.putString(json.encode(eventMap).dbsafe);
}

Future addUserToIndexFile(dbc.User user) async {
  Reference users =
      FirebaseStorage.instance.ref("/indexes/${branchPrefix}users.json");
  String da = await users
      .getData(4096 * 4096)
      .then((value) => String.fromCharCodes(value ?? Uint8List.fromList([])));
  Map eventMap = jsonDecode(da.fromDBSafeString);
  eventMap[user.username] = user.alias ?? user.username;
  return await users.putString(json.encode(eventMap).dbsafe);
}

Future removeUserFromIndexFile([dbc.User? user, String? id]) async {
  Reference users =
      FirebaseStorage.instance.ref("/indexes/${branchPrefix}users.json");
  String da = await users
      .getData(4096 * 4096)
      .then((value) => String.fromCharCodes(value ?? Uint8List.fromList([])));
  Map eventMap = jsonDecode(da.fromDBSafeString);
  if (eventMap.keys.contains(user?.username ?? id)) {
    eventMap.remove(user?.username ?? id);
  }
  return await users.putString(json.encode(eventMap).dbsafe);
}

Future addGroupToIndexFile(dbc.Group group) async {
  Reference users =
      FirebaseStorage.instance.ref("/indexes/${branchPrefix}groups.json");
  String da = await users
      .getData(4096 * 4096)
      .then((value) => String.fromCharCodes(value ?? Uint8List.fromList([])));
  Map eventMap = jsonDecode(da.fromDBSafeString);
  eventMap[group.groupid] = group.title ?? group.groupid;
  return await users.putString(json.encode(eventMap).dbsafe);
}

Future removeGroupFromIndexFile([dbc.Group? group, String? id]) async {
  Reference users =
      FirebaseStorage.instance.ref("/indexes/${branchPrefix}groups.json");
  String da = await users
      .getData(4096 * 4096)
      .then((value) => String.fromCharCodes(value ?? Uint8List.fromList([])));
  Map eventMap = jsonDecode(da.fromDBSafeString);
  if (eventMap.keys.contains(group?.groupid ?? id)) {
    eventMap.remove(group?.groupid ?? id);
  }
  return await users.putString(json.encode(eventMap).dbsafe);
}

Future createGroupIndexFiles() async {
  QuerySnapshot snaps = await db.collection("${branchPrefix}groups").get();
  List<dbc.Group> list = snaps.docs
      .map((QueryDocumentSnapshot e) =>
          dbc.Group.fromMap(forceStringDynamicMapFromObject(e.data() as Map)))
      .toList();
  Map<String, String> strings = {};
  list.forEach((element) {
    strings[element.groupid] = element.title ?? element.groupid;
  });
  Reference ref =
      FirebaseStorage.instance.ref("/indexes/${branchPrefix}groups.json");
  await ref.putString(json.encode(strings).dbsafe);
}

Future createEventIndexFiles() async {
  QuerySnapshot snaps = await db.collection("${branchPrefix}events").get();
  List<dbc.Event> list = snaps.docs
      .map((QueryDocumentSnapshot e) =>
          dbc.Event.fromMap(forceStringDynamicMapFromObject(e.data() as Map)))
      .toList();
  Map<String, String> strings = {};
  list.forEach((element) {
    strings[element.eventid] = element.title ?? element.eventid;
  });
  Reference ref =
      FirebaseStorage.instance.ref("/indexes/${branchPrefix}events.json");
  await ref.putString(json.encode(strings).dbsafe);
}

Future<String> getIndexFileContent(String name) async {
  String fileName = name;
  Reference groups = FirebaseStorage.instance.ref("/indexes/$fileName");
  if (!kIsWeb) {
    String? groupCachedFile = await checkForNewerCachedIndexFile(fileName);
    if (groupCachedFile != null) {
      print("Cached File on Device is newer!");
      return groupCachedFile;
    }
  }
  Uint8List data = await groups
      .getData(4096 * 4096)
      .then((value) => value ?? Uint8List.fromList([]));
  if (!kIsWeb) {
    await files.writeIndexFile(
        fileName, json.decode(String.fromCharCodes(data)));
  }
  return String.fromCharCodes(data);
}

Future<List<Map>> getIndexedEntitys() async {
  /*
  String groupsFileName = "${branchPrefix}groups.json";
  String usersFileName = "${branchPrefix}users.json";
  String eventsFileName = "${branchPrefix}events.json";
  Reference groups = FirebaseStorage.instance.ref("/indexes/$groupsFileName");
  Reference users = FirebaseStorage.instance.ref("/indexes/$usersFileName)");
  Reference events = FirebaseStorage.instance.ref("/indexes/$eventsFileName");
  String? groupCachedFile = await checkForNewerCachedIndexFile(groupsFileName);
  String? userCachedFile = await checkForNewerCachedIndexFile(usersFileName);
  String? eventsCachedFile = await checkForNewerCachedIndexFile(eventsFileName);

  List<Future<Uint8List>> futures = [
    users.getData(4096 * 4096).then((value) => value ?? Uint8List.fromList([])),
    events.getData(4096 * 4096).then((value) => value ?? Uint8List.fromList([]))
  ];
  List<Uint8List> lists = await Future.wait(futures);
  List<String> strings = lists.map((e) => String.fromCharCodes(e)).toList();
  return strings.map((e) => jsonDecode(e.fromDBSafeString) as Map).toList();*/
  List<Future<String>> futures = [
    getIndexFileContent("${branchPrefix}groups.json"),
    getIndexFileContent("${branchPrefix}users.json"),
    getIndexFileContent("${branchPrefix}events.json"),
  ];
  List<String> strings = await Future.wait(futures);
  return strings.map((e) => jsonDecode(e.fromDBSafeString) as Map).toList();
}

Future uploadProfilePicture(String username, File file) async {
  String fileExtension = file.path.split(".")[file.path.split(".").length - 1];
  Reference ref = FirebaseStorage.instance.ref("/profilepictures");
  await ref
      .child("${username}")
      .putFile(file, SettableMetadata(contentType: 'image/${fileExtension}'));
  String dldURL = await ref.child("${username}").getDownloadURL();
  await db.doc("${branchPrefix}users/$username").update({
    "profile_picture": dldURL,
    "lastEditedInMs": Timestamp.now().millisecondsSinceEpoch
  });
  return dldURL;
}

Future uploadGroupIcon(String groupid, File file) async {
  String fileExtension = file.path.split(".")[file.path.split(".").length - 1];
  Reference ref = FirebaseStorage.instance.ref("/groupicons");
  await ref
      .child("${groupid}")
      .putFile(file, SettableMetadata(contentType: 'image/${fileExtension}'));
}

Future uploadGroupToDB(dbc.Group group) async {
  if (group.image != null) {
    String fileExtension =
        group.image!.path.split(".")[group.image!.path.split(".").length - 1];
    Reference ref = FirebaseStorage.instance.ref("/groupicons");
    await ref.child("${group.groupid}").putFile(group.image ?? File("oguih"),
        SettableMetadata(contentType: 'image/${fileExtension}'));
  }
  Map map = group.toMap()..remove("image");
  List<Future> futures = [
    db
        .doc("${branchPrefix}groups/${group.groupid}")
        .set(forceStringDynamicMapFromObject(map)),
    addGroupToIndexFile(group),
    db
        .doc("${branchPrefix}users/${currently_loggedin_as.value!.username}")
        .update({
      "joined_groups": FieldValue.arrayUnion(
          [db.doc("${branchPrefix}groups/${group.groupid}")])
    })
  ];
  Future.wait(futures);
  currently_loggedin_as.value!.joined_groups
      .add(db.doc("${branchPrefix}groups/${group.groupid}"));
  return;
}

class PermissionTextButton extends StatelessWidget {
  GlobalPermission permission;
  Color _permToColor(String perm) {
    switch (perm) {
      case "ADMIN":
        return Color.fromARGB(255, 245, 88, 15);
      case "CHANGE_DEV_SETTINGS":
        return Color.fromARGB(255, 4, 211, 238);
      case "MANAGE_EVENTS":
        return Colors.green;
      case "MANAGE_HOSTS":
        return Colors.green;
      case "MODERATE":
        return Colors.purple;
      default:
        return Colors.white;
    }
  }

  String _permToName(String name) {
    switch (name) {
      case "ADMIN":
        return "Admin";
      case "CHANGE_DEV_SETTINGS":
        return "Developer";
      case "MANAGE_EVENTS":
        return "Event-Editor";
      case "MANAGE_HOSTS":
        return "Host-Editor";
      case "MODERATE":
        return "Moderator";
      default:
        return "Permission";
    }
  }

  String _permToTip(String name) {
    switch (name) {
      case "ADMIN":
        return "This user has every Permission, since its his project and server lol. Also the only Person who can give and deny other users Permissions.";
      case "CHANGE_DEV_SETTINGS":
        return "This user has access to developer-only tools and access to the server.";
      case "MANAGE_EVENTS":
        return "This user can manage Events for Hosts in the registry.";
      case "MANAGE_HOSTS":
        return "This user can manage Hosts in the registry.";
      case "MODERATE":
        return "This Person has access to submitted reports, and the ability to ban any kind of content that doesn't comply with our Code of Conduct.";
      default:
        return "Permission";
    }
  }

  PermissionTextButton({required this.permission});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _permToTip(permission.name),
      child: TextButton(
          onPressed: () {},
          child: Text(_permToName(permission.name),
              style: TextStyle(color: _permToColor(permission.name)))),
    );
  }
}

List<Widget> permissionIndicatorsFromPermissions(dbc.User user) {
  return dbc
      .dbPermissionsToGlobal(user.permissions)
      .map((e) => PermissionTextButton(permission: e))
      .toList();
}

Future<RemoteConfig?> getRemoteConfig() async {
  DocumentSnapshot snap = await db.doc("content/remoteconfig").get();
  if (snap.exists && snap.data() != null) {
    Map data = snap.data() as Map;
    if (!data.containsKey("downloadpagelinks") ||
        !data.containsKey("versioncode")) {
      return null;
    }
    RemoteConfig config = RemoteConfig(
        downloadLinks: data["downloadpagelinks"],
        versioncode: data["versioncode"],
        replaceChars: forceStringStringMapFromStringDynamic(
                forceStringDynamicMapFromObject(data["replaceChars"])) ??
            {});
    print("Links: ${config.downloadLinks}");
    print("Version: ${config.versioncode}");
    print("ReplaceChars: ${config.replaceChars}");
    remoteConfigValues.value = config;
    return config;
  } else {
    return null;
  }
}

Future<dbc.Host?> getDemoHost(String templateHostID) async {
  DocumentSnapshot snap = await db.doc("demohosts/$templateHostID").get();
  if (snap.exists && snap.data() != null) {
    try {
      print("HALLO");
      dbc.Host host =
          dbc.Host.fromMap(forceStringDynamicMapFromObject(snap.data() as Map));
      return host;
    } catch (e) {
      print(e);
      return null;
    }
  }
}

Future makeDemoHostsContainInstagramLink() async {
  List<DocumentSnapshot> snap =
      await db.collection("demohosts").get().then((value) => value.docs);
  List<Future> futures = [];
  snap.forEach((doc) {
    if (doc.data() != null) {
      dbc.Host data = dbc.Host.fromMap(
          stringDynamicMapFromDynamicDynamic(doc.data() as Map));
      if (data.links != null) {
        data.links!.forEach((mapentry) {
          if (mapentry.url.contains("instagram")) {
            data.links!.add(dbc.Link(title: "instagram", url: mapentry.url));
            data.links!.remove(mapentry);
          }
        });
      }
      futures.add(db.doc("demohosts/${doc.id}").set(data.toMap()));
    }
  });
  await Future.wait(futures);
  return;
}

Future<bool> doesGroupAlreadyHaveFeedFile(String groupID) async {
  ListResult ref = await files.firebasestorage.ref("feeds/groups").list();
  for (int i = 0; i < ref.items.length; i++) {
    Reference item = ref.items[i];
    if (item.name == "$groupID.json") {
      return true;
    }
  }
  return false;
}

Future createEmptyFeedFileForGroup(String groupID) async {
  await files.firebasestorage
      .ref("feeds/groups/$groupID.json")
      .putString(json.encode({}));
  return;
}

Future addFeedEntryToGroupFeed(String groupID, dbc.FeedEntry entry) async {
  Map? feed = await readGroupFeedListMap(groupID);
  if (feed != null) {
    feed[entry.timestamp.millisecondsSinceEpoch.toString()] = entry.toMap();
    await files.firebasestorage
        .ref("feeds/groups/$groupID.json")
        .putString(json.encode(feed));
  }
  return;
}

Future<Map?> readGroupFeedListMap(String groupID) async {
  bool hasFile = await doesGroupAlreadyHaveFeedFile(groupID);
  if (!hasFile) await createEmptyFeedFileForGroup(groupID);
  Uint8List? data =
      await files.firebasestorage.ref("feeds/groups/$groupID.json").getData();
  if (data == null) return null;
  String dataString = String.fromCharCodes(data);
  print(dataString);
  Map feed = json.decode(dataString.fromDBSafeString);
  print(feed);
  return feed;
}

List<dbc.FeedEntry> feedEntryMapToList(Map map) {
  List<dbc.FeedEntry> ret = [];
  map.entries.forEach((element) {
    ret.add(
        dbc.FeedEntry.fromMap(forceStringDynamicMapFromObject(element.value)));
  });
  return ret;
}

Future deleteUser(String uname, bool deleteEvents) async {
  dbc.User? user = await getUser(uname);
  if (user == null) return;
  if (deleteEvents) {
    List<Future> futures = [];
    user.events.forEach((element) {
      futures.add(element.delete());
    });
    await Future.wait(futures);
    await writeEventIndexes(await readEventIndexesJson());
  } else {
    if (deleteEvents) {
      List<Future> futures = [];
      user.events.forEach((element) {
        futures.add(element.update({"hostreference": null}));
      });
      await Future.wait(futures);
      await writeEventIndexes(await readEventIndexesJson());
    }
  }
  List<Future> futures = [db.doc(user.path).delete()];
  user.topics.forEach((topicname) {
    futures.add(removeUserFromExistingTopic(topicname, user.username));
  });
  return await sync(futures);
}

Future<fn.HttpsCallable> getCallableFunction(String name) async {
  fn.HttpsCallable callable = fn.FirebaseFunctions.instance.httpsCallable(name);
  return callable;
}

Future writeRoleTopicFiles() async {
  QuerySnapshot snap = await db.collection("dev.users").get();
  List<QueryDocumentSnapshot> snaps = snap.docs;
  List<dbc.User> users = snaps
      .map((QueryDocumentSnapshot singleSnap) => dbc.User.fromMap(
          forceStringDynamicMapFromObject(singleSnap.data() ?? {})))
      .toList();
  Map<String, List<String>> ADMIN = {};
  Map<String, List<String>> CHANGE_DEV_SETTINGS = {};
  Map<String, List<String>> MANAGE_EVENTS = {};
  Map<String, List<String>> MANAGE_HOSTS = {};
  Map<String, List<String>> MODERATE = {};
  List<Future> futures = [];
  users.forEach((user) {
    List<String> topicsToAddToThisUser = [];
    if (user.permissions.contains("ADMIN")) {
      ADMIN[user.username] = user.deviceTokens;
      topicsToAddToThisUser.add("role_ADMIN");
    }
    if (user.permissions.contains("CHANGE_DEV_SETTINGS")) {
      CHANGE_DEV_SETTINGS[user.username] = user.deviceTokens;
      topicsToAddToThisUser.add("role_CHANGE_DEV_SETTINGS");
    }
    if (user.permissions.contains("MANAGE_EVENTS")) {
      MANAGE_EVENTS[user.username] = user.deviceTokens;
      topicsToAddToThisUser.add("role_MANAGE_EVENTS");
    }
    if (user.permissions.contains("MANAGE_HOSTS")) {
      MANAGE_HOSTS[user.username] = user.deviceTokens;
      topicsToAddToThisUser.add("role_MANAGE_HOSTS");
    }
    if (user.permissions.contains("MODERATE")) {
      MODERATE[user.username] = user.deviceTokens;
      topicsToAddToThisUser.add("role_MODERATE");
    }
    futures.add(db
        .doc("${branchPrefix}users/${user.username}")
        .update({"topics": FieldValue.arrayUnion(topicsToAddToThisUser)}));
  });
  futures.addAll([
    FirebaseStorage.instance
        .ref("topics/role_ADMIN.json")
        .putString(jsonEncode(ADMIN)),
    FirebaseStorage.instance
        .ref("topics/role_CHANGE_DEV_SETTINGS.json")
        .putString(jsonEncode(CHANGE_DEV_SETTINGS)),
    FirebaseStorage.instance
        .ref("topics/role_MANAGE_EVENTS.json")
        .putString(jsonEncode(MANAGE_EVENTS)),
    FirebaseStorage.instance
        .ref("topics/role_MANAGE_HOSTS.json")
        .putString(jsonEncode(MANAGE_HOSTS)),
    FirebaseStorage.instance
        .ref("topics/role_MODERATE.json")
        .putString(jsonEncode(MODERATE))
  ]);
  await Future.wait(futures);
  return;
}

Future<Map<String, dynamic>?> getUsersForTopic(String topicname) async {
  try {
    print("topics/$topicname.json");
    Uint8List? data =
        await FirebaseStorage.instance.ref("topics/$topicname.json").getData();
    if (data == null) throw Exception("Data is null");
    print("Data Gotten");
    Map<String, dynamic> current_map = jsonDecode(String.fromCharCodes(data));
    return current_map;
  } catch (e) {
    print(e);
    return null;
  }
}

Future<Map<String, dynamic>?> addUserToExistingTopic(
    String topicname, String username) async {
  Map<String, dynamic>? currentUsers = await getUsersForTopic(topicname);
  if (currentUsers == null) return null;
  if (currentUsers.keys.contains(username)) {
    return currentUsers;
  }
  dbc.User? user = await getUser(username);
  if (user == null) return currentUsers;
  currentUsers[username] = user.deviceTokens;
  print("Current Users: $currentUsers");
  await sync([
    FirebaseStorage.instance
        .ref("topics/$topicname.json")
        .putString(jsonEncode(currentUsers)),
    db.doc(user.path).update({
      "topics": FieldValue.arrayUnion([topicname])
    })
  ]);
  return currentUsers;
}

Future<void> addPermissionToUser(
    GlobalPermission permit, String username) async {
  if (!doIHavePermission(GlobalPermission.ADMIN)) return;
  await sync([
    db.doc("${branchPrefix}users/$username").update({
      "permissions": FieldValue.arrayUnion([permit.name]),
      "lastEditedInMs": Timestamp.now().millisecondsSinceEpoch
    }),
    addUserToExistingTopic("role_${permit.name}", username)
  ]);
  return;
}

Future<Map<String, dynamic>?> removeUserFromExistingTopic(
    String topicname, String username) async {
  Map<String, dynamic>? currentUsers = await getUsersForTopic(topicname);
  if (currentUsers == null) return null;
  if (currentUsers.keys.contains(username)) {
    currentUsers.remove(username);
  }
  await sync([
    FirebaseStorage.instance
        .ref("topics/$topicname.json")
        .putString(jsonEncode({"users": currentUsers})),
    db.doc("${branchPrefix}user/$username").update({
      "topics": FieldValue.arrayRemove([topicname]),
      "lastEditedInMs": Timestamp.now().millisecondsSinceEpoch
    })
  ]);
  return currentUsers;
}

Future<void> removePermissionFromUser(
    GlobalPermission permit, String username) async {
  if (!doIHavePermission(GlobalPermission.ADMIN)) return;
  List<Future> futures = [];
  futures.add(db.doc("${branchPrefix}users/$username").update({
    "permissions": FieldValue.arrayRemove([permit.name]),
    "lastEditedInMs": Timestamp.now().millisecondsSinceEpoch
  }));
  futures.add(removeUserFromExistingTopic("role_${permit.name}", username));
  await Future.wait(futures);
  return;
}
