// ignore_for_file: public_member_api_docs, sort_constructors_first, avoid_init_to_null
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/database.dart' show db;
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/shared_state.dart';

class Link {
  String title;
  String url;
  Link({required this.title, required this.url});
  bool operator ==(covariant Link other) {
    if (identical(this, other)) return true;
    return other.title == other.title && other.url == other.url;
  }
}

List<Link> linkListFromMap(Map<String, String> map) {
  List<Link> outmap = [];
  map.keys.forEach((element) {
    outmap.add(Link(title: element, url: map[element]!));
  });
  return outmap;
}

Map<String, String> mapToLinkList(List<Link> linklist) {
  Map<String, String> outmap = {};
  linklist.forEach((element) {
    outmap[element.title] = element.url;
  });
  return outmap;
}

List<GlobalPermission> dbPermissionsToGlobal(List<String> permits) {
  List<GlobalPermission> outlist = [];
  if (permits.contains("ADMIN")) {
    for (int i = 0; i < GlobalPermission.values.length; i++) {
      outlist.add(GlobalPermission.values[i]);
    }
  } else {
    permits.forEach((element) {
      if (GlobalPermission.values.contains(element)) {
        switch (element) {
          case "MANAGE_EVENTS":
            outlist.add(GlobalPermission.MANAGE_EVENTS);
            break;
          case "CHANGE_DEV_SETTINGS":
            outlist.add(GlobalPermission.CHANGE_DEV_SETTINGS);
            break;
          default:
        }
      }
    });
  }
  return outlist;
}

/// Template class for Events to avoid type and valueerrors
///
/// If [title] isnt provided it will default to [hostreference]'s name
///
/// If both [title] and [hostreference] are null, it will default to "Unnamed Event"
///
/// [eventid] has to be provided. Only lowercase characters and numbers are allowed.
///
/// [eventid] has to be unique, this has to be checked before uploading event
///
/// [hostreference] can be a User or Group, also can be null.
///
/// [begin] is the timestamp where the event begins, can be null
///
/// [end] is the timestamp where the event endss, can be null
///
/// [location] is TBI, will be picked by google maps location picker. Can be null
///
/// [locationname] is an alternative to [location], host has to manually type in location-info. Can be null
///
/// both [location] and [locationname] can be null, can also be null at the same time.
///
/// in the [age] parameter the host can specify which age-requirements each attendee has to meet.
///
/// if the [icon] parameter is provided, the calendar-preview card and the event overview page will show the image
/// meeting this path. If null, said image will default to [hostreference]'s profile picture. If both are null, it will default to a 'missing picture' image built into the app
///
/// the [description] gets displayed right beneath the [hostreference]'s data in event overview. Its a complex Text widget which allows for Multi-line, Custom formatting and use of emojis
///
/// [timetable] TBI
///
/// [links] will contain title:url pairs of links matching the event provided by the host. They are displayed in the event overview page if provided, converted into clickable url-launching links
///
/// [guestlist] TBI
///
/// [savedcount] corresponds to the amount of users which saved this event to their favourites
///
/// [exModHostname] (externally moderated Hostname override)
///
/// [exModHostname] is used to implement the option to add events to the calendar as a ravestream member.
///
/// If [exModHostname] is null, it will default to load event to be hostet by a Host themselves.
///
/// If [exModHostname] is not null, it will be modifyable by ravestream members, and the value given will be displayed instead of the linkbutton that normally links to the host
///
class Event {
  String? title;
  String eventid;
  DocumentReference? hostreference;
  Timestamp? begin;
  Timestamp? end;
  GeoPoint? location;
  String? locationname;
  String? age;
  String? icon;
  String? description;
  String? timetable;
  Map<String, String>? links;
  Map<DocumentReference, String>? guestlist;
  int savedcount;
  String? exModHostname;

  Event(
      {this.title = null,
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
      this.exModHostname});

  Event copyWith(
      {String? title,
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
      String? exModHostname}) {
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
        exModHostname: exModHostname ?? this.exModHostname);
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
      'exModHostname': exModHostname
    };
  }

  factory Event.fromMap(Map<String, dynamic> inputmap) {
    try {
      Event mapevent = Event(
          title: inputmap["title"],
          eventid: inputmap["eventid"],
          hostreference: inputmap["hostreference"],
          begin: firebaseTimestampToTimeStamp(inputmap["begin"]),
          end: firebaseTimestampToTimeStamp(inputmap["end"]),
          location: inputmap["location"],
          locationname: inputmap["locationname"],
          age: inputmap["age"],
          icon: inputmap["icon"],
          description: inputmap["description"],
          timetable: inputmap["timetable"],
          links: forceStringStringMapFromStringDynamic(inputmap["links"]),
          guestlist: forceDocumentReferenceStringMapTypeFromStringDynamic(
              inputmap["guestlist"]),
          exModHostname: inputmap['exModHostname']);
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
    return 'Event(title: "$title", eventid: "$eventid", hostreference: "$hostreference", begin: "$begin", end: "$end", location: "$location", locationname: "$locationname", age: "$age", icon: "$icon", description: "${title /*description*/}", timetable: "$timetable", links: "$links", guestlist: "$guestlist", savedcount: "$savedcount", exModHostName: $exModHostname)';
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
        other.savedcount == savedcount &&
        other.exModHostname == exModHostname;
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
        savedcount.hashCode ^
        exModHostname.hashCode;
  }
}

/// Template class for Groups to avoid type and valueerrors
class Group {
  final String? title;
  final String groupid;
  final dynamic design;
  final Map<String, MaterialColor>? custom_roles;
  final Map<DocumentReference, dynamic>? members_roles;
  final List<DocumentReference> events;
  Group({
    this.title,
    required this.groupid,
    this.design = null,
    this.custom_roles,
    required this.members_roles,
    this.events = const [],
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
      'members_roles': members_roles!.map((DocumentReference key, value) {
        return MapEntry(key.path, value);
      }),
      'events': events.map((x) => x).toList(),
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
        title: map['title'] as String?,
        groupid: map['groupid'] as String,
        design: map['design'] as dynamic,
        custom_roles: map['custom_roles'] as Map<String, MaterialColor>?,
        members_roles: mapStringDynamic2DocRefDynamic(map["members_roles"]),
        events: forceDocumentReferenceType(map['events']));
  }

  String toJson() => json.encode(toMap());

  factory Group.fromJson(String source) =>
      Group.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Group(title: $title, groupid: $groupid, Design : $design, custom_roles: $custom_roles, members_roles: $members_roles, events: $events)';
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
  String? alias;
  String password;
  String? description;
  String? mail;
  String? profile_picture;
  List<String> permissions;
  List<DocumentReference> events;
  List<DocumentReference> joined_groups;
  List<DocumentReference> saved_events;
  List<DocumentReference> followed_groups;
  List<DocumentReference> close_friends;
  List<DocumentReference> pinned_groups;
  User(
      {required this.username,
      this.alias,
      required this.password,
      this.description,
      this.mail,
      this.profile_picture,
      this.permissions = const <String>[],
      this.events = const <DocumentReference>[],
      this.joined_groups = const <DocumentReference>[],
      this.saved_events = const <DocumentReference>[],
      this.followed_groups = const <DocumentReference>[],
      this.close_friends = const <DocumentReference>[],
      this.pinned_groups = const <DocumentReference>[]});
  User copyWith({
    String? username,
    String? alias,
    String? password,
    String? description,
    String? mail,
    String? profile_picture,
    List<String>? permissions,
    List<DocumentReference>? events,
    List<DocumentReference>? joined_groups,
    List<DocumentReference>? saved_events,
    List<DocumentReference>? followed_groups,
    List<DocumentReference>? close_friends,
    List<DocumentReference>? pinned_groups,
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
        pinned_groups: pinned_groups ?? this.pinned_groups,
        permissions: permissions ?? this.permissions);
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
      'pinned_groups': pinned_groups.map((x) => x).toList(),
      'permissions': permissions,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    //print(map);
    return User(
      username: map['username'] as String,
      alias: map['alias'] as String?,
      password: map['password'] as String,
      description: map['description'] as String?,
      mail: map['mail'] as String?,
      profile_picture: map['profile_picture'] as String?,
      permissions: forceStringType(map['permissions']),
      events: forceDocumentReferenceType(map['events']),
      joined_groups: forceDocumentReferenceType(map['joined_groups']),
      saved_events: forceDocumentReferenceType(map['saved_events']),
      followed_groups: forceDocumentReferenceType(map['followed_groups']),
      close_friends: forceDocumentReferenceType(map['close_friends']),
      pinned_groups: forceDocumentReferenceType(map['pinned_groups']),
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'User(username: $username, alias: $alias, password: $password, description: $description, mail: $mail, profile_picture: $profile_picture, permissions: $permissions, events: $events, joined_groups: $joined_groups, saved_events: $saved_events, followed_groups: $followed_groups, close_friends: $close_friends, pinned_groups: $pinned_groups)';
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
        listEquals(other.permissions, permissions) &&
        listEquals(other.events, events) &&
        listEquals(other.joined_groups, joined_groups) &&
        listEquals(other.saved_events, saved_events) &&
        listEquals(other.followed_groups, followed_groups) &&
        listEquals(other.close_friends, close_friends) &&
        listEquals(other.pinned_groups, pinned_groups);
  }

  @override
  int get hashCode {
    return username.hashCode ^
        alias.hashCode ^
        password.hashCode ^
        description.hashCode ^
        mail.hashCode ^
        profile_picture.hashCode ^
        permissions.hashCode ^
        events.hashCode ^
        joined_groups.hashCode ^
        saved_events.hashCode ^
        followed_groups.hashCode ^
        close_friends.hashCode ^
        pinned_groups.hashCode;
  }
}

/*
  Demo Objects
*/

User demoUser = User(username: "demo", password: "demo");
Group demoGroup = Group(
    groupid: "demo",
    members_roles: {db.doc("${branchPrefix}/groups/demo"): "Founder"});
Event demoEvent = Event(eventid: "demo");
