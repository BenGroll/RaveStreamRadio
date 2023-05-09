import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/screens/mainscreens/groups.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'dart:io' show Platform;
import 'chatting.dart';

const FILENAME = "extensions.dart";

/// Extension to Capitalize or TitleCase a String
extension StringCasingExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');
}

/// Extension to titleCase or capitalize each String in a List
extension Prettify on List<String> {
  List<String> titleCaseEach() {
    List<String> out = [];
    forEach((element) {
      out.add(element.toTitleCase());
    });
    return out;
  }

  List<String> capitalizeEach() {
    List<String> out = [];
    forEach((element) {
      out.add(element.toCapitalized());
    });
    return out;
  }
}

/// Check if two DocumentReferences refer to the same Document
extension Comparator on DocumentReference {
  int compareTo(dynamic other) {
    return id.compareTo(other);
  }
}

/// Checks which one of two maps is longer (1-Level) than the other
extension MapComparator on Map {
  int compareTo(Map other) {
    return entries.length.compareTo(other.entries.length);
  }
}

void pprint(dynamic data) {
  //data = "@${Platform.script.path}: $data";
  print(data);
}

/// Find the index of the map where one common key matches specific value
///
/// Example:
///
///
/// List<Map> input = [{"id": 2, "name": "Foo"}, {"id" : 2, "name": "Bar"}]
///
/// print(input.whereIsEqual("id", 2));
///
/// ==> 0
extension MapListFindByKey on List<Map> {
  int? whereIsEqual(String key, dynamic value) {
    for (int i = 0; i < length; i++) {
      if (this[i][key] == value) {
        return i;
      }
    }
    return null;
  }
}

extension Stringify on List<DocumentReference> {
  List<String> paths() {
    return map((e) => e.path).toList();
  }

  List<String> ids() {
    return map((e) => e.id).toList();
  }
}

extension Queriefy on List<dbc.Event> {
  List<dbc.Event> whereIsEqual(String name, dynamic value) {
    List<dbc.Event> outL = [];
    forEach((dbc.Event element) {
      Map mapElem = element.toMap();
      if (mapElem.keys.contains(name) && mapElem[name] == value) {
        outL.add(element);
      }
    });
    return outL;
  }

  List<dbc.Event> whereIsGreaterThan(String name, dynamic value) {
    List<dbc.Event> outL = [];
    forEach((dbc.Event element) {
      Map mapElem = element.toMap();
      if (mapElem.keys.contains(name) && mapElem[name] > value) {
        outL.add(element);
      }
    });
    return outL;
  }

  List<dbc.Event> whereIsSmallerThan(String name, dynamic value) {
    List<dbc.Event> outL = [];
    forEach((dbc.Event element) {
      Map mapElem = element.toMap();
      if (mapElem.keys.contains(name) && mapElem[name] < value) {
        outL.add(element);
      }
    });
    return outL;
  }

  List<dbc.Event> whereIsGreaterThanOrEqualTo(String name, dynamic value) {
    List<dbc.Event> outL = [];
    forEach((dbc.Event element) {
      Map mapElem = element.toMap();
      if (mapElem.keys.contains(name) && mapElem[name] >= value) {
        outL.add(element);
      }
    });
    return outL;
  }

  List<dbc.Event> whereIsLessThanOrEqualTo(String name, dynamic value) {
    List<dbc.Event> outL = [];
    forEach((dbc.Event element) {
      Map mapElem = element.toMap();
      if (mapElem.keys.contains(name) && mapElem[name] <= value) {
        outL.add(element);
      }
    });
    return outL;
  }

  List<dbc.Event> whereIsInValues(String name, List<dynamic> values) {
    List<dbc.Event> outL = [];
    forEach((dbc.Event element) {
      Map mapElem = element.toMap();
      if (mapElem.keys.contains(name) && values.contains(mapElem[name])) {
        outL.add(element);
      }
    });
    return outL;
  }

  List<dbc.Event> whereContainsString(String searchString) {
    List<dbc.Event> outL = [];
    forEach((element) {
      if ((element.locationname != null &&
              element.locationname!.contains(searchString)) ||
          (element.eventid.contains(searchString)) ||
          (element.title != null && element.title!.contains(searchString)) ||
          (element.templateHostID != null &&
              element.templateHostID!.contains(searchString))) {
        outL.add(element);
      }
    });
    return outL;
  }
}

extension Check on List<Message> {
  Message? checkForIDMatch(String id) {
    Message? returnvalue;
    forEach((element) {
      returnvalue = element.id == id ? element : null;
    });
    return returnvalue;
  }
}

extension QueryData on List<QueryEntry> {
  List<QueryEntry> matchesString(String search) {
    List<QueryEntry> matching = [];
    forEach((element) {
      if (element.id.contains(search) || element.name.contains(search)) {
        matching.add(element);
      }
    });
    return matching;
  }
}

extension Query on List<dbc.Group> {
  List<dbc.Group> queryStringMatch(String searchString) {
    List<dbc.Group> outL = [];
    forEach((element) {
      if (element.groupid.contains(searchString) ||
          (element.title != null && element.title!.contains(searchString))) {
        outL.add(element);
      }
    });
    return outL;
  }

  List<dbc.Group> get pinnedFirst {
    List<dbc.Group> outP = [];
    List<dbc.Group> outNP = [];
    forEach((element) {
      if (currently_loggedin_as.value == null
          ? false
          : db.hasGroupPinned(
              element, currently_loggedin_as.value ?? dbc.demoUser)) {
        outP.add(element);
      } else {
        outNP.add(element);
      }
    });
    outP.addAll(outNP);
    return outP;
  }
}

extension CheckForIDvalidity on String {
  bool get isValidDocumentid {
    List<String> validChars = [
      "_",
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
    bool is_valid = true;
    this.runes.forEach((element) {
      String char = String.fromCharCode(element);
      if (!validChars.contains(char)) {
        is_valid = false;
      }
    });
    return is_valid;
  }
}

const String OE = "{Char.OE}";
const String UE = "{Char.UE}";
const String AE = "{Char.AE}";
const String oe = "{Char.oe}";
const String ue = "{Char.ue}";
const String ae = "{Char.ae}";
const String scharfS = "{Char.scharfS}";

extension JsonSafe on String {
  String get dbsafe {
    Stopwatch watch = Stopwatch()..start();
    String value = replaceAll("Ö", OE);
    value = value.replaceAll("Ü", UE);
    value = value.replaceAll("Ä", AE);
    value = value.replaceAll("ß", scharfS);
    value = value.replaceAll("ä", ae);
    value = value.replaceAll("ö", oe);
    value = value.replaceAll("ü", ue);
    print("String conversion took ${watch.elapsed}");
    watch.stop;
    return value;
  }
  String get fromDBSafeString {
    Stopwatch watch = Stopwatch()..start();
    String value = replaceAll(OE, "Ö");
    value = value.replaceAll(UE, "Ü");
    value = value.replaceAll(AE, "Ä");
    value = value.replaceAll(scharfS, "ß");
    value = value.replaceAll(ae, "ä");
    value = value.replaceAll(oe, "ö");
    value = value.replaceAll(ue, "ü");
    print("String conversion took ${watch.elapsed}");
    watch.stop;
    return value;
  }

}
