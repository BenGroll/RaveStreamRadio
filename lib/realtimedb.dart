import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/chatting.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/extensions.dart';

FirebaseDatabase rtdb = FirebaseDatabase.instanceFor(
    app: app,
    databaseURL:
        "https://ravestreammobileapp-default-rtdb.europe-west1.firebasedatabase.app/");

Stream listenToChat(String ID) {
  Stream<DatabaseEvent> stream = rtdb.ref("root/Chats/$ID").onValue;
  return stream;
}

Future<Chat?> getChat_rtdb(String ID) async {
  DataSnapshot snap = await rtdb.ref("root/Chats/$ID").get();
  if (snap.exists) {
    return Chat.fromDBSnapshot(snap.value as Map);
  } else {
    return null;
  }
}

Future setChatData(Chat chat) async {
  DatabaseReference ref = rtdb.ref("root/Chats/${chat.id}");
  ref.set(chat.toMap());
}

Future addMessageToChat(Message message, Chat chat) async {
  DatabaseReference ref = rtdb.ref("root/Chats/${chat.id}");
  chat.messages.add(message);
  await ref.set(chat.toMap());
  return;
}
