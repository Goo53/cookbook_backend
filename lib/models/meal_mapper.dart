import 'meal.dart';
//import 'package:cookbook_backend/db.dart';

Meal mapRowToMeal(Map<String, dynamic> row) {
  Complexity parseComplexity(String value) {
    return Complexity.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase().trim(),
      orElse: () => Complexity.simple,
    );
  }

  Affordability parseAffordability(String value) {
    return Affordability.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase().trim(),
      orElse: () => Affordability.affordable,
    );
  }

  return Meal(
    id: row['id'] ?? '',
    categories: (row['categories'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
    title: row['title'] ?? '',
    imageUrl: row['image_url'] ?? '',
    ingredients: (row['ingredients'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
    steps: (row['steps'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
    duration: row['duration'] is int
        ? row['duration']
        : int.tryParse(row['duration'].toString()) ?? 0,
    complexity: parseComplexity((row['complexity'] ?? '').toString()),
    affordability: parseAffordability((row['affordability'] ?? '').toString()),
    isMeat: row['is_meat'] ?? false,
    isVegetarian: row['is_vegetarian'] ?? false,
  );
}

Map<String, dynamic> mealToJson(Meal meal) => {
  'id': meal.id,
  'categories': meal.categories,
  'title': meal.title,
  'imageUrl': meal.imageUrl,
  'ingredients': meal.ingredients,
  'steps': meal.steps,
  'duration': meal.duration,
  'complexity': meal.complexity.name,
  'affordability': meal.affordability.name,
  'isMeat': meal.isMeat,
  'isVegetarian': meal.isVegetarian,
};
