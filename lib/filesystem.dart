import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/debugsettings.dart';
import 'colors.dart' as cl;
import 'package:ravestreamradioapp/shared_state.dart';
import 'shared_state.dart' as shs;
import 'package:ravestreamradioapp/extensions.dart';
import 'package:ravestreamradioapp/database.dart' as db;

/// Error Image with white logo and transparent background.
const errorWhiteImage =
    Image(image: AssetImage("graphics/Event_2000x2000.jpeg"));

/// Error Image with black logo and transparent.
const errorBlackImage =
    Image(image: AssetImage("graphics/image_not_found_black_on_trans.png"));

/// Firebase Storage-Space Instance
FirebaseStorage firebasestorage = FirebaseStorage.instance;

/// Path to application directory in the devices storage
Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

/// Reference to the file where the usersettings are being saved
Future<File> get _usersettingsfile async {
  final path = await _localPath;
  return File('$path/usersettings.dart');
}

/// Reference to the file where the login-credentials are saved.
///
/// To be replaced with Hash
Future<File> get _logindatafile async {
  final path = await _localPath;
  return File('$path/logindata.dart');
}

/// Write usersettings to the devices long-term storage to allow remembering them
Future<File> writeUserSettingsMobile(UserSettings usersettingsobject) async {
  final file = await _usersettingsfile;
  return file.writeAsString(json.encode(usersettingsobject.toMap()));
}

/// Read USer Settings from the devices long-term storage
Future<UserSettings> readUserSettingsMobile() async {
  final file = await _usersettingsfile;
  return UserSettings.fromMap(json.decode(await file.readAsString()));
}

/// Write login credentials to the devices long-term storage to allow remembering them
///
/// To be replaced with Hash
Future<File> writeLoginDataMobile(String username, String password) async {
  final file = await _logindatafile;
  String datatowrite =
      json.encode({"username": username, "password": password});
  return file.writeAsString(datatowrite);
}

/// Read login credentials to the devices long-term storage to allow remembering them
Future<Map> readLoginDataMobile() async {
  final file = await _logindatafile;
  if (file.existsSync()) {
    return json.decode(await file.readAsString());
  } else {
    return {"username": "", "password": ""};
  }
}

/// Not Working RN, Only typesafe
Future writeUserSettingsWeb(UserSettings usersettingsobject) async {
  return Future;
}

/// Not Working RN, Only typesafe
Future<UserSettings> readUserSettingsWeb() async {
  return defaultusersettings;
}

/// Not Working RN, Only typesafe
Future writeLoginDataWeb(String username, String password) async {
  return Future;
}

/// Not Working RN, Only typesafe
/// Define if function should default to error or success with DEBUG_LOGIN_RETURN_TRUE_ON_WEB
Future<Map> readLoginDataWeb() async {
  return DEBUG_LOGIN_RETURN_TRUE_ON_WEB
      ? {"username": "demouser", "password": ""}
      : {"username": "", "password": ""};
}

/// Get Image from the Google Cloud storage.
///
/// Returns error image if file doesnt exists, so nullsafe
Future<Widget?> getImage(String imagepath) async {
  try {
    if (imagepath.isEmpty) {
      return null;
    } else {
      if (saved_pictures.keys.contains(imagepath)) {
        return saved_pictures[imagepath];
      } else {
        try {
          Reference test = firebasestorage.ref().child(imagepath);
          String dldURL =
              await test.getDownloadURL().catchError((error, stackTrace) {
            return "-1";
          });
          if (dldURL == "-1") return errorWhiteImage;
          Uint8List? raw_image_data = await test.getData().catchError((e) {
            return errorWhiteImage;
          });
          if (raw_image_data == null) return errorWhiteImage;
          //Save Image for later use in
          Widget createdImage = errorWhiteImage;
          if (imagepath.endsWith("svg")) {
            Widget createdImage = SvgPicture.asset(
              imagepath,
              color: Colors.white,
            );
          } else {
            createdImage = Image.memory(raw_image_data);
          }
          saved_pictures[imagepath] = createdImage;
          return createdImage;
        } catch (e) {
          return errorWhiteImage;
        }
      }
    }
  } catch (e) {
    return errorWhiteImage;
  }
}

/// get Icon of Event.
///
/// If event has no specified Icon, instead returns profile picture of the host.
///
/// If host has no specified Picture either, displays common Event Image
///
/// Common Image path: graphics\DefaultEventTemplate.jpg
Future<Widget> getEventIcon(dbc.Event event) async {
  if (event.icon != null) {
    // Get Event's Own Icon
    return await getImage(event.icon ?? "") ?? errorWhiteImage;
  } else {
    if (event.hostreference == null) {
      if (event.templateHostID != null) {
        String? imageLocation = await db.db
            .doc("demohosts/${event.templateHostID}")
            .get()
            .then((value) => value.data()?["logopath"]);
        if (imageLocation != null && imageLocation.isNotEmpty) {
          return await getImage(imageLocation.replaceAll(
                  "gs://ravestreammobileapp.appspot.com/", "")) ??
              errorWhiteImage;
        }
      }
      //pprint("@fs : No Host specified.");
      return const Image(
          image: AssetImage("graphics/DefaultEventTemplate.jpg"));
    } else {
      DocumentSnapshot<Map<String, dynamic>> host = await event.hostreference
          ?.get() as DocumentSnapshot<Map<String, dynamic>>;
      if (host == null) {
        //pprint("@fs : Couldnt get Host document");
        return errorWhiteImage;
      }
      if (host.data() == null) {
        //pprint("@fs : Host data couldnt be read");
        return errorWhiteImage;
      }
      if (host.data()?["profile_picture"] == null) {
        //pprint("@fs : Host has no profile picture.");
        return SvgPicture.asset("graphics/person_black_48dp.svg",
            color: cl.greynothighlight);
      }
      Widget? hostProfilePic =
          await getImage(host.data()?["profile_picture"] as String);
      if (hostProfilePic == null) {
        //pprint("@fs : Host has no profile picture.");
        return SvgPicture.asset("graphics/person_black_48dp.svg",
            color: cl.greynothighlight);
      } else {
        return hostProfilePic;
      }
    }
  }
}

/// Gets Flyer of Event
///
/// If the event has no specified Flyer, the Icon gets returned instead.
Future<Widget> getEventFlyer(dbc.Event event) async {
  if (event.flyer != null) {
    // Get Event's Own Icon
    return await getImage(event.flyer ?? "") ?? errorWhiteImage;
  } else {
    return getEventIcon(event);
  }
}
