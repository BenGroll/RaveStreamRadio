import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/linkbuttons.dart';


/// About us Screen
class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cl.darkerGrey,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("About Us", style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width / 50,
            vertical: MediaQuery.of(context).size.height / 50
          ),
          children: [
            Image(image: AssetImage("graphics/ravestreamtextlogo.png")),
            UrlLinkButton(
                "https://www.youtube.com/channel/UCYODAI5WVxwmXFDS9n-Dr_Q",
                "RSR Youtube Kanal",
                const TextStyle(color: Colors.white)),
            UrlLinkButton("https://soundcloud.com/user-261391065",
                "RSR Soundcloud", const TextStyle(color: Colors.white)),
            RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                    style: TextStyle(color: Colors.white),
                    children: stringToTextSpanList(aboutusstring)))
          ],
        ),
      ),
    );
  }
}

const aboutusstring = "RaveStreamRadio ist ein Zusammenschluss musikliebender Menschen, die es sich zur Aufgabe gemacht haben, etwas Übersicht in all das wirre Chaos der Münchner Raveszene zu bringen.\n\nHier findet ihr eine Anlaufstelle für Musik und eine Übersicht aller aktuellen Veranstaltungen der Kollektive. Auch den Raum für Politik, wenn wir mal wieder demonstrierend über die Straßen ziehen.\n\nSo habt ihr die Möglichkeit euch eure perfekte Veranstaltung raus zu suchen - Let's go, we'll warm you up to Rave temperature!";
