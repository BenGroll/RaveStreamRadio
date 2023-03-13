import 'package:flutter/material.dart';

/// Page to edit description (Richtext)
class DescriptionEditingPage extends StatelessWidget {
  String initialValue;
  late String currentValue;
  Function(String)? onChange;
  DescriptionEditingPage({this.initialValue = "", key, required this.onChange}) : super(key: key);
  @override
  Widget build(BuildContext context) {
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
