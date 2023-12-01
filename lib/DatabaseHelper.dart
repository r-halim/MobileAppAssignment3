import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'dart:io';
import 'FoodItems.dart';
import 'MealPlan.dart';

class DatabaseHelper {
  // Defines and initializes the database and the tables (foodITems and mealPlans tables)
  static const _dbName = 'caloriesCalculator.db';
  static const _dbVersion = 4;
  static const _foodItemsTable = 'foodItems';
  static const _mealPlanTable = 'mealPlans';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = '${directory.path}/$_dbName';
    return await openDatabase(path, version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // CRUD Operations/methods below
  // Logic to handle upgrading the database by resetting it
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Drop all tables
    await db.execute("DROP TABLE IF EXISTS $_foodItemsTable");
    await db.execute("DROP TABLE IF EXISTS $_mealPlanTable");

    _onCreate(db, newVersion);
  }
  
  // Method for creating the two tables used when the database is first setup
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_foodItemsTable (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        calories INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_mealPlanTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        targetCalories INTEGER NOT NULL,
        selectedFoodItems TEXT NOT NULL
      )
    ''');

    await _insertInitialFoodItems(db);
  }

  // List of food items which is pulled from when tables are created
  Future _insertInitialFoodItems(Database db) async {
    List<Map<String, dynamic>> initialFoodItems = [
      {'id': 1, 'name': 'Apple', 'calories': 59},
      {'id': 2, 'name': 'Banana', 'calories': 151},
      {'id': 3, 'name': 'Orange', 'calories': 53},
      {'id': 4, 'name': 'Asparagus', 'calories': 27},
      {'id': 5, 'name': 'Broccoli', 'calories': 45},
      {'id': 6, 'name': 'Carrots', 'calories': 50},
      {'id': 7, 'name': 'Cucumber', 'calories': 17},
      {'id': 8, 'name': 'Eggplant', 'calories': 35},
      {'id': 9, 'name': 'Lettuce', 'calories': 5},
      {'id': 10, 'name': 'Tomato', 'calories': 22},
      {'id': 11, 'name': 'Chicken', 'calories': 136},
      {'id': 12, 'name': 'Tofu', 'calories': 86},
      {'id': 13, 'name': 'Egg', 'calories': 78},
      {'id': 14, 'name': 'Caesar salad', 'calories': 481},
      {'id': 15, 'name': 'Cheeseburger', 'calories': 285},
      {'id': 16, 'name': 'Hamburger', 'calories': 250},
      {'id': 17, 'name': 'Dark Chocolate', 'calories': 155},
      {'id': 18, 'name': 'Corn', 'calories': 132},
      {'id': 19, 'name': 'Pizza', 'calories': 285},
      {'id': 20, 'name': 'Potato', 'calories': 130},
      {'id': 21, 'name': 'Rice', 'calories': 206},
      {'id': 22, 'name': 'Sandwich', 'calories': 200},
      {'id': 23, 'name': 'Beer', 'calories': 154},
      {'id': 24, 'name': 'Coca-Cola Classic', 'calories': 150},
      {'id': 25, 'name': 'Diet Coke', 'calories': 0},
      {'id': 26, 'name': 'Milk (1%)', 'calories': 102},
      {'id': 27, 'name': 'Milk (2%)', 'calories': 122},
      {'id': 28, 'name': 'Milk (Whole)', 'calories': 146},
      {'id': 29, 'name': 'Orange Juice', 'calories': 111},
      {'id': 30, 'name': 'Apple cider', 'calories': 117},
      {'id': 31, 'name': 'Yogurt (low-fat)', 'calories': 154},
      {'id': 32, 'name': 'Yogurt (non-fat)', 'calories': 110},
    ];

    for (var item in initialFoodItems) {
      await db.insert(_foodItemsTable, item);
    }
  }

  // Add a new schedule to the database
  Future<int> addSchedule(DateTime date, int targetCalories, List<FoodItem> selectedFoodItems) async {
    Database db = await database;
    String foodItemsJson = jsonEncode(selectedFoodItems.map((item) => item.toMap()).toList());

    return await db.insert(_mealPlanTable, {
      'date': date.toIso8601String(),
      'targetCalories': targetCalories,
      'selectedFoodItems': foodItemsJson
    });
  }

  // Update an existing meal plan schedule
  Future<int> updateSchedule(int id, DateTime date, int targetCalories, List<FoodItem> selectedFoodItems) async {
    Database db = await database;
    String foodItemsJson = jsonEncode(selectedFoodItems.map((item) => item.toMap()).toList());

    return await db.update(
        _mealPlanTable,
        {
          'date': date.toIso8601String(),
          'targetCalories': targetCalories,
          'selectedFoodItems': foodItemsJson
        },
        where: 'id = ?',
        whereArgs: [id]
    );
  }

  // Delete a meal plan schedule
  Future<int> deleteSchedule(int id) async {
    Database db = await database;
    return await db.delete(
        _mealPlanTable,
        where: 'id = ?',
        whereArgs: [id]
    );
  }

  // Get all food items from the database
  Future<List<FoodItem>> getFoodItems() async {
    Database db = await database;
    var foodItems = await db.query('foodItems');
    return List.generate(foodItems.length, (i) {
      return FoodItem(
        id: foodItems[i]['id'] as int,
        name: foodItems[i]['name'] as String,
        calories: foodItems[i]['calories'] as int,
      );
    });
  }

  // Method to fetch all meal plans
  Future<List<MealPlan>> getMealPlans() async {
    Database db = await database;
    var mealPlansData = await db.query(
        _mealPlanTable,
        orderBy: 'date DESC'
    );

    List<MealPlan> mealPlans = [];
    for (var mealPlanData in mealPlansData) {
      String selectedFoodItemsJson = mealPlanData['selectedFoodItems'] as String;
      List<FoodItem> foodItems = (jsonDecode(selectedFoodItemsJson) as List)
          .map((item) => FoodItem.fromMap(Map<String, dynamic>.from(item)))
          .toList();

      MealPlan mealPlan = MealPlan(
        id: mealPlanData['id'] as int,
        date: DateTime.parse(mealPlanData['date'] as String),
        targetCalories: mealPlanData['targetCalories'] as int,
        selectedFoodItems: foodItems,
      );
      mealPlans.add(mealPlan);
    }

    return mealPlans;
  }

  // Method to check if their is already a meal plan for that day
  Future<bool> isMealPlanExistForDate(DateTime date, int? excludingId) async {
    Database db = await database;
    List<Map> result = await db.query(
      _mealPlanTable,
      where: 'date = ? AND id != ?',
      whereArgs: [date.toIso8601String(), excludingId ?? -1],
    );
    return result.isNotEmpty;
  }

}