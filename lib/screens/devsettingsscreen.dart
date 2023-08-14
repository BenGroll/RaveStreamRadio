// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:beamer/beamer.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
                                style: cl.df),
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
                                style: cl.df)),
                        Expanded(
                            child: TextFormField(
                          keyboardType: TextInputType.number,
                          initialValue: ITEMS_PER_PAGE_IN_EVENTSHOW.toString(),
                          style: cl.df,
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
                      showDevFeedbackDialog(
                          context, ["Should have opened /download."]);
                    }),
                    child: ValueListenableBuilder(
                        valueListenable: selectedbranch,
                        builder: (context, branch, foo) {
                          return Text("Open Download-LandingPage");
                        }),
                  ),
                  ElevatedButton(
                    onPressed: (() async {
                      await db.setTestDBScenario();
                      showDevFeedbackDialog(context, ["Added test events"]);
                    }),
                    child: ValueListenableBuilder(
                        valueListenable: selectedbranch,
                        builder: (context, branch, foo) {
                          return Text(
                              "Add test events to $branch (deprecated)");
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
                          return Text(
                              "Remove all events from $branch (Does Nothing)");
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
                                  style: cl.df),
                              content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextFormField(
                                      autofocus: true,
                                      style:
                                          cl.df,
                                      decoration: const InputDecoration(
                                          enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.black)),
                                          focusColor: Colors.white,
                                          hintText: "Input Collection Path",
                                          hintStyle:
                                              cl.df),
                                      cursorColor: Colors.white,
                                      onChanged: (value) {
                                        toCopy = value;
                                      },
                                      maxLines: null,
                                    ),
                                    TextFormField(
                                      autofocus: true,
                                      style:
                                          cl.df,
                                      decoration: const InputDecoration(
                                          enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.black)),
                                          focusColor: Colors.white,
                                          hintText: "Output Collection Path",
                                          hintStyle:
                                              cl.df),
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
                                        style: cl.df)),
                                TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      return;
                                    },
                                    child: Text("Cancel",
                                        style: cl.df)),
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
                      child: Text("Write index file for Events (All data)")),
                  ElevatedButton(
                      onPressed: () async {
                        List<Event> events = db.getEventListFromIndexes(
                            await db.readEventIndexesJson());
                        showDevFeedbackDialog(
                            context, events.map((e) => e.toString()).toList());
                        ScaffoldMessenger.of(context).showSnackBar(
                            hintSnackBar("Read Indexes (All data)"));
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
                      child: Text("Test Paypal Payment (WIP)")),
                  ElevatedButton(
                      onPressed: () async {
                        List<Host> hosts = await db.getDemoHosts();
                        showDevFeedbackDialog(
                            context, hosts.map((e) => e.toString()).toList());
                      },
                      child: Text(
                          "Get All Demohosts (From Firestore Collection)")),
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
                        await db.addLogEntry("'changedAttribute': 1 -> 2",
                            category: db.LogEntryCategory.unknown,
                            action: db.LogEntryAction.unknown);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Messages Loaded"));
                      },
                      child: Text("Add a test Entry to current logfile (NF)")),
                  ElevatedButton(
                      onPressed: () async {
                        await db.createUserIndexFiles();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Users Indexed"));
                      },
                      child: Text(
                          "Create User Indexfile ({Username: Alias}) (NF)")),
                  ElevatedButton(
                      onPressed: () async {
                        await db.createGroupIndexFiles();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Groups Loaded"));
                      },
                      child: Text(
                        "Create Group Index, ({groupid: title}) (NF)",
                      )),
                  ElevatedButton(
                      onPressed: () async {
                        db.createEventIndexFiles();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Events Indexed"));
                      },
                      child:
                          Text("Create Event Index ({eventid: title}) (NF)")),
                  ElevatedButton(
                      onPressed: () async {
                        List<Map> maps = await db.getIndexedEntitys();
                        showDevFeedbackDialog(
                            context, maps.map((e) => e.toString()).toList());
                      },
                      child: Text(
                          "Read All Indexed Entitys (Groups, Events, Users)")),
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
                        await db.writeEventIndexes(eventMapToJson(
                            eventListToJsonCompatibleMap(
                                await db.getEvents())));
                        showFeedbackDialog(context, [
                          "Rewritten all Event Flyers",
                          "Updated Indexfile Too"
                        ]);
                      },
                      child: Text(
                          "Rewrite Event Flyer links with 2000x2000 instead of 1000x1000")),
                  ElevatedButton(
                      onPressed: () async {
                        String lmao = await db.readEventIndexesJson();
                        await writeIndexFile(
                            "dev.eventsIndex.json", json.decode(lmao));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("File Written"));
                      },
                      child: Text("Test Index-File-Writing (deprecated)")),
                  ElevatedButton(
                      onPressed: () async {
                        print(await getSavedIndexFile("dev.eventsIndex.json"));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("File Read."));
                      },
                      child: Text("Test Index-File-Reading(deprecated)")),
                  ElevatedButton(
                      onPressed: () async {
                        List<DateTime?> das = [
                          await getSavedIndexFileLastChanged(
                              "dev.eventsIndex.json"),
                          await getSavedIndexFileLastChanged("dev.events.json"),
                          await getSavedIndexFileLastChanged("dev.users.json"),
                          await getSavedIndexFileLastChanged("dev.groups.json")
                        ];
                        showDevFeedbackDialog(context, [
                          "Events(full) : ${das[0]}",
                          "Events(small): ${das[1]}",
                          "Users:       : ${das[2]}",
                          "Groups:      : ${das[3]}",
                        ]);
                      },
                      child:
                          Text("Get Last-Modified for all Index-Files(local)")),
                  ElevatedButton(
                      onPressed: () async {
                        String asd = await db
                            .getIndexFileContent("${branchPrefix}users.json");
                        showDevFeedbackDialog(context, [asd]);
                      },
                      child: Text("Get Users Index File")),
                  ElevatedButton(
                      onPressed: () async {
                        await writeLoginDataWeb("admin", "admin");
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("File Read"));
                      },
                      child: Text("Test writing userdata (Web)")),
                  ElevatedButton(
                      onPressed: () async {
                        Map asd = kIsWeb
                            ? await readLoginDataWeb()
                            : await readLoginDataMobile();
                        showDevFeedbackDialog(context, [asd.toString()]);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("File Read"));
                      },
                      child: Text("Test reading userdata (Web)")),
                  ElevatedButton(
                      onPressed: () async {
                        showDevFeedbackDialog(context, ["Hello"]);
                      },
                      child: Text("Test HintDialog")),
                  ElevatedButton(
                      onPressed: () async {
                        ValueNotifier<String> HostName = ValueNotifier("");
                        await showDialog(
                            context: context,
                            builder: (context) =>
                                SimpleStringEditDialog(to_notify: HostName, name: "Hostname"));
                        Host? host = await db.getDemoHost(HostName.value);
                        showDevFeedbackDialog(context, [
                          "HostName: ${HostName.value}",
                          "Data: ${host.toString()}"
                        ]);
                      },
                      child: Text("Test Single DemoHost getter")),
                  ElevatedButton(
                      onPressed: () async {
                        showDevFeedbackDialog(context, ["DemoHosts Updated."]);
                      },
                      child: Text(
                          "Change all instagram links to instagram (demohosts) (Does Nothing)")),
                  ElevatedButton(
                      onPressed: () async {
                        await writeChatOutline(ChatOutline(
                            chatID: "PwZPV10ktzkzABtfhG4A",
                            members_LastOpened: {
                              "ben": Timestamp.now().millisecondsSinceEpoch,
                              "ben2": Timestamp.now().millisecondsSinceEpoch,
                            }));
                      },
                      child: Text(
                          "write Test Chat (PwZPV10ktzkzABtfhG4A, ben:ben2)")),
                  ElevatedButton(
                      onPressed: () async {
                        ChatOutline? outL =
                            await readChatOutline("PwZPV10ktzkzABtfhG4B");
                        showDevFeedbackDialog(context, [outL.toString()]);
                      },
                      child:
                          Text("Read Test ChatOutline (PwZPV10ktzkzABtfhG4B)")),
                  ElevatedButton(
                      onPressed: () async {
                        List<ChatOutline>? chats = await getChatOutlines();
                        showDevFeedbackDialog(
                            context,
                            chats == null
                                ? ["Null"]
                                : chats.map((e) => e.toString()).toList());
                      },
                      child: Text("Get My ChatOutlines")),
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
                      child: Text(
                          "Write Test-LastMessage (ChatID: PwZPV10ktzkzABtfhG4B)")),
                  ElevatedButton(
                      onPressed: () async {
                        List<Reference> refs = await firebasestorage
                            .ref("chats/PwZPV10ktzkzABtfhG4A/")
                            .listAll()
                            .then((value) => value.items);
                        showDevFeedbackDialog(
                            context, refs.map((e) => e.name).toList());
                      },
                      child: Text(
                          "Test Storage directory listing (PwZPV10ktzkzABtfhG4B)")),
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
                      child: Text("Add Test Message (PwZPV10ktzkzABtfhG4B)")),
                  ElevatedButton(
                      onPressed: () async {
                        List<Message> messages =
                            await getMessagesForChat("PwZPV10ktzkzABtfhG4A");
                        showDevFeedbackDialog(context,
                            messages.map((e) => e.toString()).toList());
                      },
                      child: Text("Test Chat log reading")),
                  ElevatedButton(
                      onPressed: () async {
                        String test = "ÄÖÜäöüß";
                        showDevFeedbackDialog(context, [
                          "Test: $test",
                          "Safe: ${test.dbsafe}",
                          "FromSafe: ${test.fromDBSafeString}"
                        ]);
                      },
                      child: Text("Test String conversion")),
                  ElevatedButton(
                      onPressed: () async {
                        ValueNotifier<String> groupID = ValueNotifier("");
                        await showDialog(
                            context: context,
                            builder: (context) =>
                                SimpleStringEditDialog(to_notify: groupID, name: "GroupID"));
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
                                SimpleStringEditDialog(to_notify: groupID, name: "GroupID"));
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
                                SimpleStringEditDialog(to_notify: groupID, name: "GroupID"));
                        Map? test =
                            await db.readGroupFeedListMap(groupID.value);
                        showDevFeedbackDialog(
                            context,
                            db
                                .feedEntryMapToList(test ?? {})
                                .map((e) => e.toString())
                                .toList());
                      },
                      child: Text("Read Feed file for group")),
                  ElevatedButton(
                      onPressed: () async {
                        ValueNotifier<String> groupID = ValueNotifier("");
                        await showDialog(
                            context: context,
                            builder: (context) =>
                                SimpleStringEditDialog(to_notify: groupID, name: "GroupID"));
                        await db.addFeedEntryToGroupFeed(
                            groupID.value,
                            FeedEntry(
                                ownerpath: "dev.groups/rsr",
                                timestamp: Timestamp.now(),
                                leading_image_path_download_link: null,
                                type: FeedEntryType.ANNOUNCEMENT));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("FeedEntry Added"));
                      },
                      child: Text("Add Test Feed Entry to Group")),
                  ElevatedButton(
                      onPressed: () async {
                        ValueNotifier<String> token = ValueNotifier("");
                        await showDialog(
                            context: context,
                            builder: (context) =>
                                SimpleStringEditDialog(to_notify: token, name: "Token",));
                        dynamic data = await sendFCMMessageToTokens(
                            [token.value], "HELLO", "TestContent");
                        showDevFeedbackDialog(context, [data.toString()]);
                      },
                      child: Text(
                          "Test Cloud Function Calling (Sends a single Message to token via Cloud Message Function)")),
                  ElevatedButton(
                      onPressed: () async {
                        showDevFeedbackDialog(
                            context, [fcmToken ?? "No Token assigned."]);
                      },
                      child: Text("Read This Device's FCMToken")),
                  ElevatedButton(
                      onPressed: () async {
                        await MessagingAPI()
                            .firebaseMessaging
                            .subscribeToTopic("TestTopic");
                        showDevFeedbackDialog(
                            context, [fcmToken ?? "No Token assigned."]);
                      },
                      child: Text("Create Topic (deprecated)")),
                  ElevatedButton(
                      onPressed: () async {
                        ValueNotifier<String> uname = ValueNotifier("");
                        ValueNotifier<String> title = ValueNotifier("");
                        ValueNotifier<String> content = ValueNotifier("");
                        await showDialog(
                            context: context,
                            builder: (context) =>
                                SimpleStringEditDialog(to_notify: uname, name: "reciever username"));
                        await showDialog(
                            context: context,
                            builder: (context) =>
                                SimpleStringEditDialog(to_notify: title, name: "Title"));
                        await showDialog(
                            context: context,
                            builder: (context) =>
                                SimpleStringEditDialog(to_notify: content, name: "Content"));
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
                      child: Text("Add Permission to User (test)")),
                  ElevatedButton(
                      onPressed: () async {
                        await db.removePermissionFromUser(
                            GlobalPermission.ADMIN, "appletestuser");
                        showDevFeedbackDialog(context, ["Permit Removed"]);
                      },
                      child: Text("Remove Permission from User (test)")),
                  ElevatedButton(
                      onPressed: () async {
                        await sendMessageToTopic(
                            "role_ADMIN",
                            "Message Only For Admins",
                            "If you see this, you shouldnt. Just for Testing");
                        showDevFeedbackDialog(context, ["Admins messaged"]);
                      },
                      child: Text("Send Test message to all Admins")),
                  ElevatedButton(
                      onPressed: () async {
                        ValueNotifier<String> fieldname =
                            ValueNotifier("lastEditedInMs");
                        showDialog(
                            context: context,
                            builder: (context) =>
                                SimpleStringEditDialog(to_notify: fieldname, name: "fieldname"));
                        QuerySnapshot allDocs = await db.db
                            .collection("${branchPrefix}users")
                            .get();
                        List<DocumentReference> refs =
                            allDocs.docs.map((doc) => doc.reference).toList();
                        await sync(refs.map((e) {
                          return e.update({fieldname.value: null});
                        }).toList());
                        showDevFeedbackDialog(context, ["Added Field"]);
                      },
                      child: Text(
                          "Add field to all documents of a collection (value: null)")),
                   ElevatedButton(
                      onPressed: () async {
                        QuerySnapshot allDocs = await db.db
                            .collection("${branchPrefix}users")
                            .get();
                        List<DocumentReference> refs =
                            allDocs.docs.map((doc) => doc.reference).toList();
                        await sync(refs.map((e) {
                          return e.update({"lastEditedInMs": Timestamp.fromDate(DateTime.now()).millisecondsSinceEpoch});
                        }).toList());
                        showDevFeedbackDialog(context, ["Added Field"]);
                      },
                      child: Text(
                          "Set lastEditedInMs to all documents of users (value: current)")),
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
              style: cl.df,
            )),
          );
  }
}
