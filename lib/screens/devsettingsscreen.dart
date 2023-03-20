import 'dart:convert';
import 'dart:io';

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

/// Screen for developer level Actions and Informations
class DevSettingsScreen extends StatelessWidget {
  const DevSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool sees_devsettings =
        db.doIHavePermission(GlobalPermission.CHANGE_DEV_SETTINGS);
    return sees_devsettings
        ? Scaffold(
            backgroundColor: cl.deep_black,
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
                                dropdownColor: cl.deep_black,
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
                        print(events);
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
                        print(await readChatFromDB(testchat["id"])
                            .then((value) => value.toMap()));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Json Read Test"));
                      },
                      child: Text("read Chat from json test")),
                  ElevatedButton(
                      onPressed: () async {
                        Chat chat = Chat.fromMap(testchat);
                        print(chat.members);
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
                ],
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: Text("Missing Permission"),
            ),
            backgroundColor: cl.deep_black,
            body: Center(
                child: Text(
              "You dont have permission to edit developer settings.",
              style: TextStyle(color: Colors.white),
            )),
          );
  }
}
