class FoodItem {
  final int id;
  final String name;
  final int calories;

  // Defines the fields for creating an instance of the food item
  FoodItem({required this.id, required this.name, required this.calories});

  // Uses a map fetched from the database, creating an instance of the food item
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      name: map['name'],
      calories: map['calories'],
    );
  }

  // Method which converts the food item back to a map to store on the database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
    };
  }
}

