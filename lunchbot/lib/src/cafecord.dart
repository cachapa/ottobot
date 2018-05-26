import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

import 'dart:convert';

import 'restaurant.dart';

class CafeCord extends Restaurant {
  static const NAME = "Cafe Cord";
  static const RESTAURANT_URL = "https://www.cafe-cord.tv";
  static const MENU_URL = "https://www.cafe-cord.tv";

  @override
  getMenu(int weekday) async {
    print("--> GET $MENU_URL");

    var response = await http.get(MENU_URL);
    print("<-- ${response.statusCode} OK\n");

    var document = parse(UTF8.decode(response.bodyBytes));
    var tags = document.getElementsByClassName("col-xs-12 col-sm-7");
    var menuTags = tags[0].children;

    List<Dish> dishes = new List();
    for (int i = 1; i < menuTags.length - 1; i++) {
      var tag = menuTags[i];

      var name = tag.firstChild.text;
      var description = tag.nodes[2].text;
      var price = tag.nodes[4].text.replaceAll("EUR ", "");

      dishes.add(new Dish(name, description, price));
    }
    return new Menu(NAME, RESTAURANT_URL, dishes);
  }
}
