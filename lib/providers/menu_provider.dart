import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yurttaye_mobile/models/city.dart';
import 'package:yurttaye_mobile/models/menu.dart';
import 'package:yurttaye_mobile/services/api_service.dart';
import 'package:yurttaye_mobile/services/notification_service.dart';
import 'package:yurttaye_mobile/utils/app_config.dart';
import 'package:yurttaye_mobile/utils/app_logger.dart';

class MenuProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  List<City> _cities = [];
  List<Menu> _menus = []; // Filtered menus
  List<Menu> _allMenus = []; // Unfiltered menus for HomeScreen
  int? _selectedCityId;
  String? _selectedMealType;
  String? _selectedDate;
  int _selectedMealIndex = 0;
  bool _isLoading = false;
  String? _error;
  int _page = AppConfig.initialPage;
  final int _pageSize = AppConfig.pageSize;
  bool _hasMore = true;

  List<City> get cities => _cities;
  List<Menu> get menus => _menus;
  List<Menu> get allMenus => _allMenus;
  int? get selectedCityId => _selectedCityId;
  String? get selectedMealType => _selectedMealType;
  String? get selectedDate => _selectedDate;
  int get selectedMealIndex => _selectedMealIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchCities() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedCities = prefs.getString('cities');

    if (cachedCities != null) {
      try {
        final List<dynamic> json = jsonDecode(cachedCities);
        _cities = await compute(_parseCities, json);
        AppLogger.info('Cities loaded from cache: ${_cities.length} items');
        notifyListeners();
        return;
      } catch (e) {
        AppLogger.error('Error parsing cached cities', e);
      }
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      _cities = await _apiService.getCities().timeout(const Duration(seconds: 10));
      AppLogger.info('Cities fetched: ${_cities.length} items');
      await prefs.setString('cities', jsonEncode(_cities.map((c) => c.toJson()).toList()));
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Error fetching cities', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMenus({bool reset = false, bool initialLoad = false}) async {
    // Prevent multiple simultaneous calls
    if (_isLoading) {
      AppLogger.debug('Fetch already in progress, skipping...');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (reset || initialLoad) {
      _page = AppConfig.initialPage;
      _menus = [];
      _allMenus = [];
      _hasMore = true;
    }

    // Try loading cached menus for initial load
    if (initialLoad && prefs.getString('menus') != null) {
      try {
        final List<dynamic> json = jsonDecode(prefs.getString('menus')!);
        _menus = await compute(_parseMenus, json);
        _allMenus = List.from(_menus);
        AppLogger.info('Menus loaded from cache: ${_menus.length} items');
        notifyListeners();
        return;
      } catch (e) {
        AppLogger.error('Error parsing cached menus', e);
      }
    }

    if (!_hasMore && !reset && !initialLoad) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Fetch all menus for HomeScreen (unfiltered)
      final allMenus = await _apiService.getMenus().timeout(const Duration(seconds: 10));
      AppLogger.info('All menus fetched: ${allMenus.length} items');
      
      // Remove duplicates based on menu ID
      final uniqueMenus = <Menu>[];
      final seenIds = <int>{};
      
      for (final menu in allMenus) {
        if (!seenIds.contains(menu.id)) {
          seenIds.add(menu.id);
          uniqueMenus.add(menu);
        }
      }
      
      AppLogger.debug('Unique menus after deduplication: ${uniqueMenus.length} items');
      
      if (reset || initialLoad) {
        _allMenus = uniqueMenus;
      } else {
        // Merge with existing menus, avoiding duplicates
        final existingIds = _allMenus.map((m) => m.id).toSet();
        final newMenus = uniqueMenus.where((menu) => !existingIds.contains(menu.id)).toList();
        _allMenus = [..._allMenus, ...newMenus];
      }

      // Filter menus based on current selection
      final filteredMenus = _allMenus.where((menu) {
        bool matchesCity = _selectedCityId == null || menu.cityId == _selectedCityId;
        bool matchesMealType = _selectedMealType == null || menu.mealType == _selectedMealType;
        bool matchesDate = _selectedDate == null || AppConfig.apiDateFormat.format(menu.date) == _selectedDate;
        return matchesCity && matchesMealType && matchesDate;
      }).toList();

      if (reset || initialLoad) {
        _menus = filteredMenus;
      } else {
        // Merge filtered menus, avoiding duplicates
        final existingFilteredIds = _menus.map((m) => m.id).toSet();
        final newFilteredMenus = filteredMenus.where((menu) => !existingFilteredIds.contains(menu.id)).toList();
        _menus = [..._menus, ...newFilteredMenus];
      }

      // Cache menus
      await prefs.setString('menus', jsonEncode(_allMenus.map((m) => m.toJson()).toList()));
      AppLogger.info('Menus cached: ${_allMenus.length} items');

      // Schedule notifications for today
      await _scheduleNotificationsForToday();

    } catch (e) {
      _error = e.toString();
      _hasMore = false;
      AppLogger.error('Error fetching menus', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _scheduleNotificationsForToday() async {
    try {
      final notificationsEnabled = await _notificationService.areNotificationsEnabled();
      if (notificationsEnabled && _allMenus.isNotEmpty) {
        await _notificationService.scheduleDailyMealNotifications(_allMenus);
        AppLogger.notification('Daily meal notifications scheduled');
      }
    } catch (e) {
      AppLogger.error('Notification scheduling error', e);
    }
  }

  void setSelectedCity(int? cityId) {
    _selectedCityId = cityId;
    AppLogger.debug('Setting cityId: $cityId');
    fetchMenus(reset: true);
  }

  void setSelectedMealType(String? mealType) {
    if (mealType != null && !AppConfig.mealTypes.contains(mealType)) {
      AppLogger.warning('Invalid mealType: $mealType');
      return;
    }
    _selectedMealType = mealType;
    AppLogger.debug('Setting mealType: $mealType');
    fetchMenus(reset: true);
  }

  void setSelectedDate(String? date) {
    _selectedDate = date;
    AppLogger.debug('Setting date: $date');
    fetchMenus(reset: true);
  }

  void setSelectedMealIndex(int index) {
    _selectedMealIndex = index;
    AppLogger.debug('Setting meal index: $index');
  }

  void clearFilters() {
    _selectedCityId = null;
    _selectedMealType = null;
    _selectedDate = null;
    AppLogger.debug('Clearing filters');
    fetchMenus(reset: true);
  }

  List<Menu> getUpcomingMeals(DateTime selectedDate) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    
    return _allMenus
        .where((menu) =>
            menu.date.isAfter(todayOnly) && 
            menu.mealType == AppConfig.mealTypes[_selectedMealIndex])
        .take(3)
        .toList();
  }
}

// Isolate functions for parsing JSON data
List<City> _parseCities(List<dynamic> json) {
  return json.map((e) => City.fromJson(e)).toList();
}

List<Menu> _parseMenus(List<dynamic> json) {
  return json.map((e) => Menu.fromJson(e)).toList();
}
