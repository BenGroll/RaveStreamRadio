import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/commonwidgets.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/database.dart' as db;

class DevSettingsScreen extends StatelessWidget {
  const DevSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return currently_loggedin_as.value!.is_dev ?? false
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Branch: ",
                        style: TextStyle(color: Colors.white)),
                    DropdownButton(
                        dropdownColor: cl.deep_black,
                        value: selectedbranch.value,
                        items:
                            ServerBranches.values.map((ServerBranches branch) {
                          return DropdownMenuItem(
                              value: branch,
                              child: Text(
                                branch.toString(),
                                style: const TextStyle(color: Colors.white),
                              ));
                        }).toList(),
                        onChanged: (ServerBranches? newbranch) {
                          if (newbranch != null)
                            selectedbranch.value = newbranch;
                        })
                  ],
                ),
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
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ElevatedButton(
                    onPressed: (() async {
                      await db.setTestDBScenario();
                      ScaffoldMessenger.of(context)
                          .showSnackBar(hintSnackBar("Added testevents"));
                    }),
                    child: Text("Add test events to ${selectedbranch.value}"),
                  )
                ])
              ],
            ),
          )
        : Text("You dont have privileges to edit developer settings.");
  }
}
