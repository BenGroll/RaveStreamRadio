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
                radius: 60,
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
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              width:  MediaQuery.of(context)
                                                                  .size
                                                                  .width ,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  Text(
                    user.username,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                 
                ],
              ),
            ),
            
            const SizedBox(
              height: 30,
            ),
            SizedBox(
              height:  MediaQuery.of(context)
                                                                  .size
                                                                  .height,
              width:  MediaQuery.of(context)
                                                                  .size
                                                                  .width ,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  cw.ProfileWidget(
                    icon: Icons.person,
                    title: 'Edit Profile',
                  ),
                  cw.ProfileWidget(
                    icon: Icons.settings,
                    title: 'Settings',
                  ),
                  
                  
                
                  cw.ProfileWidget(
                    icon: Icons.share,
                    title: 'Share',
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