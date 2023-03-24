import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:beamer/beamer.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/chatting.dart';

class ChatsDrawer extends StatelessWidget {
  const ChatsDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: cl.nearly_black,
      child: FutureBuilder(
        future: getUsersChats(),
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.done) {
          return ListView(
            children: snapshot.data!.map((e) => ChatTile(chat: e)).toList(),
          );
          } else {
            return AspectRatio(aspectRatio: 1, child: CircularProgressIndicator());
          }
        }
      )
      
    );
  }
}

