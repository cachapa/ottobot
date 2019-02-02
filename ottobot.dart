import 'package:mattermost_dart/mattermost_dart.dart';
import 'package:logging/logging.dart';
import 'config.dart';
import 'lunchbot/lib/lunchbot.dart';
import 'futbot/lib/futbot.dart';

main() async {
  // Initialize logger
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  Mattermost mattermost = new Mattermost.withToken(
      true, MM_URL, MM_USERNAME, MM_ACCESS_TOKEN, MM_TEAM_NAME);

  new LunchBot(mattermost, "lunch-it").listen();
//  new Futbot(mattermost, FD_KEY, KT_KEY, "wm-2018").listen();

  // Notify the maintainer that we're online via direct message
  mattermost.postDirectMessage(MM_MAINTAINER_USERNAME, "ottobot online");
}
