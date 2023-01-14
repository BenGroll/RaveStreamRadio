import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/databaseclasses.dart' as dbc;
import 'package:ravestreamradioapp/database.dart' as db;

List<dbc.User> testuserlist = [
  dbc.User(
    username: "admin",
    password: "Admin"
  )
];
List<dbc.Group> testgrouplist = [
  dbc.Group(
      groupid: "bavarianfetish",
      members_roles: {db.db.doc("${branchPrefix}users/admin/"): "Role"}),
  dbc.Group(
      groupid: "timetripping",
      members_roles: {db.db.doc("${branchPrefix}users/admin/"): "Role"}),
  dbc.Group(
      groupid: "extase",
      members_roles: {db.db.doc("${branchPrefix}users/admin/"): "Role"}),
  dbc.Group(
      groupid: "peopleofpoison",
      members_roles: {db.db.doc("${branchPrefix}users/admin/"): "Role"}),
  dbc.Group(
      groupid: "kinkyinsiders",
      members_roles: {db.db.doc("${branchPrefix}users/admin/"): "Role"})
];

List<dbc.Event> testeventlist = [
  dbc.Event(
      eventid: "timetrippingchristmas2k23",
      title: "Merry Christmas",
      begin: Timestamp.fromDate(DateTime.now().add(Duration(days: 365))),
      end: Timestamp.fromDate(DateTime.now().add(Duration(days: 366))),
      locationname: "Unter Deck, Oberanger, München",
      icon: "timetrippingtesticon.jpg",
      age: "18+",
      description: "",
      links: {"instagram": "https://www.instagram.com/timetrippingmunich/"},
      hostreference: db.db.doc("${branchPrefix}groups/timetripping")),
  dbc.Event(
      eventid: "extasechristmas2k23",
      title: "Extase Christmas",
      begin: Timestamp.fromDate(DateTime.now().add(Duration(days: 366))),
      end: Timestamp.fromDate(DateTime.now().add(Duration(days: 367))),
      locationname: "Schwitzkasten, München",
      icon: "extasetesticon.jpg",
      age: "18+",
      description:
          "Hoho und Hallo zusammen,\nWir hoffe ihr seid schon ein bisschen in Weihnachtsstimmung🎅🎄\nWir starten um uns vom besinnlichen Fest an Heiligabend ordentlich zu erholen einen Xmas-Rave am 25.12!\nEs warten wie jedes Mal einige Überraschungen auf euch! 🤫\nWir freuen uns auf jeden Fall riesig drauf mit euch die Feiertage zu überbrücken und das Weihnachtsessen wieder aus zu schwitzen!🎄🧑‍🎄\nDie ersten Tickets gehen im Laufe der nächsten Woche online\nMit freundlichen vorweihnachtlichen Grüßen \n🎅Extase-Crew🎅",
      links: {"instagram": "https://www.instagram.com/extase_crew/"},
      hostreference: db.db.doc("${branchPrefix}groups/extase")),
  dbc.Event(
      eventid: "popfinalcut",
      title: "Final Cut",
      begin: Timestamp.fromDate(DateTime.now().add(Duration(days: 367))),
      end: Timestamp.fromDate(DateTime.now().add(Duration(days: 368))),
      locationname: "Kunstblock Balve, München",
      icon: "poptesticon.png",
      age: "18+",
      description:
          "Thanks for the massive support on our last showdown this year - POP pres. FINAL CUT is almost sold out. Besides our music, it’s your encouragement that means most to us and we can’t wait to see you all again on 09|12|22.\nCheck our uncompromising schedule of the night. There’s some support coming in from our good friends of the house. Welcome back, @jakob___xvii & @sarica_ supporting our residents set in line to loosen a tremendous firework, even before new year’s eve. We are bringing some audio-/visual specials to the table this time. But for now - less talk. More action.\nZero tolerance for any\n- Discrimination\n- Racism\n- Sexism\n- Ableism\n- Homophobia\nbe loving. stay poison.",
      links: {"instagram": "https://www.instagram.com/people.of.poison/"},
      hostreference: db.db.doc("${branchPrefix}groups/peopleofpoison")),
  dbc.Event(
    eventid: "famuehlefestival2k23",
    title: "FaMühle Festival",
    begin: Timestamp.fromDate(DateTime.now().add(Duration(days: 368))),
    end: Timestamp.fromDate(DateTime.now().add(Duration(days: 369))),
    locationname: "Laub, Munningen, Deutschland",
    age: null,
    icon: "famuehletesticon.jpg",
    description:
        "Es ist angerichtet. 🍜\nHeiß und fettig. Unser Programm steht für dieses Jahr und freuen uns darauf, es euch servieren zu dürfen. Der Aufbau beginnt in wenigen Tagen und bis dahin wurschtln wir noch ein wenig rum.\nDanke schon mal an alle Beteiligten, die das Fest wieder zu dem machen was es wird. DANKE!\Klein, fein, bunt, wild, laut, entspannt, einzigartig und natürlich famühlier wird's einfach wieder. 🤤\nWir freuen uns unendlich auf euch. 😘\nTickets: DM auf Insta",
    links: {"instagram": "https://www.instagram.com/famuehle/"},
  ),
  dbc.Event(
      eventid: "kinkyinsiderssession2",
      title: "Session II",
      begin: Timestamp.fromDate(DateTime.now().add(Duration(days: 369))),
      end: Timestamp.fromDate(DateTime.now().add(Duration(days: 370))),
      locationname: "Moosfeld, München, Deutschland",
      age: "18+",
      icon: "kinkytesticon.jpg",
      description:
          "7 playrooms and chillout areas\nWhirlpool\nDuschen\nRaucherbereich\n10 Gebote: siehe zweites Bild in dem folgenden Link: https://www.instagram.com/p/CloySfmKnrL/?utm_source=ig_web_copy_link",
      links: {
        "instagram": "https://www.instagram.com/knkynsdrs/",
        "Google Docs":
            "https://docs.google.com/forms/d/e/1FAIpQLSeHu9cNOz_nbeo0-i3C-2R3tpnhB2GLM_GcIjCnROjZse-oLgviewform"
      },
      hostreference: db.db.doc("${branchPrefix}groups/kinkyinsiders")), 
  dbc.Event(
    eventid: "shameless",
    title: "Shameless",
    begin: Timestamp.fromDate(DateTime.now().add(Duration(days: 370))),
    end: Timestamp.fromDate(DateTime.now().add(Duration(days: 371))),
    locationname: "Pandora Club München",
    age: "18+",
    icon: "bavarianfetishicon.jpg",
    description: "Shameless - der Name ist Programm!\nEine glamouröse Location, treibend Bässe, großartige Dj´s, Videoprojektionen,\nTänzer und Shows verschmelzen zu einem traumhaften sinnlichen Schauspiel.\nSei was Du willst, fühle Dich frei und erlebe was Dir gefällt.\nEin respektvoller Umgang mit deinen Mitmenschen ist die Voraussetzung für deine Anwesenheit.\nLGBT wird bei uns gelebt.\nDRESSCODE:\nFetish Styles, Steam Punk, sexy Leder oder Latex Outfits, Uniformen, Burlesque,\nSuicide Girl ,Kinky Fantasy, Cyber Gothic, Drag Queen, versautes Einhorn .etc.\nDeiner Fantasy sind keine Grenzen gesetzt.\nDa der Dresscode ist ein maßgeblich Bestandteil unserer Atmosphäre ist,\naber am Ende entscheidet aber immer deine Attitude (nicht ein Kleidungsstück)\nBei uns gilt ein absolutes Photoverbot\nBitte lasst eure Handys in der Garderobe\nWillkommen in unseren Wohnzimmer der Sinne,\nwillkommen auf der Shameless!\n► neue Glamour Location im WERK 3 am Ostbahnhof\n► best electronic music for kinky people \n► special Acts & Guests \n► GoGos and Shows\n► Special Visuals and Lightshows\n► Bodypainting\n► Candy Girl´s\n► Überraschungen\nLineup: \nBavarian Allstars :\nCarl Cock , BISHOP , ANDREW CLARK",
    hostreference: db.db.doc("${branchPrefix}groups/bavarianfetish")
    ),
];
