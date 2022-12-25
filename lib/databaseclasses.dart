// ignore_for_file: public_member_api_docs, sort_constructors_first, avoid_init_to_null
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/database.dart' show db;
import 'package:ravestreamradioapp/conv.dart';

/// Template class for Events to avoid type and valueerrors
class Event {
  final String? title;
  final String eventid;
  final DocumentReference? hostreference;
  final Timestamp? begin;
  final Timestamp? end;
  final GeoPoint? location;
  final String? locationname;
  final String? age;
  final String? icon;
  final String? description;
  final String? timetable;
  final Map<String, String>? links;
  final Map<DocumentReference, String>? guestlist;
  final int savedcount;

  Event({
    this.title = null,
    required this.eventid,
    this.hostreference = null,
    this.begin = null,
    this.end = null,
    this.location = null,
    this.locationname,
    this.age = null,
    this.icon = null,
    this.description,
    this.timetable = null,
    this.links = null,
    this.guestlist,
    this.savedcount = 0,
  });

  Event copyWith({
    String? title,
    required String eventid,
    dynamic host,
    Timestamp? begin,
    Timestamp? end,
    GeoPoint? location,
    String? locationname,
    String? age,
    String? icon,
    String? description,
    String? timetable,
    Map<String, String>? links,
    Map<DocumentReference, String>? guestlist,
    int? savedcount,
  }) {
    return Event(
      title: title ?? this.title,
      eventid: eventid,
      hostreference: hostreference ?? hostreference,
      begin: begin ?? this.begin,
      end: end ?? this.end,
      location: location ?? this.location,
      locationname: locationname ?? this.locationname,
      age: age ?? this.age,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      timetable: timetable ?? this.timetable,
      links: links ?? this.links,
      guestlist: guestlist ?? this.guestlist,
      savedcount: savedcount ?? this.savedcount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'eventid': eventid,
      'hostreference': hostreference,
      'begin': begin,
      'end': end,
      'location': location,
      'locationname': locationname,
      'age': age,
      'icon': icon,
      'description': description,
      'timetable': timetable,
      'links': links,
      'guestlist': guestlist != null
          ? guestlist!.map((dynamic key, value) {
              key = key.path;
              value = value;
              return MapEntry(key, value);
            })
          : {},
      'savedcount': savedcount,
    };
  }

  factory Event.fromMap(Map<String, dynamic> inputmap) {
    try {
      Event mapevent = Event(
          title: inputmap["title"],
          eventid: inputmap["eventid"],
          hostreference: inputmap["hostreference"],
          begin: firebaseTimestampToTimeStamp(
              inputmap["begin"]),
          end: firebaseTimestampToTimeStamp(
              inputmap["end"]),
          location: inputmap["location"],
          locationname: inputmap["locationname"],
          age: inputmap["age"],
          icon: inputmap["icon"],
          description: inputmap["description"],
          timetable: inputmap["timetable"],
          links: forceStringStringMapFromStringDynamic(inputmap["links"]),
          guestlist: forceDocumentReferenceStringMapTypeFromStringDynamic(
              inputmap["guestlist"]));
      return mapevent;
    } catch (e) {
      print(e);
      return Event(eventid: "errorevent");
    }
  }

  String toJson() => json.encode(toMap());
  factory Event.fromJson(String source) =>
      Event.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Event(title: $title, eventid: $eventid, hostreference: $hostreference, begin: $begin, end: $end, location: $location, locationname: $locationname, age: $age, icon: $icon, description: $description, timetable: $timetable, links: $links, guestlist: $guestlist, savedcount: $savedcount)';
  }

  @override
  bool operator ==(covariant Event other) {
    if (identical(this, other)) return true;
    return other.title == title &&
        other.hostreference == hostreference &&
        other.eventid == eventid &&
        other.begin == begin &&
        other.end == end &&
        other.location == location &&
        other.locationname == locationname &&
        other.age == age &&
        other.icon == icon &&
        other.description == description &&
        other.timetable == timetable &&
        mapEquals(other.links, links) &&
        mapEquals(other.guestlist, guestlist) &&
        other.savedcount == savedcount;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        eventid.hashCode ^
        hostreference.hashCode ^
        begin.hashCode ^
        end.hashCode ^
        location.hashCode ^
        locationname.hashCode ^
        age.hashCode ^
        icon.hashCode ^
        description.hashCode ^
        timetable.hashCode ^
        links.hashCode ^
        guestlist.hashCode ^
        savedcount.hashCode;
  }
}
/// Template class for Groups to avoid type and valueerrors
class Group {
  final String title;
  final String groupid;
  final dynamic design;
  final Map<String, MaterialColor> custom_roles;
  final Map<DocumentReference, dynamic>? members_roles;
  final List<DocumentReference> events;
  Group({
    required this.title,
    required this.groupid,
    this.design = null,
    required this.custom_roles,
    required this.members_roles,
    required this.events,
  });

  Group copyWith({
    String? title,
    required String groupid,
    dynamic design,
    Map<String, MaterialColor>? custom_roles,
    Map<DocumentReference, dynamic>? members_roles,
    List<DocumentReference>? events,
  }) {
    return Group(
      title: title ?? this.title,
      groupid: groupid,
      design: design ?? this.design,
      custom_roles: custom_roles ?? this.custom_roles,
      members_roles: members_roles ?? this.members_roles,
      events: events ?? this.events,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'groupid': groupid,
      'design': design,
      'custom_roles': custom_roles,
      'members_roles': members_roles!.map((dynamic key, value) {
        key = key.path;
        value = value;
        return MapEntry(key, value);
      }),
      'events': events.map((x) => x).toList(),
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
        title: map['title'] as String,
        groupid: map['groupid'] as String,
        design: map['design'] as dynamic,
        custom_roles: map['custom_roles'] as Map<String, MaterialColor>,
        members_roles: map['members_roles'].map((dynamic key, value) {
          key = db.doc(key.path);
          value = value;
          return MapEntry(key, value);
        }),
        events: forceDocumentReferenceType(['events']));
  }

  String toJson() => json.encode(toMap());

  factory Group.fromJson(String source) =>
      Group.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Group(title: $title, groupid: $groupid, : $design, custom_roles: $custom_roles, members_roles: $members_roles, events: $events)';
  }

  @override
  bool operator ==(covariant Group other) {
    if (identical(this, other)) return true;

    return other.title == title &&
        other.groupid == groupid &&
        other.design == design &&
        mapEquals(other.custom_roles, custom_roles) &&
        mapEquals(other.members_roles, members_roles) &&
        listEquals(other.events, events);
  }

  @override
  int get hashCode {
    return title.hashCode ^
        groupid.hashCode ^
        design.hashCode ^
        custom_roles.hashCode ^
        members_roles.hashCode ^
        events.hashCode;
  }
}

/// Template class for Users to avoid type and valueerrors
class User {
  String username;
  String alias;
  String password;
  String? description;
  String? mail;
  String? profile_picture;
  List<DocumentReference> events;
  List<DocumentReference> joined_groups;
  List<DocumentReference> saved_events;
  List<DocumentReference> followed_groups;
  List<DocumentReference> close_friends;
  User({
    required this.username,
    required this.alias,
    required this.password,
    this.description,
    this.mail,
    this.profile_picture,
    this.events = const <DocumentReference>[],
    this.joined_groups = const <DocumentReference>[],
    this.saved_events = const <DocumentReference>[],
    this.followed_groups = const <DocumentReference>[],
    this.close_friends = const <DocumentReference>[],
  });

  User copyWith({
    String? username,
    String? alias,
    String? password,
    String? description,
    String? mail,
    String? profile_picture,
    List<DocumentReference>? events,
    List<DocumentReference>? joined_groups,
    List<DocumentReference>? saved_events,
    List<DocumentReference>? followed_groups,
    List<DocumentReference>? close_friends,
  }) {
    return User(
      username: username ?? this.username,
      alias: alias ?? this.alias,
      password: password ?? this.password,
      description: description ?? this.description,
      mail: mail ?? this.mail,
      profile_picture: profile_picture ?? this.profile_picture,
      events: events ?? this.events,
      joined_groups: joined_groups ?? this.joined_groups,
      saved_events: saved_events ?? this.saved_events,
      followed_groups: followed_groups ?? this.followed_groups,
      close_friends: close_friends ?? this.close_friends,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'username': username,
      'alias': alias,
      'password': password,
      'description': description,
      'mail': mail,
      'profile_picture': profile_picture,
      'events': events.map((x) => x).toList(),
      'joined_groups': joined_groups.map((x) => x).toList(),
      'saved_events': saved_events.map((x) => x).toList(),
      'followed_groups': followed_groups.map((x) => x).toList(),
      'close_friends': close_friends.map((x) => x).toList(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    //print(map);
    return User(
        username: map['username'] as String,
        alias: map['alias'] as String,
        password: map['password'] as String,
        description: map['description'] as String,
        mail: map['mail'] as String?,
        profile_picture: map['profile_picture'] as String?,
        events: forceDocumentReferenceType(map['events']),
        joined_groups: forceDocumentReferenceType(map['joined_groups']),
        saved_events: forceDocumentReferenceType(map['saved_events']),
        followed_groups: forceDocumentReferenceType(map['followed_groups']),
        close_friends: forceDocumentReferenceType(map['close_friends']));
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'User(username: $username, alias: $alias, password: $password, description: $description, mail: $mail, profile_picture: $profile_picture, events: $events, joined_groups: $joined_groups, saved_events: $saved_events, followed_groups: $followed_groups, close_friends: $close_friends)';
  }

  @override
  bool operator ==(covariant User other) {
    if (identical(this, other)) return true;

    return other.username == username &&
        other.alias == alias &&
        other.password == password &&
        other.description == description &&
        other.mail == mail &&
        other.profile_picture == profile_picture &&
        listEquals(other.events, events) &&
        listEquals(other.joined_groups, joined_groups) &&
        listEquals(other.saved_events, saved_events) &&
        listEquals(other.followed_groups, followed_groups) &&
        listEquals(other.close_friends, close_friends);
  }

  @override
  int get hashCode {
    return username.hashCode ^
        alias.hashCode ^
        password.hashCode ^
        description.hashCode ^
        mail.hashCode ^
        profile_picture.hashCode ^
        events.hashCode ^
        joined_groups.hashCode ^
        saved_events.hashCode ^
        followed_groups.hashCode ^
        close_friends.hashCode;
  }
}

/*
  Demo Objects
*/

User demoUser = User(
    username: "demouser",
    alias: "Demo User",
    password: "DemoPasswort",
    description: "User created solely for Testing Purposes",
    mail: "bengroll002@gmail.com",
    joined_groups: [db.doc("${branchPrefix}groups/demogroup")],
    saved_events: [db.doc("${branchPrefix}events/demoevent")],
    events: [db.doc("${branchPrefix}events/demoevent")]);

Event demoEvent = Event(
    title: "Demo Event4",
    eventid: "demoevent4",
    hostreference: db.doc("${branchPrefix}users/demouser"),
    guestlist: {db.doc("${branchPrefix}users/demouser"): "Host"});

Group demoGroup = Group(
    title: "Demo Group",
    groupid: "demogroup",
    custom_roles: {},
    members_roles: {db.doc("${branchPrefix}users/demouser/"): "Role"},
    events: []);
