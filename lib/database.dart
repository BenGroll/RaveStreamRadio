import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/filesystem.dart' as files;
import 'package:ravestreamradioapp/screens/homescreen.dart' as home;
import 'package:ravestreamradioapp/shared_state.dart';

var db = FirebaseFirestore.instance;

/// adds dbc.demoUser to database of current branch
Future addTestUser() async {
  await db
      .collection("${branchPrefix}users")
      .doc(dbc.demoUser.username)
      .set(dbc.demoUser.toMap())
      .then((value) {
    print("Users set");
  });
  return Future.delayed(Duration.zero);
}

/// adds dbc.demoEvent to database of current branch
Future addTestEvent() async {
  /*print(
      "demoEvent guestlist Runtime Type: ${dbc.demoEvent.guestlist.runtimeType}");*/
  await db
      .collection("${branchPrefix}events")
      .doc(dbc.demoEvent.eventid)
      .set(dbc.demoEvent.toMap())
      .then((value) {
    print("Events Set");
  });
  return Future.delayed(Duration.zero);
}

/// adds dbc.demoGroup to database of current branch
Future addTestGroup() async {
  await db
      .collection("${branchPrefix}groups")
      .doc(dbc.demoGroup.groupid)
      .set(dbc.demoGroup.toMap())
      .then((value) {
    print("Groups set");
  });
  return Future.delayed(Duration.zero);
}

/// Uploads event to database
Future<String?> uploadEventToDatabase(dbc.Event event) async {
  await db
      .collection("${branchPrefix}events")
      .doc(event.eventid)
      .set(event.toMap());
  return Future.delayed(Duration(seconds: 2));
}
/// Adds 10 demoevents to current branch.
Future setTestDBScenario() async {
  for (int i = 0; i < 10; i++) {
    dbc.Event testevent = dbc.Event(
        eventid: "testevent$i",
        //hostreference: db.doc(branchPrefix + "users/demouser"),
        end: Timestamp.fromDate(DateTime.now().add(Duration(days: 14 + i))));
    try {
      db.doc("${branchPrefix}events/testevent$i").set(testevent.toMap());
    } catch (e) {
      print(e);
    }
  }
}

/// TBA for Web
/// Returns Failed attempt on Web until Filesystem alternative is worked out
/// Only typesafe on web, doesnt work.
Future<dbc.User?> tryUserLogin(String username, String password) async {
  if (kIsWeb) return null;
  try {
    print("Trying to login using username : $username, password: $password");
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
    return constructedUser;
  } catch (e) {
    print(e);
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
  //db.collection("events").doc(dbc.demoEvent.eventid).set(dbc.demoEvent.toMap());
  //await setTestDBScenario();
  //print(await saveEventToUserReturnWasSaved(dbc.demoEvent, dbc.demoUser));
  Map savedlogindata = kIsWeb
      ? await files.readLoginDataWeb()
      : await files.readLoginDataMobile();
  //return await tryUserLogin(savedlogindata["username"], savedlogindata["password"]);
  return await tryUserLogin(
      savedlogindata["username"], savedlogindata["password"]);
}

//// Returns total count of Events ending after today
//// TBA Get event count from given query, not only default query
Future<int> getEventCount() async {
  int itemcount = await db
      .collection("${branchPrefix}events")
      .where("end", isGreaterThanOrEqualTo: Timestamp.now())
      .count()
      .get()
      .then((value) => value.count);
  return itemcount;
}

Future<List<dbc.Event>> getEvents(
    int perpage, String? lastelemEventid, String orderbyfield) async {
  getEventCount();
  QuerySnapshot query = lastelemEventid != null
      ? await db
          .collection("${branchPrefix}events")
          .orderBy(orderbyfield)
          .where("end", isGreaterThanOrEqualTo: Timestamp.now())
          .limit(perpage)
          .startAfterDocument(
              await db.doc("${branchPrefix}events/$lastelemEventid/").get())
          .get()
      : await db
          .collection("${branchPrefix}events")
          .orderBy(orderbyfield)
          .where("end", isGreaterThanOrEqualTo: Timestamp.now())
          .limit(perpage)
          .get();
  List<Map<String, dynamic>>? maplist = querySnapshotToMapList(query);
  List<dbc.Event> events = [];
  maplist.forEach((element) {
    events.add(dbc.Event.fromMap(element));
  });
  return events;
}

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
