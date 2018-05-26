import 'package:mattermost_dart/mattermost_dart.dart';
import 'lunchbot/lib/lunchbot.dart';
import 'config.dart';

main() async {
  Mattermost mattermost = new Mattermost.withToken(
      true, MM_URL, MM_USERNAME, MM_ACCESS_TOKEN, MM_TEAM_NAME);

  new LunchBot(mattermost).listen();

  // Notify the maintainer that we're online via direct message
  mattermost.postDirectMessage(MM_MAINTAINER_USERNAME, "ottobot online");
}
