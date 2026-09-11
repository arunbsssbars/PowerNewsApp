import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _prefCityKey = 'user_preferred_city';

  static const Map<String, String> _cityMapping = {
    'delhi': 'Delhi / NCR',
    'new delhi': 'Delhi / NCR',
    'noida': 'Delhi / NCR',
    'gurugram': 'Delhi / NCR',
    'gurgaon': 'Delhi / NCR',
    'ghaziabad': 'Delhi / NCR',
    'faridabad': 'Delhi / NCR',
    'mumbai': 'Mumbai',
    'navi mumbai': 'Mumbai',
    'thane': 'Mumbai',
    'pune': 'Pune',
    'bengaluru': 'Bengaluru',
    'bangalore': 'Bengaluru',
    'hyderabad': 'Hyderabad',
    'secunderabad': 'Hyderabad',
    'chennai': 'Chennai',
    'madras': 'Chennai',
    'kolkata': 'Kolkata',
    'calcutta': 'Kolkata',
    'jaipur': 'Jaipur',
    'lucknow': 'Lucknow',
    'kanpur': 'Lucknow',
    'varanasi': 'Lucknow',
    'ahmedabad': 'Ahmedabad',
    'surat': 'Ahmedabad',
    'vadodara': 'Ahmedabad',
    'patna': 'Patna',
    'chandigarh': 'Chandigarh',
    'bhopal': 'Bhopal',
    'indore': 'Bhopal',
    'bhubaneswar': 'Bhubaneswar',
    'cuttack': 'Bhubaneswar',
    'kochi': 'Kochi',
    'cochin': 'Kochi',
    'thiruvananthapuram': 'Kochi',
    'guwahati': 'Guwahati',
  };

  /// Direct GPS hardware location detection with package:location
  Future<String?> detectLiveGPSLocation() async {
    try {
      final location = Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          debugPrint('[LocationService] GPS Service disabled, falling back to IP');
          return await _detectViaIP();
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          debugPrint('[LocationService] GPS Permission denied, falling back to IP');
          return await _detectViaIP();
        }
      }

      final locData = await location.getLocation().timeout(const Duration(seconds: 5));
      if (locData.latitude != null && locData.longitude != null) {
        final lat = locData.latitude!;
        final lon = locData.longitude!;

        // Fast reverse geocoding via OpenStreetMap Nominatim
        final geoUri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=10&addressdetails=1',
        );
        final geoRes = await http.get(
          geoUri,
          headers: {'User-Agent': 'PowerNewsApp/1.0 (Android Location Detection)'},
        ).timeout(const Duration(seconds: 4));

        if (geoRes.statusCode == 200) {
          final geoData = json.decode(utf8.decode(geoRes.bodyBytes));
          final address = geoData['address'] as Map<String, dynamic>? ?? {};
          final city = (address['city'] ?? address['town'] ?? address['state_district'] ?? address['state'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          final state = (address['state'] ?? '').toString().toLowerCase().trim();

          debugPrint('[LocationService] GPS detected address: city=$city, state=$state');

          for (final entry in _cityMapping.entries) {
            if (city.contains(entry.key) || state.contains(entry.key)) {
              final matched = entry.value;
              await setPreferredCity(matched);
              return matched;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Package location error: $e');
    }

    return await _detectViaIP();
  }

  /// Auto-detect user's current city (Saved preference -> GPS -> IP Fallback)
  Future<String?> detectUserCity() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString(_prefCityKey);
    if (savedCity != null && savedCity.isNotEmpty) {
      return savedCity;
    }

    return await detectLiveGPSLocation();
  }

  /// IP Geolocation fallback
  Future<String?> _detectViaIP() async {
    try {
      final response = await http
          .get(Uri.parse('http://ip-api.com/json'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rawCity = (data['city'] ?? '').toString().toLowerCase().trim();
        final rawRegion = (data['regionName'] ?? '').toString().toLowerCase().trim();

        for (final entry in _cityMapping.entries) {
          if (rawCity.contains(entry.key) || rawRegion.contains(entry.key)) {
            debugPrint('[LocationService] IP-detected city: ${entry.value}');
            await setPreferredCity(entry.value);
            return entry.value;
          }
        }
      }
    } catch (e) {
      debugPrint('[LocationService] IP Geolocation error: $e');
    }

    return 'Delhi / NCR';
  }

  Future<void> setPreferredCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefCityKey, city);
  }

  Future<String?> getSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefCityKey);
  }
}
