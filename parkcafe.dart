import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

import 'dart:convert';

import 'restaurant.dart';

class ParkCafe extends Restaurant {
  static const NAME = "Park Café";
  static const RESTAURANT_URL = "https://www.parkcafe089.de";
  static const MENU_URL = "https://www.parkcafe089.de/tageskarte";

  var WEEKDAYS = {
    1: "montag",
    2: "dienstag",
    3: "mittwoch",
    4: "donnerstag",
    5: "freitag",
    6: "samstag",
    7: "sonntag",
  };

  @override
  getMenu(int weekday) async {
    print("--> GET $MENU_URL");

    var response = await http.get(MENU_URL);
    print("<-- ${response.statusCode} OK\n");

    var weekdayName = WEEKDAYS[weekday];

    var document = parse(UTF8.decode(response.bodyBytes));
    var tags = document.getElementsByTagName("td");
    List<Dish> dishes = new List();
    for (int i = 0; i < tags.length; i++) {
      var tag = tags[i];
      if (tag.text.trimLeft().toLowerCase().startsWith(weekdayName)) {
        dishes.add(new Dish(
            tags[i + 4].text.trim(), "Mittagsgericht", tags[i + 5].text));
        dishes.add(
            new Dish(
              HTML_ESCAPE.convert(tags[i + 7].text.trim()), "Low Carb", tags[i + 8].text));
        break;
      }
    }
    return new Menu(NAME, RESTAURANT_URL, dishes);
  }
}
