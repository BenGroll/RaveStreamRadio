import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/extensions.dart';

/// Page to edit description (Richtext)
class DescriptionEditingPage extends StatelessWidget {
  String initialValue;
  Function(String)? onChange;
  DescriptionEditingPage({this.initialValue = "", key, required this.onChange});
  @override
  Widget build(BuildContext context) {
    late String currentValue;

    currentValue = initialValue;
    return TextFormField(
      initialValue: initialValue,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.multiline,
      maxLines: null,
      autofocus: true,
      expands: true,
      cursorColor: Colors.white,
      onChanged: onChange,
    );
  }
}
