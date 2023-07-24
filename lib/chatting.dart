// ignore_for_file: prefer_interpolation_to_compose_strings, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import "dart:convert";
import "package:beamer/beamer.dart";
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/extensions.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import "package:ravestreamradioapp/conv.dart";
import "package:ravestreamradioapp/database.dart";
import "package:ravestreamradioapp/filesystem.dart";
import 'dart:convert';
import 'dart:typed_data';
import 'package:ravestreamradioapp/extensions.dart' show Stringify, Prettify;
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/messaging.dart';
import "package:ravestreamradioapp/realtimedb.dart";
import "package:ravestreamradioapp/shared_state.dart";
import 'package:ravestreamradioapp/extensions.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;
import 'package:firebase_database/firebase_database.dart';

class ChatsDrawer extends StatelessWidget {
  const ChatsDrawer({super.key});

  List<Widget> buildChatOutlineListTiles(
      List<ChatOutline>? chatoutlines, BuildContext context) {
    List<Widget> outL = [];
    if (chatoutlines == null || chatoutlines.isEmpty) {
      outL.add(Text("You don't have any chats at this moment",
          style: TextStyle(color: Colors.white)));
      return outL;
    }

    chatoutlines.forEach((ChatOutline outLine) {
      String sub = "";
      if (outLine.lastmessage == null) {
        sub = "This chat is empty...";
      } else {
        sub = "@" + outLine.lastmessage!.sentFrom;
        sub = sub + ": " + outLine.lastmessage!.content;
      }
      outL.add(ListTile(
        onTap: () {
          if (DISABLE_CHATWINDOW) {
            ScaffoldMessenger.of(context).showSnackBar(
                cw.hintSnackBar("Chatting is disabled right now"));
          } else {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ChatWindow(id: outLine.chatID)));
          }
        },
        tileColor: cl.darkerGrey,
        title: Text(outLine.title ?? outLine.chatID,
            maxLines: 1,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
                child: Text(sub, style: TextStyle(color: Colors.white))),
            outLine.lastmessage == null
                ? SizedBox()
                : Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                        timestamp2readablestamp(
                            Timestamp.fromMillisecondsSinceEpoch(
                                outLine.lastmessage!.timestampinMilliseconds)),
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w300)),
                  )
          ],
        ),
      ));
    });
    return outL;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: cl.darkerGrey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            tileColor: cl.lighterGrey,
            title: Center(
                child: Text("Your Chats",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: DISPLAY_SHORT_SIDE(context) / 20))),
          ),
          Expanded(
            child: FutureBuilder(
                future: getChatOutlines(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return cw.LoadingIndicator(color: Colors.white);
                  } else {
                    if (snapshot.hasData) {
                      return ListView(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        children:
                            buildChatOutlineListTiles(snapshot.data, context),
                      );
                    } else {
                      return Center(
                          child: Text("Couldn't load chats.",
                              style: TextStyle(color: Colors.white)));
                    }
                  }
                }),
          ),
        ],
      ),
    );
  }
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
              ? Container(
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                  ),
                )
              : Text(
                  "@${message.sentFrom}",
                  style: TextStyle(color: Colors.white),
                ),
          ListTile(
            tileColor: cl.lighterGrey,
            title: Text(message.content,
                maxLines: null, style: TextStyle(color: Colors.white)),
            subtitle: Align(
              alignment: Alignment.centerRight,
              child: Text(
                timestamp2readablestamp(Timestamp.fromMillisecondsSinceEpoch(
                    message.timestampinMilliseconds)),
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
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
        message.sentFrom == currently_loggedin_as.value!.username;
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
  final ScrollController _controller = ScrollController();
  bool has_shown_info_banner = false;
  void _scrollDown() {
    _controller.animateTo(
      _controller.position.maxScrollExtent,
      duration: Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
  }

  String id;
  ValueNotifier<String> currentlyCuedupMessage = ValueNotifier("");

  ChatWindow({required this.id});

  void _showMessagePolicyBanner(context, ChatOutline outline) {
    if (has_shown_info_banner) return;
    has_shown_info_banner = true;
    if (outline.keepmessages) return;
    ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
        backgroundColor: cl.darkerGrey,
        content: Align(
          alignment: Alignment.topCenter,
          child: Text(
            "Messages in this app get deleted by default after both parties have seen them. To change this, edit the chat's settings in the top right corner.",
            style: TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).clearMaterialBanners();
              },
              child: Text(
                "Dismiss",
                style: TextStyle(color: Colors.white),
              )),
          TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                      backgroundColor: cl.darkerGrey,
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                  "We here at RaveStreamRadio care about your Privacy.\nThis (And server-storage being expensive) made us decide to not keep private-info.\nBy default, in any private chats (no matter 1o1 or Group-Chat), all messages are deleted permanentely from our database as soon as all members of the chat have seen the message.\nThere is no way to restore or trace any deleted messages, not for you, not for the admin, not for the people whose server your data gets stored on.\nIf you want to keep messages from being deleted, you can manually change the settings for each Chat.",
                                  style: TextStyle(color: Colors.white)),
                            )
                          ])),
                );
              },
              child: Text(
                "Learn More",
                style: TextStyle(color: Colors.white),
              ))
        ]));
  }

  @override
  Widget build(BuildContext context) {
    ValueNotifier<bool> chatRebuildTrigger = ValueNotifier<bool>(false);
    TextEditingController _textcontroller = TextEditingController();
    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessenger.of(context).clearMaterialBanners();
        return true;
      },
      child: FutureBuilder(
          future: readChatOutline(id),
          builder: (context, snapshot) {
            ValueNotifier<List<Message>> buffer = ValueNotifier([]);
            if (snapshot.connectionState == ConnectionState.done) {
              ChatOutline? outline = snapshot.data;
              if (outline == null)
                return Center(child: Text("Couldn't load Chat"));
              return Scaffold(
                backgroundColor: cl.darkerGrey,
                appBar: AppBar(
                  actions: [
                    IconButton(
                        onPressed: () {
                          ValueNotifier<bool> keepmessages =
                              ValueNotifier(outline.keepmessages);
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    backgroundColor: cl.darkerGrey,
                                    title: Text("Settings",
                                        style: TextStyle(color: Colors.white)),
                                    content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                              "By default, messages get deleted permanentely after every member has seen them. If you want messages to be saved until you decide to delete them, turn the setting below on.\nThis setting is individual for every chat and has to be set manually.",
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          Row(children: [
                                            Text("Keep Messages: ",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                            ValueListenableBuilder(
                                                valueListenable: keepmessages,
                                                builder:
                                                    (context, snapshot, foo) {
                                                  return Switch(
                                                      activeColor: Colors.white,
                                                      activeTrackColor:
                                                          Colors.white,
                                                      inactiveTrackColor:
                                                          cl.lighterGrey,
                                                      inactiveThumbColor:
                                                          cl.lighterGrey,
                                                      value: snapshot,
                                                      onChanged: (value) =>
                                                          keepmessages.value =
                                                              value);
                                                })
                                          ])
                                        ]),
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text("Dismiss",
                                              style: TextStyle(
                                                  color: Colors.white))),
                                      TextButton(
                                          onPressed: () async {
                                            if (outline.keepmessages !=
                                                keepmessages.value) {
                                              cw.showLoadingDialog(context);
                                              outline.keepmessages =
                                                  keepmessages.value;
                                              await writeChatOutline(outline);
                                              Navigator.of(context).pop();
                                              if (keepmessages.value) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(cw.hintSnackBar(
                                                        "From now on messages will be saved in chats."));
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(cw.hintSnackBar(
                                                        "From now on messages will be deleted once both parties have seen them."));
                                              }
                                            }

                                            Navigator.of(context).pop();
                                          },
                                          child: Text("Save Settings",
                                              style: TextStyle(
                                                  color: Colors.white)))
                                    ],
                                  ));
                        },
                        icon: Icon(Icons.settings, color: Colors.white))
                  ],
                  centerTitle: true,
                  title: SingleChildScrollView(
                      child: Text(outline.title ?? outline.chatID)),
                ),
                body: FutureBuilder(
                    future: getMessagesForChat(outline.chatID),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<Message>> snap) {
                      if (snap.connectionState == ConnectionState.done &&
                          snap.hasData) {
                        List<Message> messages = snap.data ?? [];
                        if (messages.length > buffer.value.length)
                          buffer.value = messages;
                        outline.members_LastOpened[currently_loggedin_as.value!
                            .username] = Timestamp.now().millisecondsSinceEpoch;
                        writeLastOpened(outline.chatID,
                            currently_loggedin_as.value!.username);
                        if (!outline.keepmessages) {
                          List<int> timestamps = outline
                              .members_LastOpened.entries
                              .map((e) => e.value)
                              .toList()
                            ..sort((a, b) => a.compareTo(b));
                          int earliest_timestamp = timestamps.first;
                          List<String> messagesReadByEveryoneByID = [];
                          messages.forEach((element) {
                            if (element.timestampinMilliseconds <=
                                earliest_timestamp) {
                              messagesReadByEveryoneByID.add(element.id);
                            }
                          });
                          deleteMessageList(
                              outline.chatID, messagesReadByEveryoneByID);
                          List<Message> messagesNotDeleted = [];
                          buffer.value.forEach((element) {
                            if (!messagesReadByEveryoneByID
                                .contains(element.id)) {
                              messagesNotDeleted.add(element);
                            }
                          });
                          if (messagesNotDeleted.length > 1) {
                            writeLastMessage(
                                outline.chatID, messagesNotDeleted.last);
                          } else {
                            writeLastMessage(outline.chatID, null);
                          }
                        }
                        return StreamBuilder(
                            stream: rtdb
                                .ref("root/MessageLogs/${outline.chatID}")
                                .onChildAdded,
                            builder: (BuildContext context,
                                AsyncSnapshot<DatabaseEvent> event) {
                              if (event.hasData &&
                                  event.data?.snapshot.value != null) {
                                Message messageEvent = Message.fromMap(
                                    messageMapFromDynamic(
                                        event.data?.snapshot.value));
                                if (buffer.value.isNotEmpty &&
                                    buffer.value.last.timestampinMilliseconds <
                                        messageEvent.timestampinMilliseconds) {
                                  buffer.value.add(messageEvent);
                                }
                                if (buffer.value.isEmpty) {
                                  buffer.value.add(messageEvent);
                                }
                              }
                              return ListView.separated(
                                  controller: _controller,
                                  itemBuilder: (context, index) {
                                    //_scrollDown();
                                    //! Return Card
                                    return MessageElement(
                                        message: buffer.value[index],
                                        isGroupChat:
                                            outline.members_LastOpened.length >
                                                2);
                                  },
                                  separatorBuilder:
                                      (BuildContext context, int index) {
                                    return SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height /
                                                50);
                                  },
                                  itemCount: messages.length);
                            });
                      } else {
                        return cw.LoadingIndicator(color: Colors.white);
                      }
                    }),
                bottomNavigationBar: Padding(
                    padding: MediaQuery.of(context).viewInsets,
                    child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: BottomAppBar(
                          color: Colors.transparent,
                          child: Card(
                            color: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: cl.greynothighlight),
                              borderRadius: BorderRadius.circular(
                                  MediaQuery.of(context).size.height / 50),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                      child: ValueListenableBuilder(
                                          valueListenable:
                                              currentlyCuedupMessage,
                                          builder: (context, snapshot, foo) {
                                            return TextFormField(
                                              controller: _textcontroller,
                                              onTap: () {
                                                _showMessagePolicyBanner(
                                                    context, outline);
                                                _scrollDown();
                                              },
                                              onChanged: (value) {
                                                currentlyCuedupMessage.value =
                                                    value;
                                              },
                                              style: TextStyle(
                                                  color: Colors.white),
                                              decoration: InputDecoration(
                                                filled: false,
                                                fillColor: Colors.transparent,
                                                hintText: "Send Message...",
                                                hintStyle: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            );
                                          })),
                                ),
                                Expanded(
                                    child: IconButton(
                                        onPressed: () async {
                                          if (DISABLE_MESSAGE_SENDING) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(cw.hintSnackBar(
                                                    "Chatting is disabled right now."));
                                            return;
                                          }
                                          if (currentlyCuedupMessage
                                              .value.isEmpty) return;
                                          currently_loggedin_as.value!.path;
                                          Timestamp sentAt = Timestamp.now();
                                          Message newMessage = Message(
                                              id: generateDocumentID(),
                                              sentFrom: currently_loggedin_as
                                                  .value!.username,
                                              timestampinMilliseconds:
                                                  Timestamp.now()
                                                      .millisecondsSinceEpoch,
                                              content:
                                                  currentlyCuedupMessage.value);
                                          await addMessageToChat(
                                              outline.chatID, newMessage);
                                          outline.members_LastOpened
                                              .forEach((user, lastOpened) {
                                            if (!(user ==
                                                currently_loggedin_as
                                                    .value?.username)) {
                                              sendMessageToUsername(
                                                  user,
                                                  "Chats",
                                                  "@${currently_loggedin_as.value?.username}: ${currentlyCuedupMessage.value}");
                                            }
                                          });
                                          writeLastMessage(
                                              outline.chatID, newMessage);
                                          currentlyCuedupMessage.value = "";
                                          _scrollDown();
                                          _textcontroller.text = "";
                                          /*chatRebuildTrigger.value =
                                              !chatRebuildTrigger.value;*/
                                          chatRebuildTrigger.notifyListeners();
                                        },
                                        icon: Icon(Icons.send,
                                            color: Colors.white)))
                              ],
                            ),
                          ),
                        ))),
              );
            } else {
              return cw.LoadingIndicator(color: Colors.white);
            }
          }),
    );
  }
}

class ChatOutline {
  String chatID;
  String? adminUserName;
  String? description;
  bool keepmessages = false;

  /// Key: username, Value: Timestamp of last opening the chat
  Map<String, int> members_LastOpened;
  String? title;

  Message? lastmessage;
  ChatOutline(
      {required this.chatID,
      this.adminUserName,
      this.description,
      required this.members_LastOpened,
      this.title,
      this.lastmessage,
      this.keepmessages = false});

  factory ChatOutline.fromMap(Map<String, dynamic> map) {
    Map<String, int> membersLastOpenedmapFromObject(Map input) {
      Map<String, int> outM = {};
      input.entries.forEach((element) {
        outM[element.key.toString()] = element.value as int;
      });
      return outM;
    }

    String title = "";
    if (membersLastOpenedmapFromObject(map["members_LastOpened"]).length == 2) {
      Map members = membersLastOpenedmapFromObject(map["members_LastOpened"]);
      if (members.entries.toList()[0].key ==
          currently_loggedin_as.value!.username) {
        title = "@${members.entries.toList()[1].key}";
      } else {
        title = "@${members.entries.toList()[0].key}";
      }
    } else {
      title = map["chatID"];
    }

    return ChatOutline(
        chatID: map["chatID"],
        adminUserName:
            map.containsKey("adminUserName") ? map["adminUserName"] : null,
        description: map.containsKey("description") ? map["description"] : null,
        members_LastOpened:
            membersLastOpenedmapFromObject(map["members_LastOpened"]),
        title: title,
        lastmessage: map["lastmessage"] != null
            ? Message.fromMap(messageMapFromDynamic(map["lastmessage"]))
            : null,
        keepmessages: map["keepmessages"]);
  }
  Map<String, dynamic> toMap() {
    return {
      "chatID": chatID,
      "adminUserName": adminUserName,
      "description": description,
      "members_LastOpened": members_LastOpened,
      "title": title,
      "lastmessage": lastmessage != null ? lastmessage!.toMap() : null,
      "keepmessages": keepmessages
    };
  }

  String toString() {
    return "ChatOutline(chatID: $chatID, adminUserName: $adminUserName, description: $description, members_LastOpened: $members_LastOpened, title: $title, lastmessage: $lastmessage, keepmessages: $keepmessages)";
  }
}

class Message {
  String sentFrom;
  String content;
  int timestampinMilliseconds;
  String id;
  Message(
      {required this.sentFrom,
      required this.content,
      required this.timestampinMilliseconds,
      required this.id});
  Map<String, dynamic> toMap() {
    return {
      "sentFrom": sentFrom,
      "content": content,
      "timestampinMilliseconds": timestampinMilliseconds,
      "id": id
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
        content: map["content"],
        sentFrom: map["sentFrom"],
        timestampinMilliseconds: map["timestampinMilliseconds"],
        id: map["id"]);
  }
  String toString() {
    return "Message(id: $id, content: $content, sentFrom: $sentFrom, timestampinMilliseconds: $timestampinMilliseconds)";
  }
}

Map<String, dynamic> chatOutlineMapFromDynamic(dynamic i) {
  Map<String, dynamic> map = {
    "chatID": i["chatID"],
    "members_LastOpened": i["members_LastOpened"],
    "lastmessage": i.containsKey("lastmessage") ? i["lastmessage"] : null,
    "keepmessages": i["keepmessages"]
  };
  return map;
}

Map<String, dynamic> messageMapFromDynamic(dynamic i) {
  return {
    "content": i["content"],
    "sentFrom": i["sentFrom"],
    "timestampinMilliseconds": i["timestampinMilliseconds"],
    "id": i["id"]
  };
}

Future writeChatOutline(ChatOutline chatOutline) async {
  DatabaseReference chats = rtdb.ref("root/ChatOutlines");
  await chats.child(chatOutline.chatID).set(chatOutline.toMap());
}

Future<ChatOutline?> readChatOutline(String chatOutlineID) async {
  DatabaseReference chat = rtdb.ref("root/ChatOutlines/${chatOutlineID}");
  DataSnapshot value = await chat.get();
  try {
    Map data = value.value as Map;
    print(data);
    Map<String, dynamic> dataMap = chatOutlineMapFromDynamic(data);
    ChatOutline outLine = ChatOutline.fromMap(dataMap);
    return outLine;
  } catch (e) {
    return null;
  }
}

Future writeLastMessage(String chatID, Message? message) async {
  DatabaseReference chat = rtdb.ref("root/ChatOutlines/$chatID");
  DataSnapshot chatdata = await chat.get();
  if (chatdata.value == null) return;
  Map data = chatdata.value as Map;
  if (message != null) {
    data["lastmessage"] = message.toMap();
  } else {
    data["lastmessage"] = null;
  }
  await chat.set(data);
  return;
}

Future writeLastOpened(String chatID, String username) async {
  DatabaseReference chat =
      rtdb.ref("root/ChatOutlines/$chatID/members_LastOpened");
  DataSnapshot chatdata = await chat.get();
  if (chatdata.value == null) return;
  Map data = chatdata.value as Map;
  data[username] = Timestamp.now().millisecondsSinceEpoch;
  await chat.set(data);
  return;
}

Future<List<ChatOutline>?> getChatOutlines() async {
  dbc.User? user = await getUser(currently_loggedin_as.value!.username);
  if (user == null) return null;
  List<String> chatIDS = user.chats;
  if (chatIDS.isEmpty) return [];
  List<Future> futures = [];
  chatIDS.forEach((element) {
    futures.add(rtdb.ref("root/ChatOutlines").child(element).get());
  });
  //Stopwatch watch = Stopwatch()..start();
  List<dynamic> datas = await Future.wait(futures);
  List<ChatOutline> chatOutlines = [];
  datas.forEach((element) {
    if (element.value != null) {
      chatOutlines
          .add(ChatOutline.fromMap(chatOutlineMapFromDynamic(element.value)));
    }
  });
  return chatOutlines;
}

Future<List<Message>> getMessagesForChat(String chatID) async {
  List<Message> messages = [];
  DatabaseReference chatMessageLog = rtdb.ref("root/MessageLogs/$chatID");
  DataSnapshot snap = await chatMessageLog.get();
  if (snap.value == null) return [];
  Map messagesData = snap.value as Map;
  messagesData.entries.forEach((element) {
    messages.add(Message.fromMap(messageMapFromDynamic(element.value)));
  });
  messages.sort(
      (a, b) => a.timestampinMilliseconds.compareTo(b.timestampinMilliseconds));
  return messages;
}

Future addMessageToChat(String chatID, Message message) async {
  DatabaseReference chats = rtdb.ref("root/MessageLogs/$chatID");
  DatabaseReference ref = chats.push();
  Map data = message.toMap();
  print(ref.path);
  data["id"] = ref.path.split("/").last;
  await ref.set(data);
  return;
}

Future deleteMessageList(String chatID, List<String> ids) async {
  DatabaseReference chats = rtdb.ref("root/MessageLogs/$chatID");
  List<Future> futures = [];
  ids.forEach((element) {
    futures.add(chats.child(element).remove());
  });
  Future.wait(futures);
  return;
}

Future<ChatOutline?> findPrivateChatByOtherUser(
    String otherUserUsername) async {
  List<ChatOutline>? outlines = await getChatOutlines();
  if (outlines == null) outlines = [];
  for (int i = 0; i < outlines.length; i++) {
    ChatOutline element = outlines[i];
    if (element.members_LastOpened.keys.length == 2 &&
        element.members_LastOpened.keys.contains(otherUserUsername)) {
      return element;
    }
  }
  return null;
}

Future startNewChat(String other_person_name) async {
  String newID = generateDocumentID();
  await writeChatOutline(ChatOutline(
      chatID: newID, members_LastOpened: {"ben": 0, other_person_name: 0}));
  await rtdb.ref("root/MessageLogs/$newID").set([]);
  await db.doc("${branchPrefix}users/$other_person_name").update({
    "chats": FieldValue.arrayUnion([newID]),
    "lastEditedInMs" : Timestamp.now().millisecondsSinceEpoch
  });
  await db.doc(currently_loggedin_as.value!.path).update({
    "chats": FieldValue.arrayUnion([newID]),
    "lastEditedInMs" : Timestamp.now().millisecondsSinceEpoch
  });
  return newID;
}

Future deleteAllChats() async {
  if (currently_loggedin_as.value == null) return;
  List<String> chatIDS = currently_loggedin_as.value!.chats;
  List<Future> futures = [];
  chatIDS.forEach((element) {
    futures.add(rtdb.ref("root/MessageLogs/").child(element).remove());
    futures.add(rtdb.ref("root/ChatOutlines/$element/lastmessage").set(null));
  });
  await Future.wait(futures);
  print("Deleted all Chats");
  return;
}
