import 'dart:math';

import 'mattermost.dart';

main() async {
  new LunchBot().listen();
}

class LunchBot {
  final wut = [
    "wut?",
    "was?",
    "wat?",
    "quê?",
    "wis?",
    "¯\_(ツ)_/¯",
    "?",
    "ja, mei",
    "bast scho"
  ];

  Mattermost _mattermost = new Mattermost();

  listen() async {
    await _mattermost.connect(
        (sender, channelId, message) => _parse(sender, channelId, message));
    // mattermost.post("test", "ottobot online");
  }

  _parse(String sender, String channelId, String message) {
    if (message.contains("help")) {
      _postHelp(channelId);
    } else {
      _postWut(channelId);
    }
  }

  _postHelp(String channelId) {
    _mattermost.post(channelId, "Still assembling...");
  }

  _postWut(String channelId) {
    _mattermost.post(channelId, wut[new Random().nextInt(wut.length)]);
  }
}
