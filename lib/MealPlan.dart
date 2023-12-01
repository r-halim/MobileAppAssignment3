import 'FoodItems.dart';

class MealPlan {
  final int id;
  final DateTime date;
  final int targetCalories;
  final List<FoodItem> selectedFoodItems;

  // Helps create the instance of the meal plan
  MealPlan({required this.id, required this.date, required this.targetCalories, required this.selectedFoodItems});

  // Helps calculate the total calories for a meal plan
  int get totalCalories {
    return selectedFoodItems.fold(0, (sum, item) => sum + item.calories);
  }
}