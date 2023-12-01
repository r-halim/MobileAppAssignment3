import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'DatabaseHelper.dart';
import 'FoodItems.dart';
import 'meal_plan_list_screen.dart';
import 'MealPlan.dart';

// Main method for initializing the app during startup
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const MyApp());
}

// Initializes the app ensuring the widget bindings are setup
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Calories Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Calories Calculator'),
    );
  }
}

// Setting up a stateful widget (title and meal plan)
class MyHomePage extends StatefulWidget {
  final String title;
  final MealPlan? initialMealPlan;

  const MyHomePage({Key? key, required this.title, this.initialMealPlan}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int? targetCalories;
  DateTime selectedDate = DateTime.now();
  FoodItem? selectedFoodItem;
  List<FoodItem> foodItems = [];
  List<FoodItem> selectedFoodItems = [];
  late TextEditingController targetCaloriesController;

  // Initialize variables and load food items
  @override
  void initState() {
    super.initState();
    _loadFoodItems();

    targetCaloriesController = TextEditingController(
      text: widget.initialMealPlan?.targetCalories?.toString() ?? '',
    );

    if (widget.initialMealPlan != null) {
      selectedDate = widget.initialMealPlan!.date;
      targetCalories = widget.initialMealPlan!.targetCalories;
      selectedFoodItems = List<FoodItem>.from(widget.initialMealPlan!.selectedFoodItems);
    }
  }

  // Disposes of the controllers
  @override
  void dispose() {
    targetCaloriesController.dispose();
    super.dispose();
  }

  // Rests states of variables to initial values (clears them)
  void _resetState() {
    setState(() {
      targetCaloriesController.clear();
      selectedDate = DateTime.now();
      targetCalories = null;
      selectedFoodItems.clear();
      selectedFoodItem = null;
    });
  }

  // Method to calculate the total calories of selected food items
  int get totalMealCalories {
    return selectedFoodItems.fold(0, (sum, item) => sum + item.calories);
  }

  // Method which loads/fetches the food items from the database
  Future<void> _loadFoodItems() async {
    var fetchedFoodItems = await DatabaseHelper.instance.getFoodItems();
    setState(() {
      foodItems = fetchedFoodItems;
    });
  }

  // Method which shows the date picker to select a date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Method which adds the selected food items to the meal plan
  void _addFoodItem() {
    if (selectedFoodItem != null) {
      setState(() {
        selectedFoodItems.add(selectedFoodItem!);
      });
    }
  }

  // Method which validates and saves the meal plan
  void _saveFoodSelection() async {
    if (targetCalories == null || targetCalories! <= 0) {
      _showDialog('Error', 'Please enter a valid target calories amount.');
      return;
    }

    if (selectedFoodItems.isEmpty) {
      _showDialog('Error', 'Please add at least one food item.');
      return;
    }

    int totalCalories = selectedFoodItems.fold(0, (sum, item) => sum + item.calories);
    if (totalCalories > targetCalories!) {
      _showDialog('Error', 'You have exceeded your calorie target. Please adjust your meal plan.');
      return;
    }

    bool isExistingMealPlan = await DatabaseHelper.instance.isMealPlanExistForDate(selectedDate, widget.initialMealPlan?.id);
    if (isExistingMealPlan) {
      _showDialog('Error', 'There is already a meal plan for this date. Please choose another date.');
      return;
    }

    if (widget.initialMealPlan != null) {
      // Update existing meal plan
      await DatabaseHelper.instance.updateSchedule(
        widget.initialMealPlan!.id,
        selectedDate,
        targetCalories!,
        selectedFoodItems,
      );
      _showDialog('Success', 'Your meal plan has been updated successfully.', success: true);
    } else {
      // Create new meal plan
      await DatabaseHelper.instance.addSchedule(
        selectedDate,
        targetCalories!,
        selectedFoodItems,
      );
      _showDialog('Success', 'Your meal plan has been saved successfully.', success: true);
    }
  }

  // Method for showing dialog boxes (pop ups)
  void _showDialog(String title, String content, {bool success = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                if (success && widget.initialMealPlan != null) {
                  // If the operation was successful and this is an update (not the main page),
                  // navigate back to the main page
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  _resetState();
                }
                if (success) {
                  // If the operation was successful, reset the state
                  _resetState();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Defines the User interface and location of fields, buttons, fonts and colors
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: targetCaloriesController,
                decoration: const InputDecoration(
                  labelText: 'Enter your target calories for the day',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  targetCalories = int.tryParse(value);
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: const Text("Select Date"),
              ),
              const SizedBox(height: 10),
              Text("Selected date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
              const SizedBox(height: 10),
              Text("Total Meal Plan Calories: $totalMealCalories cal"),
              const SizedBox(height: 10),
              DropdownButton<FoodItem>(
                isExpanded: true,
                hint: const Text('Select a Food Item'),
                value: selectedFoodItem,
                onChanged: (FoodItem? newValue) {
                  setState(() {
                    selectedFoodItem = newValue;
                  });
                },
                items: foodItems.map<DropdownMenuItem<FoodItem>>((FoodItem item) {
                  return DropdownMenuItem<FoodItem>(
                    value: item,
                    child: Text(item.name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addFoodItem,
                child: const Text('Add Food Item'),
              ),
              const SizedBox(height: 20),
              const Text('Selected Food Items:'),
              Expanded(
                child: ListView.builder(
                  itemCount: selectedFoodItems.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(selectedFoodItems[index].name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${selectedFoodItems[index].calories} cal'),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                selectedFoodItems.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (widget.initialMealPlan == null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MealPlanListScreen()),
                          );
                        },
                        child: const Text('View Meal Plans'),
                      ),
                    ),
                  if (widget.initialMealPlan == null) const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveFoodSelection,
                      child: const Text('Save Selection'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}