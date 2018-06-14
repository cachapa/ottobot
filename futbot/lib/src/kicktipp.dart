import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import 'dart:async';
import 'dart:convert';

import 'match.dart';

main(List<String> args) async {
  var matches = await new KickTipp().getMatchesToday();
  matches.forEach((match) => print(match));
}

class KickTipp extends MatchesApi {
  static const MATCHES_URL =
      "https://www.kicktipp.de/wm18-tippspiel/tippspielplan";

  final Logger log = new Logger('kicktipp');

  DateFormat format = new DateFormat("dd.MM.y HH:mm");

  Future<List<Match>> getMatches() async {
    var response = await http.get(MATCHES_URL);
    if (response.statusCode != 200) {
      log.warning(
          "--> GET $MATCHES_URL\n<-- ${response.statusCode} ${response.reasonPhrase} ${response.body.toString()}");
      throw new Exception("Error fetching matches");
    }

    var document = parse(utf8.decode(response.bodyBytes));
    var table = document.getElementsByTagName("tbody");
    var rows = table[0].children;

    List<Match> matches = new List();
    rows.forEach((row) {
      DateTime date =
          format.parse(row.children[0].text.replaceAll(".18", ".2018"));
      String homeTeam = row.children[2].text;
      String awayTeam = row.children[3].text;

      // Result and status child
      var resultChild = row.children[5].firstChild.firstChild;
      int homeResult = int.tryParse(resultChild.children[0].text);
      int awayResult = int.tryParse(resultChild.children[2].text);

      Status status;
      if (homeResult == null) {
        status = Status.SCHEDULED;
      } else if (resultChild.attributes["class"].contains("abpfiff")) {
        status = Status.FINISHED;
      } else {
        status = Status.IN_PLAY;
      }

      matches.add(new Match(date, _TEAM_TRANSLATION[homeTeam], homeResult,
          _TEAM_TRANSLATION[awayTeam], awayResult, status));
    });

    return matches;
  }

  @override
  getMatchesToday() async {
    List<Match> matches = await getMatches();
    DateTime today = new DateTime.now();
    matches.retainWhere((match) =>
        match.date.year == today.year &&
        match.date.month == today.month &&
        match.date.day == today.day);
    return matches;
  }
}

const Map<String, String> _TEAM_TRANSLATION = const {
  "Argentinien": "Argentina",
  "Australien": "Australia",
  "Belgien": "Belgium",
  "Brasilien": "Brazil",
  "Kolumbien": "Colombia",
  "Costa Rica": "Costa Rica",
  "Kroatien": "Croatia",
  "Dänemark": "Denmark",
  "Ägypten": "Egypt",
  "England": "England",
  "Frankreich": "France",
  "Deutschland": "Germany",
  "Island": "Iceland",
  "Iran": "Iran",
  "Japan": "Japan",
  "Südkorea": "Korea Republic",
  "Mexiko": "Mexico",
  "Marokko": "Morocco",
  "Nigeria": "Nigeria",
  "Panama": "Panama",
  "Peru": "Peru",
  "Polen": "Poland",
  "Portugal": "Portugal",
  "Russland": "Russia",
  "Saudi-Arabien": "Saudi Arabia",
  "Senegal": "Senegal",
  "Serbien": "Serbia",
  "Spanien": "Spain",
  "Schweden": "Sweden",
  "Schweiz": "Switzerland",
  "Tunesien": "Tunisia",
  "Uruguay": "Uruguay",
};
