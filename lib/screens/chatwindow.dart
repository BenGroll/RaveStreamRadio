import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/realtimedb.dart' as rtdb;
import 'package:ravestreamradioapp/chatting.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:firebase_database/firebase_database.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/extensions.dart';
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;

/// Borrowed from https://stackoverflow.com/users/6618622/copsonroad
final ScrollController _controller = ScrollController();
void _scrollDown() {
  _controller.animateTo(
    _controller.position.maxScrollExtent,
    duration: Duration(milliseconds: 500),
    curve: Curves.fastOutSlowIn,
  );
}

class MessageCard extends StatelessWidget {
  Message message;
  bool sentItMyself;
  bool isGroupChat;
  MessageCard(
      {super.key,
      required this.message,
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
  MessageElement({super.key, required this.message, required this.isGroupChat});

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
              MessageCard(
                  message: message,
                  sentItMyself: sentItMyself,
                  isGroupChat: isGroupChat),
              Expanded(child: SizedBox(), flex: 1)
            ],
    );
  }
}

class ChatWindow extends StatelessWidget {
  final String id;
  String currentlyCuedupMessage = "";
  ValueNotifier<bool> rebuildToggle = ValueNotifier<bool>(true);
  ChatWindow({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    pprint("ChatWindow Opened");
    return FutureBuilder(
        future: rtdb.getChat_rtdb(id),
        builder: (BuildContext context, AsyncSnapshot snap) {
          if (snap.connectionState == ConnectionState.done) {
            if (snap.data == null) {
              return Scaffold(
                body: Text("Chat not found."),
              );
            } else {
              return StreamBuilder(
                  stream: rtdb.listenToChat(id),
                  builder: (BuildContext context, AsyncSnapshot snap) {
                    if (snap.connectionState == ConnectionState.done) {
                      Chat chat = Chat.fromDBSnapshot(snap.data);
                      if (chat.messages == null) chat.messages = [];
                      List<MessageElement> messagecards = chat.messages!
                          .map((e) => MessageElement(
                              message: e, isGroupChat: chat.members.length > 2))
                          .toList();
                      return Scaffold(
                        backgroundColor: cl.darkerGrey,
                        appBar: AppBar(
                          title: Text(chat.members.length > 2
                              ? chat.id
                              : chat.members[0].id),
                          backgroundColor: cl.darkerGrey,
                        ),
                        body: ListView.separated(
                          controller: _controller,
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          separatorBuilder: (BuildContext context, int index) {
                            return SizedBox(
                                height:
                                    MediaQuery.of(context).size.height / 50);
                          },
                          itemCount: messagecards.length,
                          itemBuilder: (context, index) {
                            return messagecards[index];
                          },
                        ),
                        bottomNavigationBar: Padding(
                            padding: MediaQuery.of(context).viewInsets,
                            child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: BottomAppBar(
                                  color: Colors.transparent,
                                  child: Card(
                                    color: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                          color: cl.greynothighlight),
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.height /
                                              50),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Padding(
                                            padding: EdgeInsets.fromLTRB(
                                                10, 0, 0, 0),
                                            child: ValueListenableBuilder(
                                                valueListenable: rebuildToggle,
                                                builder:
                                                    (context, snapshot, foo) {
                                                  return TextFormField(
                                                    onTap: () => _scrollDown(),
                                                    initialValue: "",
                                                    onChanged: (value) {
                                                      currentlyCuedupMessage =
                                                          value;
                                                    },
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          "Send Message...",
                                                      hintStyle: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  );
                                                }),
                                          ),
                                        ),
                                        Expanded(
                                            child: IconButton(
                                                onPressed: () async {
                                                  currently_loggedin_as
                                                      .value!.path;
                                                  Timestamp sentAt =
                                                      Timestamp.now();
                                                  Message newMessage = Message(
                                                      sender:
                                                          currently_loggedin_as
                                                              .value!.path,
                                                      sentAt: Timestamp.now(),
                                                      content:
                                                          currentlyCuedupMessage);
                                                  rebuildToggle.value =
                                                      !rebuildToggle.value;
                                                  await rtdb.addMessageToChat(
                                                      newMessage, chat);
                                                  _scrollDown();
                                                },
                                                icon: Icon(Icons.send,
                                                    color: Colors.white)))
                                      ],
                                    ),
                                  ),
                                ))),
                      );
                    } else {
                      return const cw.LoadingIndicator(
                        color: Colors.white,
                      );
                    }
                  });
            }
          } else {
            return const cw.LoadingIndicator(
              color: Colors.white,
            );
          }
        });
  }
}
