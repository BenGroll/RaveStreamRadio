// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'main.dart' as main;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;

Future<dynamic> sendFCMMessageToTokens(
    List<String> tokens, String title, String content) async {
  HttpsCallable lol = await db.getCallableFunction("sendMessageToDeviceTokens");
  HttpsCallableResult res = await lol.call([tokens, title, content]);
  return res.data;
}

Future sendMessageToUsername(
    String username, String title, String content) async {
  dbc.User? user = await db.getUser(username);
  if (user == null) return;
  await sendMessageToUsersDevices(user, title, content);
}

Future<List> sendMessageToUsersDevices(
    dbc.User user, String title, String content) async {
  try {
    List<String> deviceTokens = user.deviceTokens;
    return await sendFCMMessageToTokens(deviceTokens, title, content);
  } catch (e) {
    return [];
  }
}

Future sendMessageToTopic(
    String topicname, String title, String content) async {
  Map<String, dynamic>? userInTopic = await db.getUsersForTopic(topicname);
  if (userInTopic == null) return;
  List<String> tokens = [];
  userInTopic.forEach((key, value) {
    tokens.addAll(forceStringType(value));
  });
  print(tokens);
  return sendFCMMessageToTokens(tokens, title, content);
}

class MessagingAPI {
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  late BuildContext? context;
  MessagingAPI({this.context});

  registerApp() async {
    firebaseMessaging.requestPermission(
        alert: true, badge: true, provisional: false, sound: true);
    fcmToken = await firebaseMessaging.getToken();
    print("FCMToken: $fcmToken");
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("This opens on Live message, $context");
      if (context != null)
        ScaffoldMessenger.of(context!)
          .showMaterialBanner(cw.NotificationBanner(message, context!));
    });
    FirebaseMessaging.onBackgroundMessage(main.handleBackgroundMessage);
    return;
  }
}
