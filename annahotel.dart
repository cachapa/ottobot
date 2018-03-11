import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'dart:io';

import 'restaurant.dart';

class AnnaHotel extends Restaurant {
  static const NAME = "Anna Hotel";
  static const RESTAURANT_URL =
      "https://www.annahotel.de/en/anna-restaurant.html";

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
    print("--> GET $RESTAURANT_URL");

    var response = await http.get(RESTAURANT_URL);
    print("<-- ${response.statusCode} OK\n");

    var weekdayName = WEEKDAYS[weekday];

    var document = parse(response.body);
    var tags = document.getElementsByClassName("pdf-download");
    var pdfUrl = tags[1].attributes["href"];

    await Process.run("wget", ["-qO", "annahotel.pdf", pdfUrl]);
    var result = await Process
        .run("pdftohtml", ["-noframes", "-i", "-stdout", "annahotel.pdf"]);
    document = parse(result.stdout);
    var nodes = document.body.nodes;
    List<Dish> dishes = new List();
    for (int i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      if (node.text.toLowerCase().startsWith(weekdayName)) {
        var price = "9,50";
        var name = nodes[i + 4].text;
        // Filter out price
        name = name.contains(price) ? name.substring(0, name.indexOf(price)) : name;
        var description = nodes[i + 7].text;

        print(name);

        dishes.add(new Dish(name, description, price));
        break;
      }
    }
    return new Menu(NAME, RESTAURANT_URL, dishes);
  }
}
