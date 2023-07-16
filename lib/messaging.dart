import 'package:ravestreamradioapp/database.dart' as db;
import 'package:cloud_functions/cloud_functions.dart';

Future<dynamic> sendFCMMessageToToken(String token, String content) async {
  HttpsCallable lol = await db.getCallableFunction("testFunction");
  HttpsCallableResult res = await lol.call(["TOKEN"]);
  return res.data;
}
