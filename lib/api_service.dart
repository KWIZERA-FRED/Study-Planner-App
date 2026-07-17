import 'dart:convert';
import 'package:http/http.dart' as http;

// Talks to the Flask + MySQL backend instead of a local sqflite database.
class ApiService {
  // Android emulator (AVD) talking to Flask running on your own machine.
  // Use http://localhost:5000 for iOS simulator/desktop/web,
  // or your computer's LAN IP for a physical phone.
  static const String baseUrl = 'http://10.0.2.2:5000';

  static Future<List<Map<String, dynamic>>> fetchGoals() async {
    final response = await http.get(Uri.parse('$baseUrl/goals'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load goals (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> createGoal(
    String subject,
    int hours,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/goals'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'subject': subject, 'hours': hours}),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create goal (${response.statusCode})');
  }

  static Future<void> updateGoal(
    int id, {
    bool? done,
    String? subject,
    int? hours,
  }) async {
    final body = <String, dynamic>{};
    if (done != null) body['done'] = done;
    if (subject != null) body['subject'] = subject;
    if (hours != null) body['hours'] = hours;

    final response = await http.put(
      Uri.parse('$baseUrl/goals/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update goal (${response.statusCode})');
    }
  }

  static Future<void> deleteGoal(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/goals/$id'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete goal (${response.statusCode})');
    }
  }
}
