// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/extensions.dart';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;

/// Page to edit description (Richtext)
class DescriptionEditingPage extends StatelessWidget {
  ValueNotifier<dbc.Event> to_Notify;
  DescriptionEditingPage(
      {key, required this.to_Notify})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: to_Notify,
        builder: (context, ev, foo) {
          return TextFormField(
            autofocus: true,
            initialValue: ev.description,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.multiline,
            maxLines: null,
            expands: true,
            cursorColor: Colors.white,
            onChanged: (value) {
              to_Notify.value.description = value;
              to_Notify.notifyListeners();
            },
            onFieldSubmitted: (value) {
              to_Notify.value.description = value;
              to_Notify.notifyListeners();
            },
          );
        });
  }
}
