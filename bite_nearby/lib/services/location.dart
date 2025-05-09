import 'dart:async';

import 'package:location/location.dart' as loc;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bite_nearby/services/Restaurant_service.dart';

class LocationService {
  final loc.Location _location = loc.Location();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isMonitoring = false;
  Timer? _monitoringTimer;

  Future<Map<String, dynamic>> getCurrentLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }
    }

    loc.PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        throw Exception("Location permission denied.");
      }
    }

    loc.LocationData locationData = await _location.getLocation();

    double latitude = locationData.latitude ?? 0.0;
    double longitude = locationData.longitude ?? 0.0;

    // Get Address from Coordinates
    String address = await getAddressFromCoordinates(latitude, longitude);

    print("Fetched User Location: $address"); // Debugging

    return {
      'geoPoint': GeoPoint(latitude, longitude),
      'address': address,
    };
  }

// Add this to your LocationService class
  Future<List<Map<String, dynamic>>> getPopularItems(
      String restaurantId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Restaurants')
          .doc(restaurantId)
          .collection('menu')
          .orderBy('rating', descending: true)
          .limit(3)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching menu items: $e');
      return [];
    }
  }

  Future<void> startProximityMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // Check location every 5 minutes (adjust as needed)
    const interval = Duration(minutes: 5);
    _monitoringTimer = Timer.periodic(interval, (timer) async {
      try {
        final locationData = await getCurrentLocation();
        final restaurants = await RestaurantService().getSortedRestaurants();

        if (restaurants.isNotEmpty) {
          final nearest = restaurants.first;
          final distanceKm = nearest['distance'] / 1000;

          if (distanceKm <= 15) {
            await _showProximityNotification(nearest);
            // Stop monitoring after showing notification to avoid spamming
            stopProximityMonitoring();
          }
        }
      } catch (e) {
        print('Proximity monitoring error: $e');
      }
    });
  }

  void stopProximityMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _isMonitoring = false;
  }

  Future<void> _showProximityNotification(
      Map<String, dynamic> restaurant) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'proximity_channel',
      'Proximity Alerts',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      restaurant['id'].hashCode, // Unique ID based on restaurant ID
      'Nearby Restaurant: ${restaurant['name']}',
      'You\'re close to ${restaurant['name']}. Check out their menu!',
      platformChannelSpecifics,
      payload: 'restaurant:${restaurant['id']}',
    );
  }

  // Reverse Geocode to Get Address
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.street}, ${place.locality}, ${place.country}";
      }
      return "Unknown location";
    } catch (e) {
      print("Error fetching address: $e");
      return "Unknown location";
    }
  }

  void dispose() {
    stopProximityMonitoring();
  }
}
