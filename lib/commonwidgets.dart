import 'package:flutter/material.dart';
import 'colors.dart' as cl;

SnackBar hintSnackBar(String alertMessage) {
  return SnackBar(
      backgroundColor: cl.deep_black,
      behavior: SnackBarBehavior.fixed,
      content: Text(alertMessage));
}

class FutureImageBuilder extends StatelessWidget {
  final Future<Widget> futureImage;
  const FutureImageBuilder({required this.futureImage});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: futureImage,
        builder: ((context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return snapshot.data as Widget;
          } else {
            return const CircularProgressIndicator(color: Colors.white);
          }
        }));
  }
}
