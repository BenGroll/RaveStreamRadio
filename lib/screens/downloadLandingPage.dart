import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:ravestreamradioapp/commonwidgets.dart';
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/database.dart' as db;
import 'package:ravestreamradioapp/filesystem.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/shared_state.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadLandingPage extends StatelessWidget {
  const DownloadLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: cl.darkerGrey,
          appBar: AppBar(
              centerTitle: true,
              title: Text("Welcome to RSR!",
                  style: TextStyle(color: Colors.white))),
          body: FutureBuilder(
              future: remoteConfig.fetchAndActivate(),
              builder: (context, AsyncSnapshot snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return Center(
                      child: Image.asset(
                          "graphics/ravestreamlogo_white_on_trans.png"));
                } else {
                  String androidURL = ANDROID_DOWNLOADLINK;
                  String iosURL = IOS_DOWNLOADLINK;
                  String webURL = WEB_DOWNLOADLINK;
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () async {
                              if (!await canLaunchUrl(Uri.parse(androidURL))) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    hintSnackBar(
                                        "Couldnt open Android download Link"));
                              }
                              await launchUrl(Uri.parse(androidURL),
                                  mode: LaunchMode.externalApplication);
                            },
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height /
                                              4,
                                      width:
                                          MediaQuery.of(context).size.width / 4,
                                      child: Image.asset(
                                          "graphics/play-store-logo-33864.png")),
                                  Text("Download on Google Play Now!",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              20))
                                ]),
                          ),
                          InkWell(
                            onTap: () async {
                              if (!await canLaunchUrl(Uri.parse(iosURL))) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    hintSnackBar(
                                        "Couldnt open IOS download Link"));
                              }
                              await launchUrl(Uri.parse(iosURL),
                                  mode: LaunchMode.externalApplication);
                            },
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height /
                                              4,
                                      width:
                                          MediaQuery.of(context).size.width / 4,
                                      child: Image.asset(
                                          "graphics/app-store-png-logo-33120.png")),
                                  Text("App-Store coming Soon!",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              20)),
                                ]),
                          ),
                          InkWell(
                            onTap: () async {
                              if (!await canLaunchUrl(Uri.parse(webURL))) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    hintSnackBar(
                                        "Couldnt open WEB download Link"));
                              }
                              await launchUrl(Uri.parse(webURL),
                                  mode: LaunchMode.externalApplication);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text("Click here to use the Website!",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          DISPLAY_SHORT_SIDE(context) / 20)),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }
              }),
        )
      ],
    );
  }
}
