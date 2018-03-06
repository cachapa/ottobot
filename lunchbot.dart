import 'mattermost.dart';

main() async {
  Mattermost mattermost = new Mattermost();
  await mattermost.connect();
  mattermost.post("test", "ottobot online");
}
