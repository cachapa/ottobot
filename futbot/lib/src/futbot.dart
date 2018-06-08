import 'dart:async';
import 'dart:io';

import 'football-data.dart';
import 'package:mattermost_dart/mattermost_dart.dart';

const UPDATE_INTERVAL = const Duration(seconds: 20);

class Futbot {
  final Mattermost _mattermost;
  final FootbalData _footballData;
  final String _channel;

  Futbot(this._mattermost, String fdApiKey, this._channel)
      : _footballData = new FootbalData(fdApiKey);

  listen() async {
    Map<String, Match> activeMatches = new Map();

    // Post schedule every morning
    _schedulePost();

    // Seed active match list. This avoids triggering new messages on app restart
    var matches = await _footballData.getMatchesToday();
    matches.forEach((match) {
      if (match.status == Status.IN_PLAY) {
        activeMatches[match.key] = match;
      }
    });

    while (true) {
      await new Future.delayed(UPDATE_INTERVAL);
      try {
        await _updateMatches(activeMatches);
      } catch (e) {
        print(e);
      }
    }
  }

  _updateMatches(activeMatches) async {
    try {
      var matches = await _footballData.getMatchesToday();

      matches.forEach((match) {
        switch (match.status) {
          case Status.IN_PLAY:
            // Check if match was already active
            if (activeMatches.containsKey(match.key)) {
              // Check if result changed
              if (activeMatches[match.key] != match) {
                _notifyGoal(match);
              }
            } else {
              _notifyMatchStarted(match);
            }
            // Update match object
            activeMatches[match.key] = match;
            break;

          case Status.FINISHED:
            // Check if the match was active
            if (activeMatches.containsKey(match.key)) {
              // Remove and notify match finished
              activeMatches.remove(match.key);
              _notifyMatchFinished(match);
            }
            break;
        }
      });
    } catch (e) {
      print(e);
    }
  }

  Future<List<Match>> _getScheduledMatches() async {
    var scheduled = new List<Match>();
    var matches = await _footballData.getMatchesToday();
    matches.forEach((Match match) {
      if (match.status == Status.SCHEDULED || match.status == Status.TIMED) {
        scheduled.add(match);
      }
    });
    return scheduled;
  }

  _schedulePost() async {
    var duration = _getDurationToTime(8);
    new Timer(duration, () async {
      print("Posting scheduled match...");
      try {
        await _notifyScheduledMatches(await _getScheduledMatches());
      } catch (e) {
        print(e);
      }
      // Schedule another post for tomorrow
      _schedulePost();
    });
  }

  Duration _getDurationToTime(int hour) {
    var now = new DateTime.now();
    var future = new DateTime(now.year, now.month, now.day, hour);
    if (now.isAfter(future)) future = future.add(new Duration(days: 1));
    return future.difference(now);
  }

  _notifyScheduledMatches(List<Match> matches) {
    if (matches.isEmpty) return;
    var post = "**Matches Today:**\n";
    matches.forEach((match) => post += "* ${_toSchedule(match)}\n");
    _mattermost.postToChannel(_channel, post);
  }

  _notifyMatchStarted(Match match) {
    _mattermost.postToChannel(_channel, "`Kick-Off` ${_toResult(match)}");
  }

  _notifyGoal(Match match) {
    _mattermost.postToChannel(_channel, _toResult(match));
  }

  _notifyMatchFinished(Match match) {
    _mattermost.postToChannel(_channel, "`Match Over` ${_toResult(match)}");
  }

  String _toSchedule(Match match) {
    return "`${match.date.hour}:${match.date.minute}` ${_toResult(match)}";
  }

  String _toResult(Match match) {
    var middle =
        (match.status == Status.IN_PLAY || match.status == Status.FINISHED)
            ? "`${match.homeResult} : ${match.awayResult}`"
            : "x";
    return "${_TEAM_FLAG[match.homeTeam]??"🏳️"} **${match.homeTeam}** $middle **${match.awayTeam}** ${_TEAM_FLAG[match.awayTeam]??"🏳️"}";
  }
}

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
