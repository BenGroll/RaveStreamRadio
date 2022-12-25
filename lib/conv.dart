import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'main.dart' as main;
import 'dart:math';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'dart:convert';
import 'package:ravestreamradioapp/shared_state.dart';

List<String> forceStringType(List<dynamic> inList) {
  List<String> outlist = [];
  for (var element in inList) {
    if (element.runtimeType == String) {
      outlist.add(element);
    }
  }
  return outlist;
}

List<int> forceintType(List<dynamic> inList) {
  List<int> outlist = [];
  for (var element in inList) {
    if (element.runtimeType == int) {
      outlist.add(element);
    }
  }
  return outlist;
}

List<DocumentReference> forceDocumentReferenceType(List<dynamic> inList) {
  List<DocumentReference> outlist = [];
  for (var element in inList) {
    if (element.runtimeType == DocumentReference) {
      outlist.add(element);
    } else {
      outlist.add(element as DocumentReference);
    }
  }
  return outlist;
}

List<Map<String, dynamic>> querySnapshotToMapList(QuerySnapshot query) {
  List<Map<String, dynamic>> documents = [];
  query.docs.forEach((element) {
    documents.add(element.data() as Map<String, dynamic>);
  });
  return documents;
}

Map<DocumentReference<Object?>, String>?
    forceDocumentReferenceStringMapTypeFromStringDynamic(
        Map<String, dynamic> input) {
  Map<DocumentReference, String> outmap = {};
  input.forEach((key, value) {
    outmap[db.db.doc(key)] = value.toString();
  });
  return outmap;
}

Map<String, String>? forceStringStringMapFromStringDynamic(
    Map<String, dynamic>? inputmap) {
  Map<String, String> outputmap = {};
  inputmap?.forEach((key, value) {
    outputmap[key] = value.toString();
  });

  return outputmap;
}

String timestamp2readablestamp(Timestamp? timestamp) {
  DateTime? date = timestamp?.toDate();
  if (date == null) {
    return "";
  } else {
    return "${date.day < 10 ? "0${date.day}" : date.day.toString()}.${date.month < 10 ? "0${date.month}" : date.month.toString()}.${date.year} ${date.hour < 10 ? "0${date.hour}" : date.hour.toString()}:${date.minute < 10 ? "0${date.minute}" : date.minute.toString()}";
  }
}

Timestamp? firebaseTimestampToTimeStamp(Timestamp? timestamp) {
  return timestamp != null
      ? Timestamp.fromMillisecondsSinceEpoch(timestamp.seconds * 1000)
      : null;
}

List<TextSpan> stringToTextSpanList(String mlinestring) {
  List<TextSpan> returnlist = [];
  mlinestring.split("{/}").forEach((element) {
    returnlist.add(TextSpan(text: "$element\n"));
  });
  return returnlist;
}

String get branchPrefix {
  if (selectedbranch.value == ServerBranches.develop) {
    return "dev.";
  }
  if (selectedbranch.value == ServerBranches.public) {
    return "";
  }
  if (selectedbranch.value == ServerBranches.test) {
    return "test.";
  } else {
    throw Exception("Prefix for selected Branch not set.");
  }
}

String getRandString(int len) {
  var random = Random.secure();
  var values = List<int>.generate(len, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

class EventTitle extends StatelessWidget {
  final TextStyle style;
  final dbc.Event event;
  const EventTitle({required this.style, required this.event});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getEventTitle(event),
        builder: ((context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Text(snapshot.data ?? "Unknown Event", style: style);
          }
          return const CircularProgressIndicator(color: Colors.white);
        }));
  }
}

Future<String> getEventTitle(dbc.Event event) async {
  if (event.title == null) {
    if (event.hostreference == null ||
        await event.hostreference?.get() == null) {
      return "Unnamed Event";
    }
    Map<String, dynamic> host = await event.hostreference
            ?.get()
            .then((value) => value.data() as Map<String, dynamic>) ??
        {"alias": null, "username": "unknownuser"};
    if (host["alias"] == null || host["alias"].isEmpty) {
      return "@${host["username"]}'s Event";
    }
    return "${host["alias"]}'s Event";
  } else {
    return event.title ?? "This should never display";
  }
}

bool isEventHostedByUser(String eventid, dbc.User? user) {
  if (user == null) {
    return false;
  }
  for (int i = 0; i < user.events.length; i++) {
    if (user.events[i].id == eventid) {
      return true;
    }
  }
  return false;
}

