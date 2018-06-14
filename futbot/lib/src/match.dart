import 'dart:async';

abstract class MatchesApi {
  Future<List<Match>> getMatchesToday();
}

class Match {
  DateTime _date;
  String _homeTeam;
  int _homeResult;
  String _awayTeam;
  int _awayResult;
  Status _status;

  Match(this._date, this._homeTeam, int homeResult, this._awayTeam,
      int awayResult, this._status)
      : _homeResult = homeResult ?? 0,
        _awayResult = awayResult ?? 0;

  get date => _date;
  get status => _status;
  get homeTeam => _homeTeam;
  get homeResult => _homeResult;
  get awayTeam => _awayTeam;
  get awayResult => _awayResult;
  get key => "$_date $_homeTeam $_awayTeam";

  bool operator ==(other) =>
      _date == other.date &&
      _homeTeam == other._homeTeam &&
      _awayTeam == other._awayTeam &&
      _homeResult == other._homeResult &&
      _awayResult == other._awayResult;

  @override
  String toString() {
    return "${_date.toLocal()} $_status $_homeTeam $_homeResult : $_awayResult $_awayTeam";
  }
}

enum Status { SCHEDULED, IN_PLAY, FINISHED }
