import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'main.dart' as main;
import 'dart:math';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'dart:convert';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/extensions.dart';

/// Forces String type on all Elements of a List.
/// Elements that can't take String type are deleted.
List<String> forceStringType(List<dynamic> inList) {
  List<String> outlist = [];
  for (var element in inList) {
    if (element.runtimeType == String) {
      outlist.add(element);
    }
  }
  return outlist;
}

/// Forces int type on all Elements of a List.
/// Elements that can't take int type are deleted.
List<int> forceintType(List<dynamic> inList) {
  List<int> outlist = [];
  for (var element in inList) {
    if (element.runtimeType == int) {
      outlist.add(element);
    }
  }
  return outlist;
}

/// Forces DocumentReferene type on all Elements of a List.
/// Elements that can't take DocumentReference type are deleted.
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

/// Converts given [query] into a List<Map<String, dynamic>>
/// Needet to work with data queried from Firestore
List<Map<String, dynamic>> querySnapshotToMapList(QuerySnapshot query,
    {bool include_documentid = false}) {
  List<Map<String, dynamic>> documents = [];
  query.docs.forEach((element) {
    Map<String, dynamic> datamap = element.data() as Map<String, dynamic>;
    datamap.addAll({"uniqueDocID": element.id});
    documents.add(datamap);
  });
  return documents;
}

/// Takes a Map<dynamic, dynamic>
///
/// Returns Map<String, dynamic>
Map<String, dynamic> stringDynamicMapFromDynamicDynamic(
    Map<dynamic, dynamic> map) {
  Map<String, dynamic> test = {};
  map.entries.forEach((element) {
    test[element.key.toString()] = map[element.key];
  });
  return test;
}

/// Takes a Map<String, dynamic>
///
/// Returns Map<DocumentReference, String>?
Map<DocumentReference<Object?>, String>?
    forceDocumentReferenceStringMapTypeFromStringDynamic(
        Map<dynamic, dynamic> input) {
  Map<String, dynamic> convMap = stringDynamicMapFromDynamicDynamic(input);
  Map<DocumentReference, String> outmap = {};
  input.forEach((key, value) {
    outmap[db.db.doc(key)] = value.toString();
  });
  return outmap;
}

/// Takes Map<String, dynamic>?
///
/// Returns Map<String, String>
Map<String, String>? forceStringStringMapFromStringDynamic(
    Map<String, dynamic>? inputmap) {
  Map<String, String> outputmap = {};
  inputmap?.forEach((key, value) {
    outputmap[key] = value.toString();
  });
  return outputmap;
}

/// Converts unix timestamp to readable date and Time
///
/// Format: DD:MM:YY hh:mm
String timestamp2readablestamp(Timestamp? timestamp) {
  DateTime? date = timestamp?.toDate();
  if (date == null) {
    return "";
  } else {
    return "${date.day < 10 ? "0${date.day}" : date.day.toString()}.${date.month < 10 ? "0${date.month}" : date.month.toString()}.${date.year} ${date.hour < 10 ? "0${date.hour}" : date.hour.toString()}:${date.minute < 10 ? "0${date.minute}" : date.minute.toString()}";
  }
}

/// Converts Firebase Type Timestamp to Dart Timestamp
Timestamp? firebaseTimestampToTimeStamp(Timestamp? timestamp) {
  return timestamp != null
      ? Timestamp.fromMillisecondsSinceEpoch(timestamp.seconds * 1000)
      : null;
}

/// Converts String into Multiple Textspans
///
/// Used for saving Strings with multiline formatting and display them correctly
///
/// Newline Pattern: {/}
///
/// TBA: Takes nl-Pattern as argument
List<TextSpan> stringToTextSpanList(String mlinestring) {
  List<TextSpan> returnlist = [];
  mlinestring.split("\n").forEach((element) {
    returnlist.add(TextSpan(text: "$element\n"));
  });
  return returnlist;
}

/// Returns a String of random characters with length len
String getRandString(int len) {
  var random = Random.secure();
  var values = List<int>.generate(len, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

String generateDocumentID() {
  List<String> allowed_values = [
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g",
    "h",
    "i",
    "j",
    "k",
    "l",
    "m",
    "n",
    "o",
    "p",
    "q",
    "r",
    "s",
    "t",
    "u",
    "v",
    "w",
    "x",
    "y",
    "z",
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9"
  ];
  print(allowed_values.length);
  String returnID = "";
  var rng = Random();
  for (int i = 0; i < 20; i++) {
    returnID = "$returnID${allowed_values[rng.nextInt(62)]}";
  }
  return returnID;
}

/// Widget to support asynchronous loading of event titles
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
            ScrollController _cont = ScrollController();
            return GestureDetector(
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: event.eventid));
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Copied Title to Clipboard")));
                },
                child: SingleChildScrollView(
                    controller: _cont,
                    scrollDirection: Axis.horizontal,
                    child: Scrollbar(
                        controller: _cont,
                        child: Text(
                          snapshot.data ?? "Unknown Event",
                          style: style,
                          maxLines: null,
                          softWrap: true,
                        ))));
          }
          return const CircularProgressIndicator(color: Colors.white);
        }));
  }
}

/// Returns Event title
///
/// Nullsafe
///
/// Falls back to host if no title specified
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

/// returns true if [event] is hosted by [user]
bool isEventHostedByUser(dbc.Event event, dbc.User? user) {
  if (user == null) {
    return false;
  }
  if (event.templateHostID != null &&
      db.doIHavePermission(GlobalPermission.MANAGE_EVENTS)) {
    return true;
  }
  for (int i = 0; i < user.events.length; i++) {
    if (user.events[i].id == event.eventid) {
      return true;
    }
  }
  return false;
}

/// Takes Map<String, dynamic>?
///
/// Returns Map<DocumentReference, dynamic>
Map<DocumentReference, dynamic>? mapStringDynamic2DocRefDynamic(
    Map<String, dynamic> input) {
  Map<DocumentReference, dynamic> out = {};
  input.keys.forEach((element) {
    out[db.db.doc(element)] = input[element];
  });
  return out;
}

/// Get key that matches value from a Map<String, dynamic>
String? getKeyMatchingValueFromMap(
    Map<String, dynamic> searchMap, dynamic searchValue) {
  if (!searchMap.containsValue(searchValue)) return null;
  for (int i = 0; i < searchMap.length; i++) {
    MapEntry entry = searchMap.entries.toList()[i];
    if (entry.value == searchValue) {
      return entry.key;
    }
  }
  return null;
}

/// Creates an array of all numbers from 0 to n
///
/// Example:
///
/// numberToArrayOfAllNumbersBelow(10)
///
/// => [0,1,2,3,4,5,6,7,8,9]
List<int> numberToArrayOfAllNumbersBelow(int number) {
  List<int> intlist = [];
  for (int i = 0; i < number; i++) {
    intlist.add(i);
  }
  return intlist;
}

/// Calculate Size in Bytes it takes to store [input]
int getSizeInBytesForMap(Map<dynamic, dynamic> input) {
  int size = 0;
  input.entries.forEach((MapEntry element) {
    String k = element.key as String;
    String v = element.value as String;
    size = size + k.length + v.length;
  });
  return size;
}

/// Turns a List<dbc.Event> into a Map, Structure:
///
/// {
///
///   eventid: {
///
///               # Event Attributes
///
///            },
///
///   eventid2:{
///
///               # Event Attributes
///
///            }
///
/// }
Map<String, dynamic> eventListToJsonCompatibleMap(List<dbc.Event> list) {
  Map<String, dynamic> outMap = {};
  list.forEach((element) {
    outMap[element.eventid] = element.toJsonCompatibleMap();
  });
  return outMap;
}

/// Takes map from eventListToJsonCompatibleMap
///
/// Returns the json encoded string
String eventMapToJson(Map<String, dynamic> inMap) {
  return json.encode(inMap).dbsafe;
}

/// Takes Map<String, dynamic> and returns the List<dbc.Event>
List<dbc.Event> maplistToEventList(List<Map<String, dynamic>> mapList) {
  List<dbc.Event> list = [];
  mapList.forEach((element) {
    list.add(dbc.Event.fromMap(element));
  });
  return list;
}

/// Takes Object
///
/// Returns the Map<String, dynamic>
Map<String, dynamic> forceStringDynamicMapFromObject(Object input) {
  try {
    Map<String, dynamic> out = input as Map<String, dynamic>;
    return out;
  } catch (e) {
    pprint(e);
    return {};
  }
}

List<Map<String, dynamic>> forceListMapStringDynamicTypeToList(
    List<dynamic> list) {
  List<Map<String, dynamic>> out = [];
  list.forEach((element) {
    list.add(element as Map<String, dynamic>);
  });
  return out;
}

List<DocumentReference> forceDocumentReferenceFromStringList(
    List<String> list) {
  return list.map((e) => db.db.doc(e)).toList();
}

List<String> get lowercaseCharacters {
  return List.generate(
      26, (index) => String.fromCharCode(index + 65).toLowerCase());
}

List<String> get uppercaseCharacters {
  return List.generate(26, (index) => String.fromCharCode(index + 65));
}

List<String> get numbers {
  return List.generate(10, (index) => index.toString());
}
