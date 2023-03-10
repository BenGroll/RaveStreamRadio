import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/commonwidgets.dart';
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/databaseclasses.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/payments.dart' as pay;

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
              child: Column(
                mainAxisSize: MainAxisSize.max,
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) => pay.paypalInterface
                            )
                        );
                        ScaffoldMessenger.of(context)
                            .showSnackBar(hintSnackBar("Payment"));
                      },
                      child: Text("Test Paypal Payment"))
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
