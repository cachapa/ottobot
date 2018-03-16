import 'dart:io';

import 'restaurant.dart';

class CafeCord extends Restaurant {
  static const NAME = "Cafe Cord";
  static const RESTAURANT_URL = "https://www.cafe-cord.tv";
  static const MENU_URL = "https://www.cafe-cord.tv/uploads/mittagskarte.pdf?1";

  @override
  getMenu(int weekday) async {
    print("--> GET $MENU_URL");

    await Process.run("wget", ["-qO", "cafecord.pdf", MENU_URL]);
    await Process.run("pdftotext", ["cafecord.pdf"]);
    var result = await Process.run("cat", ["cafecord.txt"]);
    var lines = result.stdout.split("\n");

    // TODO Make sure that we're parsing today's menu

    bool isDishes = false;
    String name = "";
    String description = "";
    List<Dish> dishes = new List();
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty || line.toLowerCase() == "guten appetit") continue;

      if (line.toLowerCase() == "mittagskarte") {
        isDishes = true;
        continue;
      }

      if (isDishes) {
        if (name.isEmpty)
          name = line;
        else if (line.contains("€")) {
          dishes.add(
              new Dish(name, description, line.replaceAll("€", "").trim()));
          name = "";
          description = "";
        } else
          description += (description.isNotEmpty ? " | " : "") + line;
      }
    }
    return new Menu(NAME, RESTAURANT_URL, dishes);
  }
}
