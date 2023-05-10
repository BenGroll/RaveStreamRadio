import 'dart:convert';
import 'dart:io';
import 'package:ravestreamradioapp/extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/commonwidgets.dart';
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/databaseclasses.dart';
import 'package:ravestreamradioapp/screens/chatwindow.dart';
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
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Created Indexes"));
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
                  ElevatedButton(
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
                  ElevatedButton(
                      onPressed: () async {
                        print(generateDocumentID());
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Chat Test"));
                      },
                      child: Text("Generate 20-length Document ID")),
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
                      child: Text("Test load Messages from IDList")),
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
                        print(await db.getIndexedEntitys());
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
                            .map((e) =>
                                db.db
                                    .doc(
                                        "${branchPrefix}events/${e["eventid"]}")
                                    .update({
                                  "flyer": e["flyer"].runtimeType == String ? 
                                      e["flyer"].replaceAll("1000x1000", "2000x2000") : null
                                }))
                            .toList();
                        await Future.wait(futures);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Events read"));
                      },
                      child: Text("Rewrite Event Flyer links")),
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
