import 'dart:async';

import 'mattermost.dart';
import 'restaurant.dart';

import 'annahotel.dart';
import 'cafecord.dart';
import 'parkcafe.dart';

main() async {
  new LunchBot().listen();
}

class LunchBot {
  List<Restaurant> restaurants = [
    new AnnaHotel(),
    new CafeCord(),
    new ParkCafe(),
  ];

  Mattermost _mattermost = new Mattermost();

  listen() async {
    await _mattermost.connect(
        (sender, channelId, message) => _parse(sender, channelId, message));

    // Notify we're online via direct message
    _mattermost.postDirectMessage("daniel.cachapa", "ottobot online");

    // Schedule a post at 11:00 the next day
    _schedulePost();
  }

  _schedulePost() {
    var now = new DateTime.now();
    var then = new DateTime(now.year, now.month, now.day + 1, 11);

    var duration = then.difference(now);
    print("Posting menu in [$duration");
    new Timer(duration, () async {
      print("Posting scheduled menu...");

      // Don't post on the weekend
      if (then.weekday <= 5) {
        _postMenu(await _mattermost.getChannelId("lunch-it"));
      }

      // Schedule another post for tomorrow
      _schedulePost();
    });
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
    var futures = new List();
    restaurants.forEach((r) => futures.add(r.getMenu(weekday)));
    Future.wait(futures).then((menus) {
      List<String> message = new List();
      menus.forEach((menu) => message.add(menu));
      _mattermost.post(channelId, message.join("\n---\n"));
    });
  }

  _postHelp(String channelId) {
    var message = "**Currently available commands are:**\n";
    message += "`lunch` Display lunch menus from restaurants around the area";
    _mattermost.post(channelId, message);
  }

  _postAbout(String channelId) {
    var message = "version `0.1`\n";
    message += "[GitHub](https://github.com/cachapa/lunchbot)";
    _mattermost.post(channelId, message);
  }
}
