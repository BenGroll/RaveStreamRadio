import "dart:convert";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:ravestreamradioapp/conv.dart";
import "package:ravestreamradioapp/database.dart";
import "package:ravestreamradioapp/filesystem.dart";
import 'dart:convert';
import 'dart:typed_data';
import 'package:ravestreamradioapp/extensions.dart' show Stringify, DocRef;

class Message {
  /// Contains full path to the Document
  final String sender;

  /// Contains full path to the Document
  final String? reciever;

  /// Leave empty if chat has more than two members
  final Timestamp sentAt;

  /// the utf8 content of the message
  final String content;
  Message(
      {required this.sender,
      this.reciever,
      required this.sentAt,
      required this.content});
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
        content: map["content"],
        sender: map["sender"],
        sentAt: Timestamp.fromMillisecondsSinceEpoch(map["sentAt"]),
        reciever: map["reciever"]);
  }
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sender': sender,
      'reciever': reciever,
      'sentAt': sentAt.millisecondsSinceEpoch,
      'content': content
    };
  }
}

List<Message> dynamicListToMessageList(List<dynamic> da) {
  List<Message> list = [];
  da.forEach((element) {
    Map<String, dynamic> map = element as Map<String, dynamic>;
    list.add(Message.fromMap(map));
  });
  return list;
}

List<Message> chatFromDB(List<Map<String, dynamic>> map) {
  List<Message> buffer = [];
  map.forEach((element) {
    buffer.add(Message(
        sender: "dev.users/admin",
        sentAt: Timestamp.now(),
        content: "Hallo Welt"));
  });
  return buffer;
}

List<Message> messagesFromDBSnapshot(List messagelist) {
    return messagelist
        .map((e) => Message(
            sender: e["sender"],
            sentAt: Timestamp.fromMillisecondsSinceEpoch(e["sentAt"]),
            content: e["content"]))
        .toList();
  }

class Chat {
  final String id;
  List<Message> messages;
  List<DocumentReference> members;
  String? pathToLogo;
  Chat(
      {this.messages = const [],
      required this.members,
      this.pathToLogo,
      required this.id});
  factory Chat.fromMap(Map map) {
    return Chat(
        members: forceDocumentReferenceFromStringList(map["members"]),
        messages: dynamicListToMessageList(map["messages"]),
        pathToLogo: map["pathToLogo"],
        id: map["id"]);
  }
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'messages': messages.map((e) => e.toMap()).toList(),
      'members': members.paths(),
      "pathToLogo": pathToLogo,
      "id": id
    };
  }

  

  factory Chat.fromDBSnapshot(Map snap) {
    List<String> members =
        forceStringType(snap["members"].map((e) => e.toString()).toList());
    List<Message> messagelist = messagesFromDBSnapshot(snap["messages"]);

    return Chat(
        members: forceDocumentReferenceFromStringList(members),
        id: snap["id"],
        messages: messagelist);
  }
}

String encodeChatAsJson(Chat chat) {
  return jsonEncode(chat.toMap());
}

Future uploadChatToDB(Chat chat) async {
  await firebasestorage
      .ref("chats/${chat.id}.json")
      .putString(encodeChatAsJson(chat));
}

Future<Chat> readChatFromDB(String id) async {
  dynamic pathReference = firebasestorage.ref("chats/$id.json");
  Uint8List? data = await pathReference.getData(100 * 1024 * 1024);
  Map map = json.decode(String.fromCharCodes(data ?? Uint8List.fromList([0])));
  return Chat.fromMap(map);
}
