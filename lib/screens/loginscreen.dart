// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:beamer/beamer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/database.dart';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/filesystem.dart' as files;
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;
import 'package:ravestreamradioapp/shared_state.dart';

class LoginScreen extends StatelessWidget {
  String? username = "";
  String? password = "";
  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: cl.deep_black,
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text("Log In",
                    style: TextStyle(
                        fontSize: MediaQuery.of(context).size.height / 20,
                        color: Colors.white)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: MediaQuery.of(context).size.width / 10),
                child: TextFormField(
                  onChanged: (value) {
                    username = value;
                  },
                  onFieldSubmitted: (value) {
                    username = value;
                  },
                  onSaved: (value) {
                    username = value;
                  },
                  cursorColor: Colors.grey,
                  style: const TextStyle(color: Colors.white),
                  autocorrect: false,
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: cl.nearly_black,
                      prefixText: "@",
                      hintText: "Username",
                      helperStyle: const TextStyle(color: Colors.grey),
                      helperText: "Cannot be changed later",
                      labelText: "Enter your username",
                      labelStyle: const TextStyle(color: Colors.grey),
                      hintStyle: const TextStyle(color: Colors.grey)),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: MediaQuery.of(context).size.width / 10),
                child: TextFormField(
                  onChanged: (value) {
                    password = value;
                  },
                  onFieldSubmitted: (value) {
                    password = value;
                  },
                  onSaved: (value) {
                    password = value;
                  },
                  autocorrect: false,
                  cursorColor: Colors.grey,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: cl.nearly_black,
                      hintText: "Password",
                      helperText: "Password",
                      labelText: "Enter your password",
                      labelStyle: const TextStyle(color: Colors.grey),
                      hintStyle: const TextStyle(color: Colors.grey)),
                ),
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: cl.nearly_black, // background
                    onPrimary: Colors.white, // foreground
                  ),
                  onPressed: () async {
                    print("Button Pressed");
                    if (!kIsWeb) {
                      dbc.User? tryUserData =
                          await db.tryUserLogin(username ?? "", password ?? "");

                      if (tryUserData == null) {
                        // Throw error dialog. (choices : Retry, anonymous)
                        showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                _showLoginFailedDialog(context));
                      } else {
                        kIsWeb
                            ? await files.writeLoginDataWeb(
                                tryUserData.username, tryUserData.password)
                            : await files.writeLoginDataMobile(
                                username = tryUserData.username,
                                password = tryUserData.password);
                        currently_loggedin_as.value = tryUserData;
                        Beamer.of(context).beamToNamed("/profile/");
                        sleep(const Duration(seconds: 1));
                        ScaffoldMessenger.of(context).showSnackBar(
                            cw.hintSnackBar("Logged in as @$username"));
                      }
                    } else {
                      print("Is On Web!");

                      DocumentSnapshot doc = await db.db
                          .doc("${branchPrefix}users/$username")
                          .get();

                      if (!doc.exists) {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                _showLoginFailedDialog(context));
                      } else {
                        print("User exists!");
                        Map<String, dynamic>? docData =
                            doc.data() as Map<String, dynamic>?;
                        print(doc.data());
                        if (docData == null) {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                  _showLoginFailedDialog(context));
                        } else {
                          dbc.User tryUserData = dbc.User.fromMap(docData);
                          if (tryUserData.password == password) {
                            currently_loggedin_as.value = tryUserData;
                            Beamer.of(context).beamToNamed("/");
                          } else {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    _showLoginFailedDialog(context));
                          }
                        }
                      }
                    }
                  },
                  child: Text("Login",
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width / 20))),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(" - or - ",
                    style:
                        TextStyle(color: Color.fromARGB(255, 185, 185, 185))),
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: cl.nearly_black, // background
                    onPrimary: Colors.white, // foreground
                  ),
                  onPressed: () {
                    kIsWeb
                        ? Beamer.of(context).beamToNamed("/createaccount/")
                        : Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (context) => CreateAccountScreen()));
                  }, //Create new Account button
                  child: Text("Create new account",
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width / 25))),
            ],
          ),
        ));
  }
}

class CreateAccountScreen extends StatelessWidget {
  CreateAccountScreen({super.key});
  String username = "";
  String password = "";
  String alias = "";
  String description = "";
  String mail = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: cl.deep_black,
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text("Create Account",
                    style: TextStyle(
                        fontSize: MediaQuery.of(context).size.height / 20,
                        color: Colors.white)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: MediaQuery.of(context).size.width / 10),
                child: TextFormField(
                  onChanged: (value) {
                    username = value;
                  },
                  onFieldSubmitted: (value) {
                    username = value;
                  },
                  onSaved: (value) {
                    username = value ?? "";
                  },
                  cursorColor: Colors.grey,
                  style: const TextStyle(color: Colors.white),
                  autocorrect: false,
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: cl.nearly_black,
                      prefixText: "@",
                      hintText: "Username",
                      helperText: "Username",
                      labelText: "Choose your username",
                      labelStyle: const TextStyle(color: Colors.grey),
                      hintStyle: const TextStyle(color: Colors.grey)),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: MediaQuery.of(context).size.width / 10),
                child: TextFormField(
                  onChanged: (value) {
                    password = value;
                  },
                  onFieldSubmitted: (value) {
                    password = value;
                  },
                  onSaved: (value) {
                    password = value ?? "";
                  },
                  autocorrect: false,
                  cursorColor: Colors.grey,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: cl.nearly_black,
                      hintText: "Password",
                      helperText: "Password",
                      labelText: "Choose your password",
                      labelStyle: const TextStyle(color: Colors.grey),
                      hintStyle: const TextStyle(color: Colors.grey)),
                ),
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: cl.nearly_black, // background
                    onPrimary: Colors.white, // foreground
                  ),
                  onPressed: () async {
                    if (username.isEmpty) {}
                    if (await db.db
                        .doc("${branchPrefix}users/$username")
                        .get()
                        .then((value) => value.exists)) {
                      _showUsernameTakenDialog(context, username);
                    } else {
                      dbc.User createdUser = dbc.User(
                          username: username,
                          password: password,
                          alias: alias,
                          description: description);

                      await db.db
                          .doc("${branchPrefix}users/$username")
                          .set(createdUser.toMap());
                      currently_loggedin_as.value =
                          await tryUserLogin(username, password);
                      kIsWeb
                          ? await files.writeLoginDataWeb(username, password)
                          : await files.writeLoginDataMobile(
                              username = username, password = password);
                      kIsWeb
                          ? Beamer.of(context).beamToNamed("/profile")
                          : Navigator.of(context).pop();
                      if (!kIsWeb) {
                        sleep(const Duration(seconds: 1));
                        ScaffoldMessenger.of(context).showSnackBar(
                            cw.hintSnackBar("User Created Successfully!"));
                      }
                    }
                  },
                  child: Text("Create and Login",
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width / 20))),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(" - or - ",
                    style:
                        TextStyle(color: Color.fromARGB(255, 185, 185, 185))),
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: cl.nearly_black, // background
                    onPrimary: Colors.white, // foreground
                  ),
                  onPressed: () {
                    kIsWeb
                        ? Beamer.of(context).beamToNamed("/login/")
                        : Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: ((context) => LoginScreen())));
                  },
                  child: Text("Login with existing Account",
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width / 25))),
            ],
          ),
        ));
  }
}

Widget _showUsernameTakenDialog(BuildContext context, String? uname) {
  return AlertDialog(
    title: const Text("Username Taken"),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      // ignore: prefer_const_literals_to_create_immutables
      children: [
        uname == null
            ? Text("Username can't be empty")
            : Text("Username has to be unique. Account @$uname exists already.")
      ],
    ),
    actions: [
      TextButton(
        child: const Text("Retry"),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      TextButton(
        child: const Text("Browse Anonymously"),
        onPressed: () {
          Beamer.of(context).beamToNamed("/events/");
        },
      ),
    ],
  );
}

Widget _showLoginFailedDialog(BuildContext context) {
  return AlertDialog(
    content: const Text("Couldnt login using this data."),
    actions: [
      TextButton(
        child: const Text("Retry"),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      TextButton(
        child: const Text("Browse Anonymously"),
        onPressed: () {
          Beamer.of(context).beamToNamed("/events/");
        },
      ),
    ],
  );
}
