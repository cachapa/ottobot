abstract class Restaurant {
  getMenu(int weekday);
}

class Dish {
  final String name;
  final String description;
  final String price;

  Dish(this.name, this.description, this.price);

  String toString() {
    return "**${name.trim()}**\n_${description.trim()}_ `${price.trim()} €`";
  }
}

class Menu {
  final String restaurantName;
  final String restaurantUrl;
  final List<Dish> dishes;

  Menu(this.restaurantName, this.restaurantUrl, this.dishes);

  String toString() {
    var string = "##### [$restaurantName]($restaurantUrl)\n";
    if (dishes.isNotEmpty) {
      dishes.forEach((dish) => string += "$dish\n");
    } else {
      string += "_No lunch menu today_\n";
    }
    return string;
  }
}
