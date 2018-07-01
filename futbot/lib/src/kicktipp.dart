import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import 'dart:async';
import 'dart:convert';

import 'match.dart';

main(List<String> args) async {
  var kicktipp = new KickTipp("");

  // var matches = await kicktipp.getMatchesToday();
  // print(matches.join("\n"));
  
  // var players = kicktipp.getShortLeaderboard();
  // print(players.join("\n"));
}

class KickTipp extends MatchesApi {
  static const MATCHES_URL =
      "https://www.kicktipp.de/wm18-tippspiel/tippspielplan?&spieltagIndex";
  static const LEADERBOARD_URL =
      "https://www.kicktipp.de/ottonova-wm-2018/tippuebersicht";

  final Logger log = new Logger('kicktipp');

  final DateFormat format = new DateFormat("dd.MM.y HH:mm");

  final String _apiKey;

  KickTipp(this._apiKey);

  @override
  Future<Iterable<Player>> getShortLeaderboard() async {
    return (await getLeaderboard()).takeWhile((player) => player.position <= 3);
  }

  Future<List<Player>> getLeaderboard() async {
    var response =
        await http.get(LEADERBOARD_URL, headers: {"cookie": "login=$_apiKey"});
    if (response.statusCode != 200) {
      log.warning(
          "--> GET ${response.request}\n<-- ${response.statusCode} ${response.reasonPhrase} ${response.body.toString()}");
      throw new Exception("Error fetching leaderboard");
    }

    var document = parse(utf8.decode(response.bodyBytes));
    var table = document.getElementsByTagName("tbody");
    var rows = table[1].children;

    List<Player> players = new List();
    rows.forEach((row) {
      int position = int.tryParse(row.children[0].text);
      String name = row.children[2].firstChild.text;
      int points = int.tryParse(row.children[row.children.length - 1].text);

      players.add(new Player(position, name, points));
    });

    return players;
  }

  Future<List<Match>> getMatches() async {
    var response = await http.get(MATCHES_URL);
    if (response.statusCode != 200) {
      log.warning(
          "--> GET ${response.request}\n<-- ${response.statusCode} ${response.reasonPhrase} ${response.body.toString()}");
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
      var resultChild = row.children[4].firstChild.firstChild;
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
  "Südkorea": "South Korea",
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
