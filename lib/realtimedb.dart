import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/chatting.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ravestreamradioapp/shared_state.dart';

FirebaseDatabase rtdb = FirebaseDatabase.instanceFor(
    app: app,
    databaseURL:
        "https://ravestreammobileapp-default-rtdb.europe-west1.firebasedatabase.app/");

Stream listenToChat(String ID) {
  Stream<DatabaseEvent> stream = rtdb.ref("root/Chats/$ID").onValue;
  return stream;
}

Future setChatData(Chat chat) async {
  DatabaseReference ref = rtdb.ref("root/Chats/${chat.id}");
  ref.set(chat.toMap());
}
