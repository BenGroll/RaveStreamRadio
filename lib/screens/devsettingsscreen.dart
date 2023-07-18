// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:beamer/beamer.dart';
import 'package:ravestreamradioapp/extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/commonwidgets.dart';
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/databaseclasses.dart';
import 'package:ravestreamradioapp/filesystem.dart';
import 'package:ravestreamradioapp/messaging.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/payments.dart' as pay;
import 'package:ravestreamradioapp/chatting.dart';
import 'package:ravestreamradioapp/testdbscenario.dart';
import 'package:ravestreamradioapp/realtimedb.dart' as rtdb;
import 'package:firebase_database/firebase_database.dart';

/// Screen for developer level Actions and Informations
class DevSettingsScreen extends StatelessWidget {
  const DevSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool sees_devsettings =
        db.doIHavePermission(GlobalPermission.CHANGE_DEV_SETTINGS);
    return sees_devsettings
        ? Scaffold(
            backgroundColor: cl.darkerGrey,
            appBar: AppBar(
              title: Text("Dev. Settings"),
              centerTitle: true,
            ),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: [
                  ValueListenableBuilder(
                      valueListenable: selectedbranch,
                      builder: (context, BranchVal, foo) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Branch: ",
                                style: TextStyle(color: Colors.white)),
                            DropdownButton(
                                dropdownColor: cl.darkerGrey,
                                value: BranchVal,
                                items: ServerBranches.values
                                    .map((ServerBranches branch) {
                                  return DropdownMenuItem(
                                      value: branch,
                                      child: Text(
                                        branch.toString(),
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ));
                                }).toList(),
                                onChanged: (ServerBranches? newbranch) {
                                  if (newbranch != null) {
                                    selectedbranch.value = newbranch;
                                  }
                                })
                          ],
                        );
                      }),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                            child: Text("Length of Event lists:",
                                style: TextStyle(color: Colors.white))),
                        Expanded(
                            child: TextFormField(
                          keyboardType: TextInputType.number,
                          initialValue: ITEMS_PER_PAGE_IN_EVENTSHOW.toString(),
                          style: TextStyle(color: Colors.white),
                          onSaved: (newValue) {
                            ITEMS_PER_PAGE_IN_EVENTSHOW = int.parse(newValue ??
                                ITEMS_PER_PAGE_IN_EVENTSHOW.toString());
                          },
                          onFieldSubmitted: (newValue) {
                            ITEMS_PER_PAGE_IN_EVENTSHOW = int.parse(newValue);
                          },
                        ))
                      ]),
                  ElevatedButton(
                    onPressed: (() async {
                      Beamer.of(context).beamToNamed("/download");
                      ScaffoldMessenger.of(context)
                          .showSnackBar(hintSnackBar("Opened DownloadLink"));
                    }),
                    child: ValueListenableBuilder(
                        valueListenable: selectedbranch,
                        builder: (context, branch, foo) {
                          return Text("Open DownloadLink");
                        }),
                  ),
                  ElevatedButton(
                    onPressed: (() async {
                      await db.setTestDBScenario();
                      ScaffoldMessenger.of(context)
                          .showSnackBar(hintSnackBar("Added testevents"));
                    }),
                    child: ValueListenableBuilder(
                        valueListenable: selectedbranch,
                        builder: (context, branch, foo) {
                          return Text("Add test events to $branch");
                        }),
                  ),
                  ElevatedButton(
                    onPressed: (() async {
                      //! Continue here
                      ScaffoldMessenger.of(context)
                          .showSnackBar(hintSnackBar("Removed Events"));
                    }),
                    child: ValueListenableBuilder(
                        valueListenable: selectedbranch,
                        builder: (context, branch, foo) {
                          return Text("Remove all events from $branch");
                        }),
                  ),
                  ElevatedButton(
                    onPressed: (() async {
                      String toCopy = "";
                      String toCopyTo = "";
                      bool continuE = false;
                      await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: Colors.black,
                              title: Text("Enter Collection Names",
                                  style: TextStyle(color: Colors.white)),
                              content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextFormField(
                                      autofocus: true,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                          enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.black)),
                                          focusColor: Colors.white,
                                          hintText: "Input Collection Path",
                                          hintStyle:
                                              TextStyle(color: Colors.white)),
                                      cursorColor: Colors.white,
                                      onChanged: (value) {
                                        toCopy = value;
                                      },
                                      maxLines: null,
                                    ),
                                    TextFormField(
                                      autofocus: true,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                          enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.black)),
                                          focusColor: Colors.white,
                                          hintText: "Output Collection Path",
                                          hintStyle:
                                              TextStyle(color: Colors.white)),
                                      cursorColor: Colors.white,
                                      onChanged: (value) {
                                        toCopyTo = value;
                                      },
                                      maxLines: null,
                                    ),
                                  ]),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      continuE = true;
                                      return;
                                    },
                                    child: Text("Enter",
                                        style: TextStyle(color: Colors.white))),
                                TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      return;
                                    },
                                    child: Text("Cancel",
                                        style: TextStyle(color: Colors.white))),
                              ],
                            );
                          });
                      if (!continuE) return;
                      await db.createCopyOfCollection(
                          toCopy, toCopyTo, context);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(hintSnackBar("Collection Copied"));
                    }),
                    child: ValueListenableBuilder(
                        valueListenable: selectedbranch,
                        builder: (context, branch, foo) {
                          return Text("Copy a collection");
                        }),
                  ),
                  ElevatedButton(
                      onPressed: () async {
                        List<Event> events = await db.getEvents();
                        String jsonindexString = eventMapToJson(
                            eventListToJsonCompatibleMap(events));
                        db.writeEventIndexes(jsonindexString);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Created Indexes"));
                      },
                      child: Text("Write index file for Events")),
                  ElevatedButton(
                      onPressed: () async {
                        List<Event> events = db.getEventListFromIndexes(
                            await db.readEventIndexesJson());
                        showFeedbackDialog(
                            context, events.map((e) => e.toString()).toList());
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Read Indexes"));
                      },
                      child: Text("Read index file for Events")),
                  ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (BuildContext context) =>
                                pay.paypalInterface));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Payment"));
                      },
                      child: Text("Test Paypal Payment")),
                  ElevatedButton(
                      onPressed: () async {
                        await db.getDemoHosts();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Got Hosts"));
                      },
                      child: Text("Get Hosts")),
                  ElevatedButton(
                      onPressed: () async {
                        await db.writeIDStoDemoHosts();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Set Hosts"));
                      },
                      child: Text("Include IDs in HostDocs")),
                  /*ElevatedButton(
                      onPressed: () async {
                        await uploadChatToDB(Chat.fromMap(testchat));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Json Write Test"));
                      },
                      child: Text("write Chat to json test")),
                  ElevatedButton(
                      onPressed: () async {
                        pprint(await readChatFromDB(testchat["id"])
                            .then((value) => value.toMap()));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Json Read Test"));
                      },
                      child: Text("read Chat from json test")),
                  ElevatedButton(
                      onPressed: () async {
                        Chat chat = Chat.fromMap(testchat);
                        pprint(chat.members);
                        rtdb.setChatData(chat);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("RealtimeDB Test"));
                      },
                      child: Text("RealtimeDB Test")),
                  ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (BuildContext context) =>
                                ChatWindow(id: "TZTrs5BngHYohRGsm4w2")));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Chat Test"));
                      },
                      child: Text("Chat Test")),
                  */
                  ElevatedButton(
                      onPressed: () async {
                        showDevFeedbackDialog(context, [generateDocumentID()]);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Chat Test"));
                      },
                      child: Text("Generate 20-length Document ID")),
                  /*
                  ElevatedButton(
                      onPressed: () async {
                        Message testmessage = Message(
                            sender: "dev.users/admin",
                            sentAt: Timestamp.now(),
                            content: "Sup");
                        Message testmessage2 = Message(
                            sender: "dev.users/addmin",
                            sentAt: Timestamp.now(),
                            content: "wie gehts");

                        //await rtdb.addMessage(testmessage);
                        //await rtdb.addMessage(testmessage2);
                        //await rtdb.rtdb.ref("root/Chats/${"TZTrs5BngHYohRGsm4w2"}/messages").set(["adiugh", "adoiuhd"]);
                        await rtdb.addMessageToChat(
                            testmessage,
                            Chat(id: "TZTrs5BngHYohRGsm4w2", members: [
                              db.db.doc("dev.users/admin"),
                              db.db.doc("dev.users/addmin")
                            ]));

                        ScaffoldMessenger.of(context).showSnackBar(
                            hintSnackBar("Add Test Messages to RTDB"));
                      },
                      child: Text("Add Test Messages to RTDB")),
                  ElevatedButton(
                      onPressed: () async {
                        List<String> ids = [
                          "4ye88RdGM6m9jB8DvqLq",
                          "6buQOrfAFE0x8QQfvQE1",
                          "RyytWkjzyZJAEmcEjL2s"
                        ];
                        List<Message> messages =
                            await loadMessagesForChat("TZTrs5BngHYohRGsm4w2");
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Messages Loaded"));
                      },
                      child: Text("Test load Messages from IDList")),*/
                  ElevatedButton(
                      onPressed: () async {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Messages Loaded"));
                      },
                      child: Text("Log Timestamp Test")),
                  ElevatedButton(
                      onPressed: () async {
                        await db.addLogEntry("'changedAttribute': 1 -> 2",
                            category: db.LogEntryCategory.unknown,
                            action: db.LogEntryAction.unknown);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Messages Loaded"));
                      },
                      child: Text("Log Adding Test")),
                  ElevatedButton(
                      onPressed: () async {
                        db.createUserIndexFiles();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Users Indexed"));
                      },
                      child: Text("Create User Index")),
                  ElevatedButton(
                      onPressed: () async {
                        db.createGroupIndexFiles();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Groups Loaded"));
                      },
                      child: Text("Create Group Index")),
                  ElevatedButton(
                      onPressed: () async {
                        db.createEventIndexFiles();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Events Indexed"));
                      },
                      child: Text("Create Event Index")),
                  ElevatedButton(
                      onPressed: () async {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Events Loaded"));
                      },
                      child: Text("Read Indexed Entitys")),
                  ElevatedButton(
                      onPressed: () async {
                        await db.addEventToIndexFile(demoEvent);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Events read"));
                      },
                      child: Text("Read Eventindex")),
                  ElevatedButton(
                      onPressed: () async {
                        QuerySnapshot snap = await db.db
                            .collection("${branchPrefix}events")
                            .get();
                        List<QueryDocumentSnapshot> docs = snap.docs;
                        List<Map> events =
                            docs.map((e) => e.data() as Map).toList();
                        List<Future> futures = events
                            .map((e) => db.db
                                    .doc(
                                        "${branchPrefix}events/${e["eventid"]}")
                                    .update({
                                  "flyer": e["flyer"].runtimeType == String
                                      ? e["flyer"]
                                          .replaceAll("1000x1000", "2000x2000")
                                      : null
                                }))
                            .toList();
                        await Future.wait(futures);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Events read"));
                      },
                      child: Text("Rewrite Event Flyer links")),
                  ElevatedButton(
                      onPressed: () async {
                        String lmao = await db.readEventIndexesJson();
                        await writeIndexFile(
                            "dev.eventsIndex.json", json.decode(lmao));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("File Written"));
                      },
                      child: Text("Test Index-File-Writing")),
                  ElevatedButton(
                      onPressed: () async {
                        print(await getSavedIndexFile("dev.eventsIndex.json"));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("File Read."));
                      },
                      child: Text("Test Index-File-Reading")),
                  ElevatedButton(
                      onPressed: () async {
                        print(await getSavedIndexFileLastChanged(
                            "dev.eventsIndex.json"));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("File Read"));
                      },
                      child: Text("Test Index-File-LastModified")),
                  ElevatedButton(
                      onPressed: () async {
                        print(await db
                            .getIndexFileContent("${branchPrefix}users.json"));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("File Read"));
                      },
                      child: Text("Get Groups Index File")),
                  ElevatedButton(
                      onPressed: () async {
                        await writeLoginDataWeb("admin", "admin");
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("File Read"));
                      },
                      child: Text("Test writing userdata")),
                  ElevatedButton(
                      onPressed: () async {
                        Map asd = kIsWeb
                            ? await readLoginDataWeb()
                            : await readLoginDataMobile();
                        showDevFeedbackDialog(context, [asd.toString()]);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("File Read"));
                      },
                      child: Text("Test reading userdata")),
                  ElevatedButton(
                      onPressed: () async {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("File Read"));
                      },
                      child: Text("Test ListGen")),
                  ElevatedButton(
                      onPressed: () async {
                        showDevFeedbackDialog(context, ["Hello"]);
                      },
                      child: Text("Test HintDialog")),
                  ElevatedButton(
                      onPressed: () async {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("File Read"));
                      },
                      child: Text("Test ListGen")),
                  ElevatedButton(
                      onPressed: () async {
                        Host? host = await db.getDemoHost("0815events");
                        showDevFeedbackDialog(context, [host.toString()]);
                      },
                      child: Text("Test Single DemoHost getter")),
                  ElevatedButton(
                      onPressed: () async {
                        showDevFeedbackDialog(context, ["DemoHosts Updated."]);
                      },
                      child: Text(
                          "Change all instagram links to instagram (demohosts)")),
                  ElevatedButton(
                      onPressed: () async {
                        await writeChatOutline(ChatOutline(
                            chatID: "PwZPV10ktzkzABtfhG4A",
                            members_LastOpened: {
                              "ben": Timestamp.now().millisecondsSinceEpoch,
                              "ben2": Timestamp.now().millisecondsSinceEpoch,
                            }));
                      },
                      child: Text("write Test Chat")),
                  ElevatedButton(
                      onPressed: () async {
                        ChatOutline? outL =
                            await readChatOutline("PwZPV10ktzkzABtfhG4B");
                        showDevFeedbackDialog(context, [outL.toString()]);
                      },
                      child: Text("Read Test Chat")),
                  ElevatedButton(
                      onPressed: () async {
                        List<ChatOutline>? chats =
                            await getChatOutlinesForUserObject(
                                currently_loggedin_as.value ?? demoUser);
                        showDevFeedbackDialog(
                            context,
                            chats == null
                                ? ["Null"]
                                : chats.map((e) => e.toString()).toList());
                      },
                      child: Text("Get My Chats")),
                  ElevatedButton(
                      onPressed: () async {
                        await writeLastMessage(
                            "PwZPV10ktzkzABtfhG4A",
                            Message(
                                id: generateDocumentID(),
                                sentFrom: "dev.users/ben",
                                content: "Hallo",
                                timestampinMilliseconds:
                                    Timestamp.now().millisecondsSinceEpoch));
                      },
                      child: Text("Write Testmessage")),
                  ElevatedButton(
                      onPressed: () async {
                        print(await firebasestorage
                            .ref("chats/PwZPV10ktzkzABtfhG4A/")
                            .listAll()
                            .then((value) => value.items));
                      },
                      child: Text("Test Storage directory listing")),
                  /*ElevatedButton(
                      onPressed: () async {
                        await firebasestorage
                            .ref("chats/PwZPV10ktzkzABtfhG4A/3.json")
                            .putString(jsonEncode({
                              "0": Message(
                                      content: "Äins",
                                      sentFrom: "dev.users/ben",
                                      timestampinMilliseconds: Timestamp.now()
                                          .millisecondsSinceEpoch)
                                  .toMap(),
                              "1": Message(
                                      content: "Zwei",
                                      sentFrom: "dev.users/ben",
                                      timestampinMilliseconds: Timestamp.now()
                                          .millisecondsSinceEpoch)
                                  .toMap(),
                              "2": Message(
                                      content: "Drei",
                                      sentFrom: "dev.users/ben",
                                      timestampinMilliseconds: Timestamp.now()
                                          .millisecondsSinceEpoch)
                                  .toMap(),
                            }));
                      },
                      child: Text("Add Test Messages")),*/
                  ElevatedButton(
                      onPressed: () async {
                        await addMessageToChat(
                            "PwZPV10ktzkzABtfhG4A",
                            Message(
                                sentFrom: "ben",
                                content: "Test2",
                                timestampinMilliseconds:
                                    Timestamp.now().millisecondsSinceEpoch,
                                id: generateDocumentID()));
                      },
                      child: Text("Add Test Message")),
                  ElevatedButton(
                      onPressed: () async {
                        print(await getMessagesForChat("PwZPV10ktzkzABtfhG4A"));
                      },
                      child: Text("Test Chat log reading")),
                  ElevatedButton(
                      onPressed: () async {
                        String test = "ÄÖÜäöüß";
                        print("Test: $test");
                        print("Safe: ${test.dbsafe}");
                        print("FromSafe: ${test.fromDBSafeString}");
                      },
                      child: Text("Test Chat log reading")),
                  ElevatedButton(
                      onPressed: () async {
                        ValueNotifier<String> groupID = ValueNotifier("");
                        await showDialog(
                            context: context,
                            builder: (context) =>
                                SimpleStringEditDialog(to_notify: groupID));
                        bool doesHaveFile = await db
                            .doesGroupAlreadyHaveFeedFile(groupID.value);
                        showDevFeedbackDialog(context, [
                          "Feed File exists for ${groupID.value}: ",
                          doesHaveFile.toString()
                        ]);
                      },
                      child: Text("Test Group Feed File Existance")),
                  ElevatedButton(
                      onPressed: () async {
                        ValueNotifier<String> groupID = ValueNotifier("");
                        await showDialog(
                            context: context,
                            builder: (context) =>
                                SimpleStringEditDialog(to_notify: groupID));
                        await db.createEmptyFeedFileForGroup(groupID.value);
                        showFeedbackDialog(context, ["Empty File created"]);
                      },
                      child: Text("Create empty file for feed")),
                  ElevatedButton(
                      onPressed: () async {
                        ValueNotifier<String> groupID = ValueNotifier("");
                        await showDialog(
                            context: context,
                            builder: (context) =>
                                SimpleStringEditDialog(to_notify: groupID));
                        Map? test =
                            await db.readGroupFeedListMap(groupID.value);
                        print(db.feedEntryMapToList(test ?? {}));
                      },
                      child: Text("Read Feed file for group")),
                  ElevatedButton(
                      onPressed: () async {
                        ValueNotifier<String> groupID = ValueNotifier("");
                        await showDialog(
                            context: context,
                            builder: (context) =>
                                SimpleStringEditDialog(to_notify: groupID));
                        await db.addFeedEntryToGroupFeed(
                            groupID.value,
                            FeedEntry(
                                ownerpath: "dev.groups/rsr",
                                timestamp: Timestamp.now(),
                                leading_image_path_download_link: null,
                                type: FeedEntryType.ANNOUNCEMENT));
                      },
                      child: Text("Add Feed Entry to Group")),
                  ElevatedButton(
                      onPressed: () async {
                        String test = "ÄÖÜäöüß";
                        showDevFeedbackDialog(context,
                            [test.dbsafe, test.dbsafe.fromDBSafeString]);
                      },
                      child: Text("Test String manipulation")),
                  ElevatedButton(
                      onPressed: () async {
                        ValueNotifier<String> token = ValueNotifier("");
                        await showDialog(
                            context: context,
                            builder: (context) =>
                                SimpleStringEditDialog(to_notify: token));
                        dynamic data = await sendFCMMessageToTokens(
                            [token.value], "HELLO", "TestContent");
                        showDevFeedbackDialog(context, [data.toString()]);
                      },
                      child: Text("Test Cloud Function Calling")),
                  ElevatedButton(
                      onPressed: () async {
                        showDevFeedbackDialog(
                            context, [fcmToken ?? "No Token assigned."]);
                      },
                      child: Text("Read FCMToken")),
                  ElevatedButton(
                      onPressed: () async {
                        await MessagingAPI()
                            .firebaseMessaging
                            .subscribeToTopic("TestTopic");
                        showDevFeedbackDialog(
                            context, [fcmToken ?? "No Token assigned."]);
                      },
                      child: Text("Create Topic")),
                  ElevatedButton(
                      onPressed: () async {
                        ValueNotifier<String> uname = ValueNotifier("");
                        ValueNotifier<String> title = ValueNotifier("");
                        ValueNotifier<String> content = ValueNotifier("");
                        await showDialog(
                            context: context,
                            builder: (context) =>
                                SimpleStringEditDialog(to_notify: uname));
                        await showDialog(
                            context: context,
                            builder: (context) =>
                                SimpleStringEditDialog(to_notify: title));
                        await showDialog(
                            context: context,
                            builder: (context) =>
                                SimpleStringEditDialog(to_notify: content));
                        await sendMessageToUsername(
                            uname.value, title.value, content.value);
                        showDevFeedbackDialog(
                            context, [fcmToken ?? "No Token assigned."]);
                      },
                      child: Text("Send Message to User")),
                  ElevatedButton(
                      onPressed: () async {
                        await db.writeRoleTopicFiles();
                        showDevFeedbackDialog(context, ["File Set"]);
                      },
                      child: Text("Write Roles for all Users")),
                  ElevatedButton(
                      onPressed: () async {
                        await db.addPermissionToUser(
                            GlobalPermission.ADMIN, "appletestuser");
                        showDevFeedbackDialog(context, ["Permit Added"]);
                      },
                      child: Text("Add Permission to User")),
                  ElevatedButton(
                      onPressed: () async {
                        await db.removePermissionFromUser(
                            GlobalPermission.ADMIN, "appletestuser");
                        showDevFeedbackDialog(context, ["Permit Removed"]);
                      },
                      child: Text("Remove Permission from User")),
                  ElevatedButton(
                      onPressed: () async {
                        await sendMessageToTopic(
                            "role_ADMIN",
                            "Message Only For Admins",
                            "If you see this, you shouldnt. Just for Testing");
                        showDevFeedbackDialog(context, ["Admins messaged"]);
                      },
                      child: Text("Admin Messaging")),
                ],
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: Text("Missing Permission"),
            ),
            backgroundColor: cl.darkerGrey,
            body: Center(
                child: Text(
              "You dont have permission to edit developer settings.",
              style: TextStyle(color: Colors.white),
            )),
          );
  }
}
