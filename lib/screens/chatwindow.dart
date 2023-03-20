import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/realtimedb.dart' as rtdb;
import 'package:ravestreamradioapp/chatting.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:firebase_database/firebase_database.dart';
import 'package:ravestreamradioapp/shared_state.dart';

class MessageCard extends StatelessWidget {
  Message message;
  bool sentItMyself;
  bool isGroupChat;
  MessageCard(
      {required this.message,
      required this.sentItMyself,
      this.isGroupChat = false});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            sentItMyself ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          sentItMyself
              ? Container()
              : Text(
                  "@${message.sender.split('/')[1]}",
                  style: TextStyle(color: Colors.white),
                ),
          ListTile(
            tileColor: Colors.white,
            title: Text(
              message.content,
              maxLines: null,
            ),
            subtitle: Text(timestamp2readablestamp(message.sentAt)),
          ),
        ],
      ),
    );
  }
}

class MessageElement extends StatelessWidget {
  Message message;
  bool isGroupChat;
  MessageElement({required this.message, required this.isGroupChat});

  @override
  Widget build(BuildContext context) {
    bool sentItMyself =
        message.sender.split("/")[1] == currently_loggedin_as.value!.username;
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment:
          sentItMyself ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: sentItMyself
          ? [
              Expanded(child: SizedBox(), flex: 1),
              MessageCard(
                  message: message,
                  sentItMyself: sentItMyself,
                  isGroupChat: isGroupChat)
            ]
          : [
              MessageCard(message: message, sentItMyself: sentItMyself, isGroupChat: isGroupChat),
              Expanded(child: SizedBox(), flex: 1)
            ],
    );
  }
}

class ChatWindow extends StatelessWidget {
  final String id;
  const ChatWindow({required this.id});

  @override
  Widget build(BuildContext context) {
    print("ChatWindow Opened");
    return StreamBuilder(
        stream: rtdb.listenToChat(id),
        builder: (BuildContext context, AsyncSnapshot snap) {
          print(snap.connectionState);
          if (snap.connectionState == ConnectionState.active) {
            Chat chat = Chat.fromDBSnapshot(snap.data.snapshot.value);
            List<MessageElement> messagecards =
                chat.messages.map((e) => MessageElement(message: e, isGroupChat: chat.members.length > 2)).toList();
            return Scaffold(
              backgroundColor: cl.deep_black,
              appBar: AppBar(
                title: Text(chat.members.length > 2 ? chat.id : chat.members[0].id),
                backgroundColor: cl.deep_black,
              ),
              body: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 8),
                separatorBuilder: (BuildContext context, int index) {
                  return SizedBox(
                      height: MediaQuery.of(context).size.height / 50);
                },
                itemCount: messagecards.length,
                itemBuilder: (context, index) {
                  return messagecards[index];
                },
              ),
            );
          } else {
            return CircularProgressIndicator(
              color: Colors.white,
            );
          }
        });
  }
}
