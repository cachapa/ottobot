import 'dart:async';

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import 'football-data.dart';
import 'kicktipp.dart';
import 'match.dart';

import 'package:mattermost_dart/mattermost_dart.dart';

const UPDATE_INTERVAL = const Duration(seconds: 20);

class Futbot {
  final Mattermost _mattermost;
  final MatchesApi _matchesApi;
  final String _channel;

  final Logger log = new Logger('futbot');

  Futbot(this._mattermost, String fdApiKey, String ktApiKey, this._channel)
      // : _matchesApi = new FootbalData(fdApiKey);
      : _matchesApi = new KickTipp(ktApiKey);

  listen() async {
    Map<String, Match> activeMatches = new Map();

    // Post schedule every morning
    _schedulePost();

    // Seed active match list. This avoids triggering new messages on app restart
    var matches = await _matchesApi.getMatchesToday();
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
        log.warning("_listen: $e");
      }
    }
  }

  _updateMatches(activeMatches) async {
    try {
      var matches = await _matchesApi.getMatchesToday();

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
      log.warning("_updateMatches: $e");
    }
  }

  Future<List<Match>> _getScheduledMatches() async {
    var scheduled = new List<Match>();
    var matches = await _matchesApi.getMatchesToday();
    matches.forEach((match) {
      if (match.status == Status.SCHEDULED) {
        scheduled.add(match);
      }
    });
    return scheduled;
  }

  _schedulePost() async {
    var duration = _getDurationToTime(8);
    log.info("Posting upcoming matches in $duration");
    new Timer(duration, () async {
      log.info("Posting scheduled match...");
      try {
        await _notifyScheduledMatches(await _getScheduledMatches());
      } catch (e) {
        log.warning("_schedulePost: $e");
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
    matches.forEach((match) => post += "${_toSchedule(match)}\n");
    _mattermost.postToChannel(_channel, post);
  }

  _notifyMatchStarted(Match match) {
    _mattermost.postToChannel(_channel, "**Kick-Off**\n$match");
  }

  _notifyGoal(Match match) {
    _mattermost.postToChannel(_channel, match.toString());
  }

  _notifyMatchFinished(Match match) async {
    var leaderboard = await _matchesApi.getShortLeaderboard();
    _mattermost.postToChannel(_channel,
        "**Match Over**\n$match\n\n${_toLeaderboard(leaderboard)}");
  }

  String _toSchedule(Match match) {
    var time = new DateFormat('Hm').format(match.date.toLocal());
    return "`$time` $match";
  }

  String _toLeaderboard(Iterable<Player> leaderboard) {
    if (leaderboard == null || leaderboard.isEmpty) return "";
    return "${leaderboard.join("\n")}\n[more…](https://www.kicktipp.de/ottonova-wm-2018/tippuebersicht)";
  }
}
