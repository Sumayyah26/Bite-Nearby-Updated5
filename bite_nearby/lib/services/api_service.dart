import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bite_nearby/screens/models/recipe_recommendation.dart';

class ApiService {
  static const String apiUrl = 'http://<your-local-IP>:8000/recommend';
  static const String apiKey = '192.168.1.34';

  static Future<List<RecipeRecommendation>> fetchRecommendations({
    required List<String> allergies,
    required List<String> preferences,
  }) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      },
      body: jsonEncode({
        'allergies': allergies,
        'preferences': preferences,
      }),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => RecipeRecommendation.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load recommendations: ${response.statusCode}');
    }
  }
}
