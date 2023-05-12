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
import 'package:ravestreamradioapp/extensions.dart';

String? usernamevalidator(String? username) {
  if (username == null || username.isEmpty) return "Username can't be Empty";
  List<String> allowedChars = lowercaseCharacters + numbers + ["_"];
  String? out = null;
  username.characters.forEach((element) {
    if (!allowedChars.contains(element)) {
      out = "Username can only contain a-z, 0-9, '_'";
    }
  });
  return out;
}

String? passwordvalidator(String? password) {
  if (password == null || password.isEmpty) return "Password can't be Empty";
  if (password.length < 4)
    return "Password has to be at least 4 characters long";
  if (password.contains(" ")) return "Password can't contain any Spaces";
  return null;
}

class LoginScreen extends StatelessWidget {
  String? username = "";
  GlobalKey<FormFieldState> usernameFieldKey = GlobalKey();
  ValueNotifier<String> usernameValidatorError = ValueNotifier<String>("");
  String? password = "";
  GlobalKey<FormFieldState> passwordFieldKey = GlobalKey();
  ValueNotifier<String> passwordValidatorError = ValueNotifier<String>("");
  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: cl.darkerGrey,
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
                child: ValueListenableBuilder(
                    valueListenable: usernameValidatorError,
                    builder: (context, error, foo) {
                      return TextFormField(
                        key: usernameFieldKey,
                        onChanged: (value) {
                          usernameFieldKey.currentState?.validate();
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
                        validator: usernamevalidator,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.0)),
                            filled: true,
                            fillColor: cl.lighterGrey,
                            prefixText: "@",
                            hintText: "Username",
                            labelText: "Enter your username",
                            labelStyle: const TextStyle(color: Colors.grey),
                            hintStyle: const TextStyle(color: Colors.grey)),
                      );
                    }),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: MediaQuery.of(context).size.width / 10),
                child: ValueListenableBuilder(
                    valueListenable: passwordValidatorError,
                    builder: (context, error, foo) {
                      return TextFormField(
                        key: passwordFieldKey,
                        validator: passwordvalidator,
                        onChanged: (value) {
                          password = value;
                          passwordFieldKey.currentState?.validate();
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
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.0)),
                            filled: true,
                            fillColor: cl.lighterGrey,
                            hintText: "Password",
                            labelText: "Enter your password",
                            labelStyle: const TextStyle(color: Colors.grey),
                            hintStyle: const TextStyle(color: Colors.grey)),
                      );
                    }),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusDirectional.circular(8.0)),
                  primary: cl.lighterGrey, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: () async {
                  if ((!usernameFieldKey.currentState!.isValid ||
                      !passwordFieldKey.currentState!.isValid)) {
                    ScaffoldMessenger.of(context).showSnackBar(cw.hintSnackBar(
                        "One or more Fields doesn't match requirements."));
                    return;
                  }
                  if (!kIsWeb) {
                    cw.showLoadingDialog(context, "Logging in...");
                    dbc.User? tryUserData =
                        await db.tryUserLogin(username ?? "", password ?? "");
                    if (tryUserData == null) {
                      // Throw error dialog. (choices : Retry, anonymous)
                      Navigator.of(context).pop();
                      showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              _showLoginFailedDialog(context));
                    } else {
                      await files.writeLoginDataMobile(
                          username = tryUserData.username,
                          password = tryUserData.password);
                      currently_loggedin_as.value = tryUserData;
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      sleep(const Duration(seconds: 1));
                      ScaffoldMessenger.of(context).showSnackBar(
                          cw.hintSnackBar("Logged in as @$username"));
                    }
                  } else {
                    pprint("Is On Web!");
                    dbc.User? constUser = await db.getUser(username ?? "");
                    if (constUser == null) {
                      await showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              _showLoginFailedDialog(context));
                    } else {
                      pprint("Constructed User");
                      if (constUser.password == password) {
                        currently_loggedin_as.value = constUser;
                        await files.writeLoginDataWeb(
                            constUser.username, constUser.password);
                        Navigator.of(context).pop();
                        Beamer.of(context).beamToNamed("/");
                      } else {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                _showLoginFailedDialog(context));
                      }
                    }
                  }
                },
                child: Text("Login",
                    style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width / 20)),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(" - or - ",
                    style:
                        TextStyle(color: Color.fromARGB(255, 185, 185, 185))),
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusDirectional.circular(8.0)),
                    primary: cl.lighterGrey, // background

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

/// Screen to create a new Account
class CreateAccountScreen extends StatelessWidget {
  CreateAccountScreen({super.key});
  String username = "";
  String password = "";
  String alias = "";
  String description = "";
  String mail = "";
  GlobalKey<FormFieldState> usernameFieldKey = GlobalKey();
  ValueNotifier<String> usernameValidatorError = ValueNotifier<String>("");
  GlobalKey<FormFieldState> passwordFieldKey = GlobalKey();
  ValueNotifier<String> passwordValidatorError = ValueNotifier<String>("");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: cl.darkerGrey,
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
                child: ValueListenableBuilder(
                    valueListenable: passwordValidatorError,
                    builder: (context, error, foo) {
                      return TextFormField(
                        key: usernameFieldKey,
                        onChanged: (value) {
                          username = value;
                          usernameFieldKey.currentState?.validate();
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
                        validator: usernamevalidator,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.0)),
                            filled: true,
                            fillColor: cl.lighterGrey,
                            prefixText: "@",
                            hintText: "Username",
                            labelText: "Choose your username",
                            labelStyle: const TextStyle(color: Colors.grey),
                            hintStyle: const TextStyle(color: Colors.grey)),
                      );
                    }),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: MediaQuery.of(context).size.width / 10),
                child: ValueListenableBuilder(
                    valueListenable: passwordValidatorError,
                    builder: (context, error, foo) {
                      return TextFormField(
                        key: passwordFieldKey,
                        validator: passwordvalidator,
                        onChanged: (value) {
                          password = value;
                          passwordFieldKey.currentState?.validate();
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
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.0)),
                            filled: true,
                            fillColor: cl.lighterGrey,
                            hintText: "Password",
                            helperText: "Password",
                            labelText: "Choose your password",
                            labelStyle: const TextStyle(color: Colors.grey),
                            hintStyle: const TextStyle(color: Colors.grey)),
                      );
                    }),
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusDirectional.circular(8.0)),
                    primary: cl.lighterGrey, // background
                    onPrimary: Colors.white, // foreground
                  ),
                  onPressed: () async {
                    if (!usernameFieldKey.currentState!.isValid ||
                        !passwordFieldKey.currentState!.isValid) {
                      ScaffoldMessenger.of(context).showSnackBar(cw.hintSnackBar(
                          "One or more Fields doesn't match requirements."));
                      return;
                    }
                    if (username.isEmpty) {
                      showDialog(
                          context: context,
                          builder: (context) =>
                              _showUsernameTakenDialog(context, username));
                      return;
                    }
                    if (await db.db
                        .doc("${branchPrefix}users/$username")
                        .get()
                        .then((value) => value.exists)) {
                      showDialog(
                          context: context,
                          builder: (context) =>
                              _showUsernameTakenDialog(context, username));
                    } else {
                      cw.showLoadingDialog(context, "Creating User...");
                      dbc.User createdUser = dbc.User(
                          username: username,
                          password: password,
                          alias: alias,
                          description: description,
                          path: "${branchPrefix}users/$username");
                      await db.db
                          .doc("${branchPrefix}users/$username")
                          .set(createdUser.toMap());
                      await db.addUserToIndexFile(createdUser);
                      currently_loggedin_as.value =
                          await tryUserLogin(username, password);
                      kIsWeb
                          ? await files.writeLoginDataWeb(username, password)
                          : await files.writeLoginDataMobile(
                              username = username, password = password);
                      Navigator.of(context).pop();
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusDirectional.circular(8.0)),
                    primary: cl.lighterGrey, // background
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

/// Shows the dialog to tell the user the username they chose is already taken
Widget _showUsernameTakenDialog(BuildContext context, String? uname) {
  return AlertDialog(
    title: Text("Username Taken", style: TextStyle(color: Colors.white)),
    backgroundColor: cl.lighterGrey,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      // ignore: prefer_const_literals_to_create_immutables
      children: [
        uname == null || uname.isEmpty
            ? Text("Username can't be empty",
                style: TextStyle(color: Colors.white))
            : Text("Username has to be unique. Account @$uname exists already.",
                style: TextStyle(color: Colors.white))
      ],
    ),
    actions: [
      TextButton(
        child: const Text("Retry", style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      TextButton(
        child: const Text("Browse Anonymously",
            style: TextStyle(color: Colors.white)),
        onPressed: () {
          if (kIsWeb) {
            Beamer.of(context).beamToNamed("/events/");
          } else {
            print("HERE");
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          }
        },
      ),
    ],
  );
}

/// Show Dialog with wrong login credentials
Widget _showLoginFailedDialog(BuildContext context) {
  return AlertDialog(
    backgroundColor: cl.lighterGrey,
    content: const Text("Couldn't login using this data.",
        style: TextStyle(color: Colors.white)),
    actions: [
      TextButton(
        child: const Text("Retry", style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      TextButton(
        child: const Text("Browse Anonymously",
            style: TextStyle(color: Colors.white)),
        onPressed: () {
          if (kIsWeb) {
            Beamer.of(context).beamToNamed("/events/");
          } else {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          }
        },
      ),
    ],
  );
}
