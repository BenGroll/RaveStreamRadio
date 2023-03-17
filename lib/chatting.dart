import "dart:convert";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:ravestreamradioapp/conv.dart";

class Message {
  /// Contains full path to the Document
  final String sender;

  /// Contains full path to the Document
  final String? reciever;

  /// Leave empty if chat has more than two members
  final Timestamp sentAt;
  Message({required this.sender, this.reciever, required this.sentAt});
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
        sender: map["sender"],
        sentAt: map["sentAt"],
        reciever: map["reciever"]);
  }
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sender': sender,
      'reciever': reciever,
      'sentAt': sentAt
    };
  }
}

List<Message> chatFromDB(List map) {
  List<Message> buffer = [];
  map.forEach((element) {
    buffer.add(Message(sender: "dev.users/admin", sentAt: Timestamp.now()));
  });
  print(buffer);
  return buffer;
}

class Chat {
  List<Message> messages;
  List<DocumentReference> members;
  String? pathToLogo;
  Chat({this.messages = const [], required this.members, this.pathToLogo});
  factory Chat.fromMap(Map map) {
    print(map["members"]);
    return Chat(
        members: map["members"],
        messages: map["messages"].toList(),
        pathToLogo: map["pathToLogo"]);
  }
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'messages': messages.map((e) => e.toMap()),
      'members': members,
      "pathToLogo": pathToLogo
    };
  }
}

String encodeChatAsJson(Chat chat) {
  return jsonEncode(chat.toMap());
}
