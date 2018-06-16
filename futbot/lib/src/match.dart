import 'dart:async';

abstract class MatchesApi {
  Future<List<Match>> getMatchesToday();
  Future<Iterable<Player>> getShortLeaderboard();
}

class Match {
  final DateTime date;
  final String homeTeam;
  final int homeResult;
  final String awayTeam;
  final int awayResult;
  final Status status;
  final String key;

  Match(this.date, this.homeTeam, int homeResult, this.awayTeam, int awayResult,
      this.status)
      : this.homeResult = homeResult ?? 0,
        this.awayResult = awayResult ?? 0,
        this.key = "$date $homeTeam $awayTeam";

  bool operator ==(other) =>
      date == other.date &&
      homeTeam == other.homeTeam &&
      awayTeam == other.awayTeam &&
      homeResult == other.homeResult &&
      awayResult == other.awayResult;

  @override
  String toString() {
    var middle = (status == Status.IN_PLAY || status == Status.FINISHED)
        ? "`${homeResult} : ${awayResult}`"
        : "x";
    return "${_TEAM_FLAG[homeTeam]??"🏳️"} **${homeTeam}** $middle **${awayTeam}** ${_TEAM_FLAG[awayTeam]??"🏳️"}";
  }
}

class Player {
  final int position;
  final String name;
  final int points;

  Player(this.position, this.name, this.points);

  @override
  String toString() {
    String emojiPosition = position == 1 ? "🥇" : position == 2 ? "🥈" : position == 3 ? "🥉" : position;
    return "$emojiPosition `${points}` **${name}**";
  }
}

enum Status { SCHEDULED, IN_PLAY, FINISHED }

const Map<String, String> _TEAM_FLAG = const {
  "Argentina": "🇦🇷",
  "Australia": "🇦🇺",
  "Belgium": "🇧🇪",
  "Brazil": "🇧🇷",
  "Colombia": "🇨🇴",
  "Costa Rica": "🇨🇷",
  "Croatia": "🇭🇷",
  "Denmark": "🇩🇰",
  "Egypt": "🇪🇬",
  "England": "🏴󠁧󠁢󠁥󠁮󠁧󠁿",
  "France": "🇫🇷",
  "Germany": "🇩🇪",
  "Iceland": "🇮🇸",
  "Iran": "🇮🇷",
  "Japan": "🇯🇵",
  "Korea Republic": "🇰🇷",
  "South Korea": "🇰🇷",
  "Mexico": "🇲🇽",
  "Morocco": "🇲🇦",
  "Nigeria": "🇳🇬",
  "Panama": "🇵🇦",
  "Peru": "🇵🇪",
  "Poland": "🇵🇱",
  "Portugal": "🇵🇹",
  "Russia": "🇷🇺",
  "Saudi Arabia": "🇸🇦",
  "Senegal": "🇸🇳",
  "Serbia": "🇷🇸",
  "Spain": "🇪🇸",
  "Sweden": "🇸🇪",
  "Switzerland": "🇨🇭",
  "Tunisia": "🇹🇳",
  "Uruguay": "🇺🇾",
};
