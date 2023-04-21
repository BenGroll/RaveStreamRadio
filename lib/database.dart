// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
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
import 'package:ravestreamradioapp/extensions.dart' show Queriefy, pprint;

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
    await event.hostreference!.set(hostdata);
  }
  Map eventIndexFile = await json.decode(await readEventIndexesJson());
  eventIndexFile[event.eventid] = event.toMap();
  if (eventIndexFile[event.eventid]["hostreference"] != null) {
    eventIndexFile[event.eventid]["hostreference"] =
        eventIndexFile[event.eventid]["hostreference"].path;
  }
  await storage.ref("indexes/${branchPrefix}eventsIndex.json").putString(
      eventMapToJson(forceStringDynamicMapFromObject(eventIndexFile)));
  return Future.delayed(Duration.zero);
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
  //pprint("tryUserLogin with $username $password");
  //if (kIsWeb && DEBUG_LOGIN_RETURN_TRUE_ON_WEB) return dbc.demoUser;
  //if (kIsWeb && !DEBUG_LOGIN_RETURN_TRUE_ON_WEB) return null;
  try {
    //pprint("Trying to login using username : $username, password: $password");
    if (username.isEmpty || password.isEmpty) {
      return null;
    }
    //pprint("${branchPrefix}users/$username");

    DocumentSnapshot<Map<String, dynamic>> doc =
        await db.doc("${branchPrefix}users/$username").get();
    /*DocumentSnapshot<Map<String, dynamic>> doc =
        await db.doc("users/admin").get();*/
    //pprint("Doc: $doc");
    if (doc.data() == null) {
      return null;
    }
    if (doc["password"] != password) {
      return null;
    }
    dbc.User constructedUser = dbc.User.fromMap(doc.data() ?? {});
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

  if (kIsWeb) {
    ///
  } else {
    return await tryUserLogin(
        savedlogindata["username"], savedlogindata["password"]);
  }
}

/// Fetch User from database
Future<dbc.User?> getUser(String username) async {
  DocumentSnapshot userdoc =
      await db.doc("${branchPrefix}users/$username").get();
  if (userdoc.exists && userdoc.data() != null) {
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
  if (currently_loggedin_as.value == null) return [];
  Query query = db.collection("${branchPrefix}events");
  QuerySnapshot snapshot = await query.get();
  List<Map<String, dynamic>>? maplist = querySnapshotToMapList(snapshot);
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
  EventFilters(
      {this.lastelemEventid,
      this.onlyAfter,
      this.onlyBefore,
      this.canGoByAge = 18,
      this.orderbyField = "end",
      required this.byStatus,
      this.onlyHostedByMe = false});

  @override
  String toString() {
    return 'Filter(lastelemEventid: $lastelemEventid, onlyAfter: ${timestamp2readablestamp(onlyAfter)}, onlyBefore: ${timestamp2readablestamp(onlyBefore)}, canGoByAge: $canGoByAge, orderByField: $orderbyField, byStatus: $byStatus, onlyHostedByMe: $onlyHostedByMe)';
  }
}

/// Gets the list of events for current branch from firestore.
Future<List<dbc.Event>> fetchEventsFromIndexFile() async {
  String eventIndexesJson = await readEventIndexesJson();
  List<dbc.Event> eventList = getEventListFromIndexes(eventIndexesJson);
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
    String jsonindexString =
        eventMapToJson(eventListToJsonCompatibleMap(events));
    await writeEventIndexes(jsonindexString);
    return await fetchEventsFromIndexFile();
  }
  return eventList;
}

/// Filter and order the list of events
List<dbc.Event> queriefyEventList(List<dbc.Event> events, EventFilters filters,
    [int? queryLimit]) {
  List<dbc.Event> eventList = events;
  //pprint(". ${eventList.length}");
  //pprint("Stati Included: ${filters.byStatus}");
  if (filters.onlyAfter != null) {
    eventList =
        eventList.whereIsGreaterThanOrEqualTo("begin", filters.onlyAfter);
  }
  //pprint(".. ${eventList.length}");

  if (filters.onlyBefore != null) {
    eventList = eventList.whereIsLessThanOrEqualTo("end", filters.onlyBefore);
  }
  //pprint("... ${eventList.length}");

  eventList = eventList.whereIsInValues("status", filters.byStatus);
  //pprint(".... ${eventList.length}");

  if (filters.canGoByAge != null) {
    eventList =
        eventList.whereIsLessThanOrEqualTo("minAge", filters.canGoByAge);
  }
  //pprint("..... ${eventList.length}");

  if (filters.onlyHostedByMe) {
    List newList = [];
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
    });
  }
  //pprint("...... ${eventList.length}");

  eventList.sort((a, b) {
    dynamic sort_a = a.toMap().keys.contains(filters.orderbyField)
        ? a.toMap()[filters.orderbyField]
        : 0;
    dynamic sort_b = a.toMap().keys.contains(filters.orderbyField)
        ? a.toMap()[filters.orderbyField]
        : 0;
    return sort_a.compareTo(sort_b);
  });
  //pprint("....... ${eventList.length}");

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
  if (!doIHavePermission(GlobalPermission.MANAGE_HOSTS)) return {};
  DocumentSnapshot indexesSnap = await db.doc("content/indexes").get();
  if (indexesSnap.data() != null) {
    return forceStringStringMapFromStringDynamic(
            indexesSnap["templateHostIDs"]) ??
        {};
  }
  return {};
}
/*
Future createIndexesForEvents(
    List<dbc.Event> events, BuildContext context) async {
  if (events.isEmpty) return;
  List<Future> callList = [];
  Map<String, dynamic> exampleEventMap = events.first.toMap();
  exampleEventMap.keys.forEach((attribute) async {
    Map<String, dynamic> idToValueMap = {};
    events.forEach((event) {
      idToValueMap[event.eventid] = event.toMap()[attribute];
    });
    callList.add(db
        .doc("${branchPrefix}events.indexes/${attribute}")
        .set({"values": idToValueMap}));
  });
  await Future.wait(callList);
  return Future.delayed(Duration.zero);
}*/

/// Write the database events to the index.json
Future writeEventIndexes(String eventjsonstring) async {
  Reference storageRef = FirebaseStorage.instance.ref();
  Reference pathReference =
      storageRef.child("indexes/${branchPrefix}eventsIndex.json");
  UploadTask task = pathReference.putString(eventjsonstring);
  return await task;
}

/// Read the index.json
Future<String> readEventIndexesJson() async {
  Reference storageRef = FirebaseStorage.instance.ref();
  Reference pathReference =
      storageRef.child("indexes/${branchPrefix}eventsIndex.json");
  Uint8List? data = await pathReference.getData(100 * 1024 * 1024);
  return String.fromCharCodes(data ?? Uint8List.fromList([0]));
}

/// Read the event list from a index.json in String format
List<dbc.Event> getEventListFromIndexes(String indexJsonString) {
  Map<String, dynamic> indexMap = json.decode(indexJsonString);
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
