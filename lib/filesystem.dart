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

UserSettings defaultusersettings = UserSettings(lang: "en");

const errorWhiteImage =
    Image(image: AssetImage("graphics/image_not_found_white_on_trans.png"));
const errorBlackImage =
    Image(image: AssetImage("graphics/image_not_found_black_on_trans.png"));

FirebaseStorage firebasestorage = FirebaseStorage.instance;

class UserSettings {
  String lang = "en";
  UserSettings({required this.lang});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{"lang": lang};
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(lang: map["lang"] as String);
  }
}

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> get _usersettingsfile async {
  final path = await _localPath;
  return File('$path/usersettings.dart');
}

Future<File> get _logindatafile async {
  final path = await _localPath;
  return File('$path/logindata.dart');
}

Future<File> writeUserSettingsMobile(UserSettings usersettingsobject) async {
  final file = await _usersettingsfile;
  return file.writeAsString(json.encode(usersettingsobject.toMap()));
}

Future<UserSettings> readUserSettingsMobile() async {
  final file = await _usersettingsfile;
  return UserSettings.fromMap(json.decode(await file.readAsString()));
}

Future<File> writeLoginDataMobile(String username, String password) async {
  final file = await _logindatafile;
  String datatowrite =
      json.encode({"username": username, "password": password});
  return file.writeAsString(datatowrite);
}

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

Future<Widget?> getImage(String imagepath) async {
  if (imagepath.isEmpty) {
    return null;
  } else {
    if (saved_pictures.keys.contains(imagepath)) {
      return saved_pictures[imagepath];
    } else {
      try {
        Reference test = firebasestorage.ref().child(imagepath);
        Uint8List? raw_image_data = await test.getData();
        if (raw_image_data == null) {
          return null;
        }

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
}

Future<Widget> getEventIcon(dbc.Event event) async {
  if (event.icon != null) {
    // Get Event's Own Icon
    return await getImage(event.icon ?? "") ?? errorWhiteImage;
  } else {
    if (event.hostreference == null) {
      //print("@fs : No Host specified.");
      return const Image(
          image: AssetImage("graphics/DefaultEventTemplate.jpg"));
    } else {
      DocumentSnapshot<Map<String, dynamic>> host = await event.hostreference
          ?.get() as DocumentSnapshot<Map<String, dynamic>>;
      if (host == null) {
        //print("@fs : Couldnt get Host document");
        return errorWhiteImage;
      }
      if (host.data() == null) {
        //print("@fs : Host data couldnt be read");
        return errorWhiteImage;
      }
      if (host.data()?["profile_picture"] == null) {
        //print("@fs : Host has no profile picture.");
        return SvgPicture.asset("graphics/person_black_48dp.svg",
            color: cl.greynothighlight);
      }
      Widget? hostProfilePic =
          await getImage(host.data()?["profile_picture"] as String);
      if (hostProfilePic == null) {
        //print("@fs : Host has no profile picture.");
        return SvgPicture.asset("graphics/person_black_48dp.svg",
            color: cl.greynothighlight);
      } else {
        return hostProfilePic;
      }
    }
  }
}

Future<Widget> getEventFlyer(dbc.Event event) async {
  if (event.flyer != null) {
    // Get Event's Own Icon
    return await getImage(event.flyer ?? "") ?? errorWhiteImage;
  } else {
    return getEventIcon(event);
  }
}
