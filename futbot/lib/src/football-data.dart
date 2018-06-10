import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class FootbalData {
  static const MATCHES_URL =
      "http://api.football-data.org/v1/competitions/467/fixtures?timeFrame=n1";

  final Logger log = new Logger('football-data');

  final String _apiKey;

  FootbalData(this._apiKey);

  Future<List<Match>> getMatchesToday() async {
    var matchesMap = (await _get(MATCHES_URL))["fixtures"];

    List<Match> matches = new List();
    matchesMap.forEach((fixture) {
      matches.add(new Match.fromJson(fixture));
    });

    return matches;
  }

  _get(url) async {
    var response =
        await http.get(MATCHES_URL, headers: {"X-Auth-Token": _apiKey});
    if (response.statusCode != 200) {
      log.warning(
          "--> GET $url\n<-- ${response.statusCode} ${response.reasonPhrase}");
    }
    return json.decode(response.body);
  }
}

class Match {
  DateTime _date;
  Status _status;
  String _homeTeam;
  int _homeResult;
  String _awayTeam;
  int _awayResult;

  Match.fromJson(map) {
    _date = DateTime.parse(map["date"]);
    _status = _stringToStatus(map["status"]);

    _homeTeam = map["homeTeamName"];
    _awayTeam = map["awayTeamName"];

    var result = map["result"];
    _homeResult = result["goalsHomeTeam"] ?? 0;
    _awayResult = result["goalsAwayTeam"] ?? 0;
  }

  get date => _date;
  get status => _status;
  get homeTeam => _homeTeam;
  get homeResult => _homeResult;
  get awayTeam => awayTeam;
  get awayResult => _awayResult;
  get key => "$_date $_homeTeam $_awayTeam";

  bool operator ==(Match other) =>
      _date == other.date &&
      _homeTeam == other._homeTeam &&
      _awayTeam == other._awayTeam &&
      _homeResult == other._homeResult &&
      _awayResult == other._awayResult;

  @override
  String toString() {
    return "$_date $_status $_homeTeam $_homeResult : $_awayResult $_awayTeam";
  }

  Status _stringToStatus(String string) {
    for (Status status in Status.values) {
      if (status.toString() == "Status.$string") return status;
    }
    return Status.UNKNOWN;
  }
}

enum Status {
  SCHEDULED,
  TIMED,
  IN_PLAY,
  POSTPONED,
  CANCELED,
  FINISHED,
  UNKNOWN
}
