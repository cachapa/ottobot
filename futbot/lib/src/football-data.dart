import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'match.dart';

main(List<String> args) async {
  var matches = await new FootbalData("").getMatchesToday();
  matches.forEach((match) => print(match));
}

class FootbalData extends MatchesApi {
  static const MATCHES_URL =
      "https://api.football-data.org/v1/competitions/467/fixtures?timeFrame=n1";

  final Logger log = new Logger('football-data');

  final String _apiKey;

  FootbalData(this._apiKey);

  getMatchesToday() async {
    var matchesMap = (await _get(MATCHES_URL))["fixtures"];

    List<Match> matches = new List();
    matchesMap.forEach((fixture) {
      matches.add(_fromJson(fixture));
    });

    return matches;
  }

  _get(url) async {
    var response =
        await http.get(MATCHES_URL, headers: {"X-Auth-Token": _apiKey});
    if (response.statusCode != 200) {
      log.warning(
          "--> GET $url\n<-- ${response.statusCode} ${response.reasonPhrase} ${response.body.toString()}");
      throw new Exception("Error fetching matches");
    }
    return json.decode(response.body);
  }

  Match _fromJson(map) {
    DateTime date = DateTime.parse(map["date"]);

    String homeTeam = map["homeTeamName"];
    String awayTeam = map["awayTeamName"];

    var result = map["result"];
    int homeResult = result["goalsHomeTeam"];
    int awayResult = result["goalsAwayTeam"];

    Status status;
    switch (map["status"]) {
      case "IN_PLAY":
        status = Status.IN_PLAY;
        break;
      case "FINISHED":
        status = Status.FINISHED;
        break;
      default:
        status = Status.SCHEDULED;
    }

    return new Match(date, homeTeam, homeResult, awayTeam, awayResult, status);
  }

  @override
  Future<Iterable<Player>> getShortLeaderboard() {
    return null;
  }
}
