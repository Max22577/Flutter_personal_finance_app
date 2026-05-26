import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CurrencyApiService {
  static final String _apiKey = dotenv.env['API_KEY'] ?? '';
  static const String _baseUrl = 'https://v6.exchangerate-api.com/v6';

  Future<Map<String, double>?> fetchLatestRates() async {
    try {
      final url = Uri.parse('$_baseUrl/$_apiKey/latest/USD');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // The API returns 'conversion_rates' as a Map<String, double>
        final Map<String, dynamic> rawRates = data['conversion_rates'];
        
        // Convert to double to ensure type safety
        return rawRates.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
    } catch (e) {
      debugPrint('Error fetching rates: $e');
    }
    return null;
  }
}