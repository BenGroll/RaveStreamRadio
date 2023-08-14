// ignore_for_file: public_member_api_docs, sort_constructors_first, avoid_init_to_null, non_constant_identifier_names
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/database.dart' show db;
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/screens/managecalendarscreen.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/extensions.dart';
import 'dart:io' show File;

/// DataClass for Link (Pair of Title and url)
class Link {
  String title;
  String url;
  Link({required this.title, required this.url});
  bool operator ==(covariant Link other) {
    if (identical(this, other)) return true;
    return other.title == other.title && other.url == other.url;
  }
}

/// Creates List<Link> from {"title" : "url"} maps
List<Link> linkListFromMap(Map<String, String> map) {
  List<Link> outmap = [];
  map.keys.forEach((element) {
    outmap.add(Link(title: element, url: map[element]!));
  });
  return outmap;
}

/// Reverse of linkListFromMap
///
/// Creates {"title" : url} map from List<Link>
Map<String, String> mapFromLinkList(List<Link> linklist) {
  Map<String, String> outmap = {};
  linklist.forEach((element) {
    outmap[element.title] = element.url;
  });
  return outmap;
}

/// Converts a list of db User permissions to list of GlobalPermission objects
List<GlobalPermission> dbPermissionsToGlobal(List<String> permits) {
  print(permits);
  List<GlobalPermission> outlist = [];
  if (permits.contains("ADMIN")) {
    outlist.add(GlobalPermission.ADMIN);
    outlist.add(GlobalPermission.CHANGE_DEV_SETTINGS);
    outlist.add(GlobalPermission.MANAGE_EVENTS);
    outlist.add(GlobalPermission.MANAGE_HOSTS);
    outlist.add(GlobalPermission.MODERATE);

    return outlist;
  }
  permits.forEach((element) {
    switch (element) {
      case "MANAGE_EVENTS":
        outlist.add(GlobalPermission.MANAGE_EVENTS);
        break;
      case "CHANGE_DEV_SETTINGS":
        outlist.add(GlobalPermission.CHANGE_DEV_SETTINGS);
        break;
      case "MANAGE_HOSTS":
        outlist.add(GlobalPermission.MANAGE_HOSTS);
        break;
      case "MODERATE":
        outlist.add(GlobalPermission.MODERATE);
        break;
    }
  });
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
/// [templateHostID] (externally moderated Hostname override)
///
/// [templateHostID] is used to implement the option to add events to the calendar as a ravestream member.
///
/// If [templateHostID] is null, it will default to load event to be hostet by a Host themselves.
///
/// If [templateHostID] is not null, it will be modifyable by ravestream members, and the value given will be displayed instead of the linkbutton that normally links to the host
///
class Event {
  String? title;
  String eventid;
  DocumentReference? hostreference;
  Timestamp? begin;
  Timestamp? end;
  GeoPoint? location;
  String? locationname;
  String? genre;
  int minAge = DEFAULT_MINAGE;
  String? icon;
  String? flyer;
  String? description;
  String? timetable;
  Map<String, String>? links;
  Map<DocumentReference, String>? guestlist;
  int savedcount;
  String? templateHostID;
  String status;
  Event({
    this.title = null,
    required this.eventid,
    this.hostreference = null,
    this.begin = null,
    this.end = null,
    this.location = null,
    this.locationname,
    this.minAge = 18,
    this.genre = null,
    this.icon = null,
    this.flyer = null,
    this.description,
    this.timetable = null,
    this.links = null,
    this.guestlist,
    this.savedcount = 0,
    this.templateHostID,
    this.status = "public",
  });

  Event copyWith({
    String? title,
    required String eventid,
    DocumentReference? hostreference,
    Timestamp? begin,
    Timestamp? end,
    GeoPoint? location,
    String? locationname,
    int minAge = 0,
    String? genre,
    String? icon,
    String? flyer,
    String? description,
    String? timetable,
    Map<String, String>? links,
    Map<DocumentReference, String>? guestlist,
    int? savedcount,
    String? templateHostID,
    String? status,
  }) {
    return Event(
      title: title ?? this.title,
      eventid: eventid,
      hostreference: hostreference ?? hostreference,
      begin: begin ?? this.begin,
      end: end ?? this.end,
      location: location ?? this.location,
      locationname: locationname ?? this.locationname,
      minAge: minAge,
      genre: genre,
      icon: icon ?? this.icon,
      flyer: flyer ?? this.flyer,
      description: description ?? this.description,
      timetable: timetable ?? this.timetable,
      links: links ?? this.links,
      guestlist: guestlist ?? this.guestlist,
      savedcount: savedcount ?? this.savedcount,
      templateHostID: templateHostID ?? this.templateHostID,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'eventid': eventid,
      'hostreference': hostreference as DocumentReference?,
      'begin': begin,
      'end': end,
      'location': location,
      'locationname': locationname,
      'minAge': minAge,
      'genre': genre,
      'icon': icon,
      'flyer': flyer,
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
      'templateHostID': templateHostID,
      'status': status,
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
          minAge: inputmap["minAge"],
          genre: inputmap["genre"],
          icon: inputmap["icon"],
          flyer: inputmap["flyer"],
          description: inputmap["description"],
          timetable: inputmap["timetable"],
          links: forceStringStringMapFromStringDynamic(inputmap["links"]),
          guestlist: forceDocumentReferenceStringMapTypeFromStringDynamic(
              inputmap["guestlist"]),
          templateHostID: inputmap['templateHostID'],
          status:
              inputmap.containsKey("status") ? inputmap["status"] : "public");
      return mapevent;
    } catch (e) {
      return Event(eventid: "errorevent");
    }
  }

  Map<String, dynamic> toJsonCompatibleMap() {
    Map<String, dynamic> object = toMap();
    if (object["hostreference"] != null) {
      object["hostreference"] = object["hostreference"].path;
    }
    if (object["begin"] != null) {
      object["begin"] =
          DateTime.fromMillisecondsSinceEpoch(object["begin"].seconds)
              .microsecondsSinceEpoch;
    }
    if (object["end"] != null) {
      object["end"] = DateTime.fromMillisecondsSinceEpoch(object["end"].seconds)
          .microsecondsSinceEpoch;
    }
    object["description"] = "DSC";
    return object;
  }

  String toJson() {
    return json.encode(toJsonCompatibleMap()).dbsafe;
  }

  factory Event.fromJson(String source) {
    Map<String, dynamic> map = json.decode(source.fromDBSafeString);
    if (map["hostreference"] != null) {
      map["hostreference"] = db.doc(map["hostreference"]);
    }
    if (map["begin"] != null) {
      map["begin"] = Timestamp.fromMillisecondsSinceEpoch(map["begin"]);
    }
    if (map["end"] != null) {
      map["end"] = Timestamp.fromMillisecondsSinceEpoch(map["end"]);
    }
    map["description"] = "DSC";
    return Event.fromMap(map);
  }

  @override
  String toString() {
    return 'Event(title: "$title", eventid: "$eventid", hostreference: "$hostreference", begin: "$begin", end: "$end", location: "$location", locationname: "$locationname", minAge: "$minAge", icon: "$icon", description: "*", timetable: "$timetable", links: "$links", guestlist: "$guestlist", savedcount: "$savedcount", templateHostID: $templateHostID, status: $status)';
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
        other.minAge == minAge &&
        other.genre == genre &&
        other.icon == icon &&
        other.flyer == flyer &&
        other.description == description &&
        other.timetable == timetable &&
        mapEquals(other.links, links) &&
        mapEquals(other.guestlist, guestlist) &&
        other.savedcount == savedcount &&
        other.templateHostID == templateHostID &&
        other.status == status;
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
        minAge.hashCode ^
        genre.hashCode ^
        icon.hashCode ^
        flyer.hashCode ^
        description.hashCode ^
        timetable.hashCode ^
        links.hashCode ^
        guestlist.hashCode ^
        savedcount.hashCode ^
        templateHostID.hashCode ^
        status.hashCode;
  }
}

/// Template class for Groups to avoid type and valueerrors
class Group {
  String? title;
  String groupid;
  dynamic design;
  Map<String, MaterialColor>? custom_roles;
  Map<DocumentReference, dynamic>? members_roles;
  List<DocumentReference> events;
  String? description;
  File? image;
  Group(
      {this.title,
      required this.groupid,
      this.design = null,
      this.custom_roles,
      required this.members_roles,
      this.events = const [],
      this.description,
      this.image});

  Group copyWith(
      {String? title,
      required String groupid,
      dynamic design,
      Map<String, MaterialColor>? custom_roles,
      Map<DocumentReference, dynamic>? members_roles,
      List<DocumentReference>? events,
      String? description,
      File? image}) {
    return Group(
        title: title ?? this.title,
        groupid: groupid,
        design: design ?? this.design,
        custom_roles: custom_roles ?? this.custom_roles,
        members_roles: members_roles ?? this.members_roles,
        events: events ?? this.events,
        description: description ?? this.description,
        image: image ?? this.image);
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
      'description': description,
      'image': image
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
        title: map['title'] as String?,
        groupid: map['groupid'] as String,
        design: map['design'] as dynamic,
        custom_roles: map['custom_roles'] as Map<String, MaterialColor>?,
        members_roles: mapStringDynamic2DocRefDynamic(map["members_roles"]),
        events: forceDocumentReferenceType(map['events']),
        description: map['description'],
        image: map['image']);
  }

  String toJson() => json.encode(toMap());

  factory Group.fromJson(String source) =>
      Group.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Group(title: $title, groupid: $groupid, Design : $design, custom_roles: $custom_roles, members_roles: $members_roles, events: $events, description: $description, image: $image)';
  }

  @override
  bool operator ==(covariant Group other) {
    if (identical(this, other)) return true;

    return other.title == title &&
        other.groupid == groupid &&
        other.design == design &&
        mapEquals(other.custom_roles, custom_roles) &&
        mapEquals(other.members_roles, members_roles) &&
        listEquals(other.events, events) &&
        other.description == description &&
        other.image == image;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        groupid.hashCode ^
        design.hashCode ^
        custom_roles.hashCode ^
        members_roles.hashCode ^
        events.hashCode ^
        image.hashCode;
  }
}

/// Template class for Users
class User {
  String username;
  String? alias;
  String password;
  String? description;
  String? mail;
  String? profile_picture;
  String path;
  int?  lastEditedInMs;
  List<String> permissions;
  List<String> chats;
  List<String> deviceTokens;
  List<String> topics;
  List<DocumentReference> events;
  List<DocumentReference> joined_groups;
  List<DocumentReference> saved_events;
  List<DocumentReference> followed_groups;
  List<DocumentReference> close_friends;
  List<DocumentReference> pinned_groups;

  User({
    required this.username,
    this.alias,
    required this.password,
    this.description,
    this.mail,
    this.profile_picture,
    required this.path,
    required lastEditedInMs,
    this.topics = const [],
    this.permissions = const <String>[],
    this.chats = const <String>[],
    this.deviceTokens = const <String>[],
    this.events = const <DocumentReference>[],
    this.joined_groups = const <DocumentReference>[],
    this.saved_events = const <DocumentReference>[],
    this.followed_groups = const <DocumentReference>[],
    this.close_friends = const <DocumentReference>[],
    this.pinned_groups = const <DocumentReference>[],
  });
  User copyWith({
    String? username,
    String? alias,
    String? password,
    String? description,
    String? mail,
    String? profile_picture,
    String? path,
    int? lastEditedInMs,
    List<String>? topics,
    List<String>? permissions,
    List<String>? chats,
    List<String>? deviceTokens,
    List<DocumentReference>? events,
    List<DocumentReference>? joined_groups,
    List<DocumentReference>? saved_events,
    List<DocumentReference>? followed_groups,
    List<DocumentReference>? close_friends,
    List<DocumentReference>? pinned_groups,
  }) {
    return User(
      lastEditedInMs: lastEditedInMs ?? this.lastEditedInMs,
        username: username ?? this.username,
        alias: alias ?? this.alias,
        password: password ?? this.password,
        description: description ?? this.description,
        mail: mail ?? this.mail,
        profile_picture: profile_picture ?? this.profile_picture,
        chats: chats ?? this.chats,
        deviceTokens: deviceTokens ?? this.deviceTokens,
        events: events ?? this.events,
        joined_groups: joined_groups ?? this.joined_groups,
        saved_events: saved_events ?? this.saved_events,
        followed_groups: followed_groups ?? this.followed_groups,
        close_friends: close_friends ?? this.close_friends,
        pinned_groups: pinned_groups ?? this.pinned_groups,
        permissions: permissions ?? this.permissions,
        path: path ?? this.username,
        topics: topics ?? this.topics);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'username': username,
      'alias': alias,
      'password': password,
      'description': description,
      'mail': mail,
      'profile_picture': profile_picture,
      'path': path,
      'lastEditedInMs' : lastEditedInMs,
      'events': events.map((x) => x).toList(),
      'chats': chats,
      'topics': topics,
      'joined_groups': joined_groups.map((x) => x).toList(),
      'saved_events': saved_events.map((x) => x).toList(),
      'followed_groups': followed_groups.map((x) => x).toList(),
      'close_friends': close_friends.map((x) => x).toList(),
      'pinned_groups': pinned_groups.map((x) => x).toList(),
      'permissions': permissions,
      'deviceTokens': deviceTokens
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    pprint("Usermap: $map");
    return User(
      username: map['username'] as String,
      lastEditedInMs: map.containsKey("lastEditedInMs") && map["lastEditedInMs"] != null ? map['lastEditedInMs'] as int : 0,
      alias: map['alias'] as String?,
      password: map['password'] as String,
      description: map['description'] as String?,
      mail: map['mail'] as String?,
      profile_picture: map['profile_picture'] as String?,
      path: map["path"] as String,
      topics: map.containsKey("topics") ? forceStringType(map["topics"]) : [],
      permissions: map.containsKey("permissions") ? forceStringType(map['permissions']) : [],
      chats: map.containsKey("chats") ? forceStringType(map['chats']) : [],
      deviceTokens: map.containsKey("deviceTokens") ? forceStringType(map['deviceTokens']) : [],
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
    return 'User(username: $username, alias: $alias, password: $password, description: $description, mail: $mail, profile_picture: $profile_picture, permissions: $permissions, path: $path, lastEditedInMs: $lastEditedInMs, chats: $chats, events: $events, joined_groups: $joined_groups, saved_events: $saved_events, followed_groups: $followed_groups, close_friends: $close_friends, pinned_groups: $pinned_groups, deviceTokens: $deviceTokens, topics: $topics)';
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
        other.path == path &&
        other.chats == chats &&
        other.deviceTokens == deviceTokens &&
        other.topics == topics &&
        other.lastEditedInMs == other &&
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
        lastEditedInMs.hashCode ^
        alias.hashCode ^
        password.hashCode ^
        description.hashCode ^
        mail.hashCode ^
        profile_picture.hashCode ^
        permissions.hashCode ^
        chats.hashCode ^
        topics.hashCode ^
        deviceTokens.hashCode ^
        path.hashCode ^
        events.hashCode ^
        joined_groups.hashCode ^
        saved_events.hashCode ^
        followed_groups.hashCode ^
        close_friends.hashCode ^
        pinned_groups.hashCode;
  }
}

/// Enum of possible Categories a host can be ordered into
enum HostCategory { collective, festival, host, location, eventseries, label }

/// Safely get permit from object.
bool? getPermit(Map<String, dynamic> host) {
  if (host.containsKey("permit")) {
    return host["permit"];
  }
  if (host.containsKey("genehmigung")) {
    Map<String, dynamic> map = host;
    host["permit"] = host["genemigung"] == "ja";
    host.remove("genehmigung");
    db.collection("demohosts").doc(map["id"]).set(host);
    return host["permit"];
  }
  return null;
}

/// Safely get 'official_logo' field from host
bool? getOfficialLogo(Map<String, dynamic> host) {
  if (host.containsKey("official_logo")) {
    return host["official_logo"];
  }
  if (host.containsKey("offiziel_logo")) {
    Map<String, dynamic> map = host;
    host["official_logo"] = host["offiziel_logo"] == "ja";
    host.remove("offiziel_logo");
    db.collection("demohosts").doc(map["id"]).set(host);
    return host["offiziel_logo"] == "ja";
  }
  return null;
}

/// Safely get category from Host
HostCategory? getCategory(Map<String, dynamic> host) {
  if (host.containsKey("category")) {
    if (host["category"] == "collective") return HostCategory.collective;
    if (host["category"] == "host") return HostCategory.host;
    if (host["category"] == "eventseries") return HostCategory.eventseries;
    if (host["category"] == "label") return HostCategory.label;
    if (host["category"] == "festival") return HostCategory.festival;
    if (host["category"] == "location") return HostCategory.location;
  }
  if (host.containsKey("kategorie")) {
    pprint("Kat: ${host["kategorie"]}");
    String kat = host["kategorie"];
    if (kat == "Kollektiv") {
      Map<String, dynamic> data = host;
      data["category"] = "collective";
      data.remove("kategorie");
      db.collection("demohosts").doc(host["id"]).set(data);
      return HostCategory.collective;
    }
    if (kat == "Veranstalter") {
      Map<String, dynamic> data = host;
      data["category"] = "host";
      data.remove("kategorie");
      db.collection("demohosts").doc(host["id"]).set(data);
      return HostCategory.host;
    }
    if (kat == "Party-Reihe") {
      Map<String, dynamic> data = host;
      data["category"] = "eventseries";
      data.remove("kategorie");
      db.collection("demohosts").doc(host["id"]).set(data);
      return HostCategory.host;
    }
    if (kat == "Label") {
      Map<String, dynamic> data = host;
      data["category"] = "label";
      data.remove("kategorie");
      db.collection("demohosts").doc(host["id"]).set(data);
      return HostCategory.host;
    }
    if (kat == "Festival") {
      Map<String, dynamic> data = host;
      data["category"] = "festival";
      data.remove("kategorie");
      db.collection("demohosts").doc(host["id"]).set(data);
      return HostCategory.host;
    }
    if (kat == "Location") {
      Map<String, dynamic> data = host;
      data["category"] = "location";
      data.remove("Location");
      db.collection("demohosts").doc(host["id"]).set(data);
      return HostCategory.host;
    }
    return null;
  }
  return null;
}

class Host {
  final List<Link>? links;
  final String? logopath;
  final String name;
  final String id;
  final HostCategory? category;
  final bool? permit;
  final bool? official_logo;
  Host(
      {this.links,
      this.logopath,
      required this.name,
      required this.id,
      this.category,
      this.permit,
      this.official_logo});
  factory Host.fromMap(Map<String, dynamic> map) {
    return Host(
        permit: getPermit(map),
        category: getCategory(map),
        official_logo: getOfficialLogo(map),
        links: linkListFromMap(map.containsKey("links")
            ? forceStringStringMapFromStringDynamic(map["links"]) ?? {}
            : {} as Map<String, String>),
        logopath: map.containsKey("logopath") ? map["logopath"] : null,
        name: map["name"],
        id: map["id"]);
  }
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "links": mapFromLinkList(links ?? <Link>[]),
      "logopath": logopath,
      "name": name,
      "category": category?.name,
      "permit": permit,
      "official_logo": official_logo
    };
  }
}

enum ReportState { filed, pending, completed }

ReportState mapRepState(String state) {
  if (state == "filed") return ReportState.filed;
  if (state == "pending") return ReportState.pending;
  if (state == "completed") return ReportState.completed;
  return ReportState.filed;
}

class Report {
  final String? id;
  final Timestamp? timestamp;
  final DocumentReference? issuer;
  final DocumentReference? target;
  final String? description;
  final ReportState state;
  final Timestamp? finishedat;
  final DocumentReference? finishedby;
  Report(
      {required this.id,
      required this.timestamp,
      this.issuer,
      this.target,
      this.description,
      this.state = ReportState.pending,
      this.finishedat,
      this.finishedby});
  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
        id: map["id"],
        timestamp: map["timestamp"],
        issuer: map["issuer"],
        target: map["target"] != null ? db.doc(map["target"]) : null,
        state: mapRepState(map["state"]),
        description: map["description"],
        finishedat: map["finishedat"],
        finishedby: map["finishedby"]);
  }
}

enum FeedbackCategory { Bug, Idea, Positive, Moderation, Content, Other }

class FeedBackCollector {
  String feedbackcontent;
  FeedbackCategory category;
  String? feedbackSenderUserName;
  FeedBackCollector(
      {required this.feedbackcontent,
      required this.category,
      required this.feedbackSenderUserName});
  Map<String, dynamic> toMap() {
    return {
      "feedbackcontent": feedbackcontent,
      "category": category.name,
      "feedbackSenderUserName": feedbackSenderUserName
    };
  }
}

// Demo Objects
User demoUser =
    User(username: "demo", password: "demo", path: "dev.users/demo", lastEditedInMs: Timestamp.now().millisecondsSinceEpoch);
Group demoGroup = Group(
    groupid: "demo",
    members_roles: {db.doc("${branchPrefix}/groups/demo"): "Founder"});
Event demoEvent = Event(eventid: "demo");

enum FeedEntryType { EVENT_POSTED, EVENT_UPDATED, ANNOUNCEMENT }

class FeedEntry {
  String ownerpath;
  Timestamp timestamp;
  String? leading_image_path_download_link;
  FeedEntryType type;
  String? textcontent;
  FeedEntry(
      {required this.ownerpath,
      required this.timestamp,
      this.leading_image_path_download_link,
      required this.type,
      this.textcontent});
  Map<String, dynamic> toMap() {
    return {
      "ownerpath": ownerpath,
      "timestamp": timestamp.millisecondsSinceEpoch,
      "leading_image_path_download_link": leading_image_path_download_link,
      "type": type.name,
      "textcontent": textcontent
    };
  }

  factory FeedEntry.fromMap(Map<String, dynamic> map) {
    return FeedEntry(
        textcontent:
            map.containsKey("textcontent") && map["textcontent"] != null
                ? map["textcontent"]
                : null,
        ownerpath: map["ownerpath"],
        timestamp: Timestamp.fromMillisecondsSinceEpoch(map["timestamp"]),
        leading_image_path_download_link:
            map.containsKey("leading_image_path_download_link") &&
                    map["leading_image_path_download_link"] != null
                ? map["leading_image_path_download_link"]
                : null,
        type: FeedEntryType.values
            .firstWhere((element) => element.name == map["type"]));
  }
  String toString() {
    return "FeedEntry(ownerpath: $ownerpath, timestamp: $timestamp, leading_image_path_download_link: $leading_image_path_download_link, type: $type, textcontent: $textcontent)";
  }
}
