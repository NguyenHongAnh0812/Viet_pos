// import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CategoryCacheService {
  static const String _cacheKey = 'category_cache';
  static const String _cacheTimestampKey = 'category_cache_timestamp';
  static const Duration _cacheExpiry = Duration(minutes: 30);

  // Cache categories
  Future<void> cacheCategories(List<Map<String, dynamic>> categories) async {
    // final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // await prefs.setString(_cacheKey, jsonEncode(categories));
    // await prefs.setInt(_cacheTimestampKey, timestamp);
  }

  // Get cached categories
  Future<List<Map<String, dynamic>>?> getCachedCategories() async {
    // final prefs = await SharedPreferences.getInstance();
    final timestamp = 0; // prefs.getInt(_cacheTimestampKey);
    
    if (timestamp == null) return null;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final age = Duration(milliseconds: now - timestamp);
    
    if (age > _cacheExpiry) {
      await clearCache();
      return null;
    }
    
    final cachedData = null; // prefs.getString(_cacheKey);
    if (cachedData == null) return null;
    
    try {
      final List<dynamic> decoded = jsonDecode(cachedData);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      await clearCache();
      return null;
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.remove(_cacheKey);
    // await prefs.remove(_cacheTimestampKey);
  }

  // Invalidate cache when data changes
  Future<void> invalidateCache() async {
    await clearCache();
  }
}

// Usage in category service
// Comment out or fix ProductCategoryOptimizedService related code
// class ProductCategoryOptimizedService {
//   // Implementation here
// }

// class ProductCategoryOptimized {
//   // Implementation here
// }
