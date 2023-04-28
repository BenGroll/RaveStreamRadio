import 'package:beamer/beamer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/screens/devsettingsscreen.dart';
import 'package:ravestreamradioapp/screens/homescreen.dart' as home;
import 'package:ravestreamradioapp/screens/loginscreen.dart';
import 'package:ravestreamradioapp/filesystem.dart' as files;
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/screens/overviewpages/useroverviewpage.dart';
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;
import 'package:ravestreamradioapp/extensions.dart';

import '../../conv.dart';


class ProfileScreen extends StatefulWidget {
  final dbc.User? loggedinas;
  const ProfileScreen({super.key, required this.loggedinas});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return widget.loggedinas == null
        ? NotLoggedInScaffold()
        : LoggedInScaffold(loggedinas: widget.loggedinas ?? dbc.demoUser);
  }
}

class NotLoggedInScaffold extends StatelessWidget {
  const NotLoggedInScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cl.lighterGrey,
      body: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 20.0,
            horizontal: 10.0,
          ),
          child: Center(
            child: ElevatedButton(
              child: const Text("Login"),
              onPressed: () {
                //Navigate to Login Screen
                kIsWeb
                ? Beamer.of(context).beamToNamed("/login")
                : Navigator.of(context).push(
                    MaterialPageRoute(builder: ((context) => LoginScreen())));
              },
            ),
          )),
    );
  }
}

class LoggedInScaffold extends StatelessWidget {
  final dbc.User loggedinas;
  const LoggedInScaffold({super.key, required this.loggedinas});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cl.darkerGrey,
      body : ProfileView());
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});
  

  @override
  Widget build(BuildContext context) {
     dbc.User? user = currently_loggedin_as.value;
  return user == null
      ? Text('Not logged in')
 :Scaffold(
  backgroundColor: cl.darkerGrey,
body: SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
         
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 150,
              child: const CircleAvatar(
                radius: 70,
                /*backgroundImage: SvgPicture(pictureProvider),*/
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: cl.lighterGrey,
                  width: 5.0,
                ),
              ),
            ),
            // Avatar Editor Icon
            SizedBox(
              height: 30,
            ),

            SizedBox(
              width:  MediaQuery.of(context)
                                                                  .size
                                                                  .width ,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                                                       SizedBox(child: IconButton(onPressed: () => cw.ProfileAliasEditor(initialValue: user.alias,
                                            onChange: (value) {
                                              user.alias = value;
                                            },),
                                  icon: Icon(Icons.edit,
                                  color: Colors.white
                                  ),
                                      ),
                                      )
                                                      ,],),
                  Padding(padding: EdgeInsets.all(0),
                  child:
                  user.alias != null
                  ? Text(
                    user.username,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                    ),
                  )
                  : Container(
                    child: Text("You don't have an alias yet!",
                    style: TextStyle(color: Colors.white)),
                  )
                  ),
                  SizedBox(
  height: 30,
),
 Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  
  children: [SizedBox(child: Text('Description:', 
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold),
                                                      textAlign: TextAlign.center,
                                                      ),
                                                      
                                                      ) , 
                                                      
                        SizedBox(child: IconButton(onPressed: () => cw.ProfileDescriptionEditor(initialValue: user.alias,
                                            onChange: (value) {
                                              user.alias = value;
                                            },),
                                  icon: Icon(Icons.edit,
                                  color: Colors.white
                                  ),
                                      ),
                                      ),]),
                                                      
                  SizedBox(
                                                      child: user.
                                                                  description !=
                                                              null
                                                          ? Padding(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                      16.0),
                                                              child: RichText(
                                                                  maxLines: 50,
                                                                  softWrap:
                                                                      true, 
                                                                  textAlign: TextAlign.center,
                                                                  text: TextSpan(
                                                                      style: const TextStyle(
                                                                          color: Colors
                                                                              .white),
                                                                      children: (user.description == null || user.description!.isEmpty)
                                                                          ? null
                                                                          : stringToTextSpanList(user.description ??
                                                                              ""))))
                                                          : const SizedBox(
                                                              child: Text("Add a Description and tell something about yourself!",
                    style: TextStyle(color: Colors.white)),),
                                                    ),
SizedBox(
  height: 30,
),
 SizedBox(child: Text('Email Adress:', 
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold),
                                                      textAlign: TextAlign.center,
                                                      )) ,
                                                    SizedBox(
                                                      child: user.
                                                                mail !=
                                                              null
                                                          ? Padding(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                      16.0),
                                                              child: RichText(
                                                                  maxLines: 50,
                                                                  softWrap:
                                                                      true, 
                                                                  textAlign: TextAlign.center,
                                                                  text: TextSpan(
                                                                      style: const TextStyle(
                                                                          color: Colors
                                                                              .white),
                                                                      children: (user.mail == null || user.mail!.isEmpty)
                                                                          ? null
                                                                          : stringToTextSpanList(user.mail ??
                                                                              ""))))
                                                          : const SizedBox(
                                                              child: Text("Add your Email Adress!",
                    style: TextStyle(color: Colors.white)),),
                                                    ),SizedBox(
  height: 30,
),
                                                    
                                                    SizedBox(child: Text('Hosting Events:', 
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold),
                                                      textAlign: TextAlign.center,
                                                      )) ,
                                                    SizedBox(
                                                      child: user.
                                                                  events !=
                                                              null
                                                          ? Padding(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                      16.0),
                                                              child: RichText(
                                                                  maxLines: 50,
                                                                  softWrap:
                                                                      true, 
                                                                  textAlign: TextAlign.center,
                                                                  text: TextSpan(
                                                                      style: const TextStyle(
                                                                          color: Colors
                                                                              .white),
                                                                      children: (user.events == null || user.events!.isEmpty)
                                                                          ? null
                                                                          : stringToTextSpanList(user.description ??
                                                                              ""))))
                                                          : const SizedBox(
                                                          child: Text("You didn't host an event yet!",
                    style: TextStyle(color: Colors.white)),),
                                                    ),
                                                   
                                                    
                 
                ],
              ),
            ),
            
           
          ],
        ),
      ),
    ),
    );
     
      
  }
}