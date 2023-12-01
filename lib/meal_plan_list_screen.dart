import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'DatabaseHelper.dart';
import 'MealPlan.dart';
import 'main.dart';

class MealPlanListScreen extends StatefulWidget {
  const MealPlanListScreen({Key? key}) : super(key: key);

  @override
  MealPlanListScreenState createState() => MealPlanListScreenState();
}

class MealPlanListScreenState extends State<MealPlanListScreen> {
  late Future<List<MealPlan>> mealPlans;

  // Method fot initialize the page, fetching the list of meal plans from the database
  @override
  void initState() {
    super.initState();
    mealPlans = DatabaseHelper.instance.getMealPlans();
  }

  // Responsible for the visual layout of the meal plan list page.
  // Shows each entry as sorted in a descending order of the dates,
  // each entry shows the date of meal plan, Target calories and
  // the total calories for the meal plan
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Meal Plans'),
      ),
      body: FutureBuilder<List<MealPlan>>(
        future: mealPlans,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.error != null) {
            return const Center(child: Text('An error occurred'));
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                MealPlan mealPlan = snapshot.data![index];
                String formattedDate = DateFormat('yyyy-MM-dd').format(mealPlan.date);
                int totalCalories = mealPlan.totalCalories;

                return ListTile(
                  title: Text("Meal Plan for $formattedDate"),
                  subtitle: Text("Target Calories: ${mealPlan.targetCalories}\nTotal Meal Plan Calories: $totalCalories"),
                  onTap: () => _showMealPlanOptions(context, mealPlan),
                );
              },
            );
          } else {
            return const Center(child: Text('No meal plans found'));
          }
        },
      ),
    );
  }

  // Responsible for the modal (popup from the bottom) which displays the options
  // to update meal plan and deleting the meal plan
  void _showMealPlanOptions(BuildContext context, MealPlan mealPlan) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 120,
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Update Meal Plan'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MyHomePage(
                            title: 'Update Meal Plan',
                            initialMealPlan: mealPlan,
                          ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Meal Plan'),
                onTap: () async {
                  await DatabaseHelper.instance.deleteSchedule(mealPlan.id);
                  Navigator.pop(context);
                  setState(() {
                    mealPlans = DatabaseHelper.instance.getMealPlans();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}