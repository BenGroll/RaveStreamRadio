import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/chatting.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/extensions.dart';
import 'conv.dart';
import 'package:firebase_database/firebase_database.dart';

FirebaseDatabase rtdb = FirebaseDatabase.instanceFor(
    app: app,
    databaseURL:
        "https://ravestreammobileapp-default-rtdb.europe-west1.firebasedatabase.app/");

Stream listenToChat(String ID) {
  print("ID: $ID");
  Stream<DatabaseEvent> stream = rtdb.ref("root/Chats/$ID").onValue;
  return stream;
}

Future<Chat?> getChat_rtdb(String ID) async {
  DataSnapshot snap = await rtdb.ref("root/Chats/$ID").get();
  if (snap.exists) {
    Chat chat = Chat.fromMap(snap.value as Map);
    DataSnapshot messages = await rtdb.ref("root/Chats/$ID/messages").get();
    List<String> messageIDList = forceStringType(messages.value as List);
    print("MessageIDList: $messageIDList");
    List<Future> futures = [];
    messageIDList.forEach((element) {
      futures.add(rtdb.ref("root/Messages/$element").get());
    });
    List snapshots = await Future.wait(futures);
    //print(snapshots);
    List<Message> messageList = [];
    snapshots.forEach((element) {
      messageList.add(Message.fromMap(element.value as Map));
    });
    print(messageList);
    chat.messages = messageList;
    return chat;
  } else {
    return null;
  }
}

Future setChatData(Chat chat) async {
  DatabaseReference ref = rtdb.ref("root/Chats/${chat.id}");
  ref.set(chat.toMap());
}

Future addMessageToChat(Message message, Chat chat) async {
  Message totalMessage = await addMessage(message);
  DataSnapshot ref = await rtdb.ref("root/Chats/${chat.id}/messages").get();
  List<Object?> messages = ref.value == null ? [] : ref.value as List<Object?>;
  messages.add(totalMessage.id);
  await rtdb.ref("root/Chats/${chat.id}/messages").set(messages);
  return Future.delayed(Duration.zero);
}

Future<Message> addMessage(Message message) async {
  String messageID = generateDocumentID();
  await rtdb.ref("root/Messages/$messageID").set(message.toMap());
  message.id = messageID;
  return message;
}
