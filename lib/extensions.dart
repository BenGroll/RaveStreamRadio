import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;

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