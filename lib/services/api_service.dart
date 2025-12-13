import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yurttaye_mobile/models/city.dart';
import 'package:yurttaye_mobile/models/menu.dart';
import 'package:yurttaye_mobile/utils/constants.dart';
import 'package:yurttaye_mobile/utils/app_logger.dart';

class ApiService {
  // Fetch cities from the API
  Future<List<City>> getCities() async {
    final uri = Uri.parse('${Constants.apiUrl}/City');
    AppLogger.api('Fetching cities from: $uri');
    final response = await http.get(
      uri,
      headers: {'x-api-key': Constants.apiKey},
    );
    AppLogger.api('Cities response: status=${response.statusCode}');
    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return await compute(_parseCities, json);
    } else {
      throw Exception('Failed to load cities: ${response.statusCode}');
    }
  }

  // Fetch menus with optional filters and pagination
  Future<List<Menu>> getMenus({
    int? cityId,
    String? mealType,
    String? date,
    int? page,
    int? pageSize,
  }) async {
    final queryParams = <String, String>{};
    if (cityId != null) queryParams['cityId'] = cityId.toString();
    if (mealType != null) queryParams['mealType'] = mealType;
    if (date != null) queryParams['date'] = date;
    if (page != null) queryParams['page'] = page.toString();
    if (pageSize != null) queryParams['pageSize'] = pageSize.toString();

    final uri = Uri.parse('${Constants.apiUrl}/Menu').replace(queryParameters: queryParams);
    AppLogger.api('Fetching menus from: $uri');
    final response = await http.get(
      uri,
      headers: {'x-api-key': Constants.apiKey},
    );
    AppLogger.api('Menus response: status=${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return await compute(_parseMenus, json);
    } else {
      throw Exception('Failed to load menus: ${response.statusCode}');
    }
  }
}

// Isolate functions for parsing JSON data
List<City> _parseCities(List<dynamic> json) {
  return json.map((e) => City.fromJson(e)).toList();
}

List<Menu> _parseMenus(List<dynamic> json) {
  return json.map((e) => Menu.fromJson(e)).toList();
}