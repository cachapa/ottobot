import 'dart:async';

import 'package:mattermost_dart/mattermost_dart.dart';
import 'restaurant.dart';

import 'annahotel.dart';
import 'cafecord.dart';
import 'parkcafe.dart';

class LunchBot {
  List<Restaurant> restaurants = [
    new AnnaHotel(),
    new CafeCord(),
    new ParkCafe(),
  ];

  Mattermost _mattermost;
  String _channel;

  LunchBot(this._mattermost, this._channel);

  listen() async {
    await _mattermost.listen(
        (sender, channelId, message) => _parse(sender, channelId, message));

    // Schedule a post at 11:00 the next day
    _schedulePost();
  }

  _schedulePost() {
    var duration = _getDurationToTime(11);
    print("Posting menu in $duration");
    new Timer(duration, () async {
      print("Posting scheduled menu...");

      // Don't post on the weekend
      if (new DateTime.now().weekday <= 5) {
        try {
          await _postMenu(await _mattermost.getChannelId(_channel));
        } catch (e) {
          print(e);
        }
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

  _parse(String sender, String channelId, String message) {
    if (message.contains("about")) {
      _postAbout(channelId);
    } else {
      _postMenu(channelId);
    }
  }

  _postMenu(String channelId) async {
    _mattermost.notifyTyping(channelId);

    var weekday = new DateTime.now().weekday;
    var futures = new List<Future<Menu>>();
    restaurants.forEach((r) => futures.add(r.getMenu(weekday)));
    Future.wait(futures).then((menus) {
      var message = new List<Menu>();
      menus.forEach((menu) => message.add(menu));
      _mattermost.post(channelId, message.join("\n---\n"));
    });
  }

  _postHelp(String channelId) {
    var message = "**Currently available commands are:**\n";
    message += "* `lunch` Display lunch menus from nearby restaurants";
    message += "* `about` About ottobot";
    _mattermost.post(channelId, message);
  }

  _postAbout(String channelId) {
    var message = "version `0.1`\n";
    message += "[GitHub](https://github.com/cachapa/ottobot)";
    _mattermost.post(channelId, message);
  }
}
