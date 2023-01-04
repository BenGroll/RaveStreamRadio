import 'package:flutter/material.dart';
import 'colors.dart' as cl;
import 'package:ravestreamradioapp/pres/rave_stream_icons_icons.dart'
    show RaveStreamIcons;
import 'package:ravestreamradioapp/colors.dart' as cl;

/// Custom Snackbar used to notify User
/// Fixed to the bottom of scaffold body
SnackBar hintSnackBar(String alertMessage) {
  return SnackBar(
      backgroundColor: cl.deep_black,
      behavior: SnackBarBehavior.fixed,
      content: Text(alertMessage));
}

/// Custom Builder to support waiting for image data.
/// Returns CircularProgressIndicator until image is loaded
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

class OpenSidebarButton extends StatelessWidget {
  const OpenSidebarButton({super.key});
  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
        child: Image(image: AssetImage("graphics/ravestreamlogo_white_on_trans.png")));
  }
}

class NavBar extends StatelessWidget {
  const NavBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: cl.nearly_black,
      child: ListView(
        padding: EdgeInsets.zero,
      ),
    );
  }
}
