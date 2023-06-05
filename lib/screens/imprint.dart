import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/colors.dart' as cl;
import 'package:ravestreamradioapp/conv.dart';
import 'package:ravestreamradioapp/database.dart' show db;
import 'package:ravestreamradioapp/extensions.dart';
import 'package:ravestreamradioapp/commonwidgets.dart' as cw;

/// The Imprint Screen
class ImPrint extends StatelessWidget {
  const ImPrint({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cl.darkerGrey,
      appBar: AppBar(
        backgroundColor: cl.darkerGrey,
        title: Text("Imprint (DE)"),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width / 50,
          vertical: MediaQuery.of(context).size.height / 50,
        ),
        child: FutureBuilder(
            future: db.doc("content/infostrings").get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: RichText(
                        text: TextSpan(
                            style: TextStyle(color: Colors.white),
                            children: stringToTextSpanList(
                                /*snapshot.data!.data()!["imprintstring"] ??
                                    imprintstring*/
                                    imprintstring
                                    
                                    ))));
              } else {
                return const cw.LoadingIndicator(
                  color: Colors.white
                );
              }
            }),
      ),
    );
  }
}

const imprintstring =
    "Angaben gemäß § 5 TMG\n\nRaveStreamRadio GmbH\n\nGeschäftsführer: Richard Meinl, Antonio Segovia Ricci\n\nBezirksstraße 38b\n\n85761 Unterschleißheim\nE-Mail: Ravestreamradio@web.de\n\nVerantwortlich für den Inhalt nach § 55 Abs. 2 RStV:\nRaveStreamRadio GmbH\n\nGeschäftsführer: Richard Meinl, Antonio Segovia Ricci\n\nBezirksstraße 38b\n\n85761 Unterschleißheim\n\nE-Mail: RavestreamRadio@web.de\n\n\nHaftungsausschluss\n\nHaftung für Inhalte\n\nDie Inhalte unserer Seiten wurden mit größter Sorgfalt erstellt. Für die Richtigkeit, Vollständigkeit und Aktualität der Inhalte können wir jedoch keine Gewähr übernehmen. Als Diensteanbieter sind wir gemäß § 7 Abs.1 TMG für eigene Inhalte auf diesen Seiten nach den allgemeinen Gesetzen verantwortlich. Nach §§ 8 bis 10 TMG sind wir als Diensteanbieter jedoch nicht verpflichtet, übermittelte oder gespeicherte fremde Informationen zu überwachen oder nach Umständen zu forschen, die auf eine rechtswidrige Tätigkeit hinweisen.Verpflichtungen zur Entfernung oder Sperrung der Nutzung von Informationen nach den allgemeinen Gesetzen bleiben hiervon unberührt. Eine diesbezügliche Haftung ist jedoch erst ab dem Zeitpunkt der Kenntnis einer konkreten Rechtsverletzung möglich. Bei Bekanntwerden von entsprechenden Rechtsverletzungen werden wir diese Inhalte umgehend entfernen.\n\nHaftung für Links\n\nUnser Angebot enthält Links zu externen Webseiten Dritter, auf deren Inhalte wir keinen Einfluss haben. Deshalb können wir für diese fremden Inhalte auch keine Gewähr übernehmen. Für die Inhalte der verlinkten Seiten ist stets der jeweilige Anbieter oder Betreiber der Seiten verantwortlich. Die verlinkten Seiten wurden zum Zeitpunkt der Verlinkung auf mögliche Rechtsverstöße überprüft. Rechtswidrige Inhalte waren zum Zeitpunkt der Verlinkung nicht erkennbar. Eine permanente inhaltliche Kontrolle der verlinkten Seiten ist jedoch ohne konkrete Anhaltspunkte einer Rechtsverletzung nicht zumutbar. Bei Bekanntwerden von Rechtsverletzungen werden wir derartige Links umgehend entfernen.\n\nUrheberrecht\n\nDie durch die Seitenbetreiber erstellten Inhalte und Werke auf diesen Seiten unterliegen dem deutschen Urheberrecht. Die Vervielfältigung, Bearbeitung, Verbreitung und jede Art der Verwertung außerhalb der Grenzen des Urheberrechtes bedürfen der schriftlichen Zustimmung des jeweiligen Autors bzw. Erstellers. Downloads und Kopien dieser Seite sind nur für den privaten, nicht kommerziellen Gebrauch gestattet. Soweit die Inhalte auf dieser Seite nicht vom Betreiber erstellt wurden, werden die Urheberrechte Dritter beachtet. Insbesondere werden Inhalte Dritter als solche gekennzeichnet. Sollten Sie trotzdem auf eine Urheberrechtsverletzung aufmerksam werden, bitten wir um einen entsprechenden Hinweis. Bei Bekanntwerden von Rechtsverletzungen werden wir derartige Inhalte umgehend entfernen.";
