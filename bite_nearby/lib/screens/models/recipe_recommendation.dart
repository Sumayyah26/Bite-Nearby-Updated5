class RecipeRecommendation {
  final String name;
  final String cuisine;
  final String cookTime;
  final List<String> mainIngredients;
  final String instructions;
  final double similarityScore;
  final String imageUrl;
  RecipeRecommendation(
      {required this.name,
      required this.cuisine,
      required this.cookTime,
      required this.mainIngredients,
      required this.instructions,
      required this.similarityScore,
      required this.imageUrl});

  factory RecipeRecommendation.fromJson(Map<String, dynamic> json) {
    return RecipeRecommendation(
      name: json['name'],
      cuisine: json['cuisine'],
      cookTime: json['cook_time'],
      mainIngredients: List<String>.from(json['main_ingredients']),
      instructions: json['instructions'],
      similarityScore: (json['similarity_score'] as num).toDouble(),
      imageUrl: json['image_url'] ?? '',
    );
  }
}
