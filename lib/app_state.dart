import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class AppState extends ChangeNotifier {
  double? latitude;
  double? longitude;

  bool locationPermissionGranted = false;
  String locationStatus = "Initializing location…";

  Future<void> initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationStatus = "Location services disabled. Enable for local news.";
        locationPermissionGranted = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        locationStatus =
        "Location permission denied forever. Enable in Settings.";
        locationPermissionGranted = false;
        notifyListeners();
        return;
      }

      if (permission == LocationPermission.denied) {
        locationStatus = "Location permission denied. Local news may be limited.";
        locationPermissionGranted = false;
        notifyListeners();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      latitude = pos.latitude;
      longitude = pos.longitude;
      locationPermissionGranted = true;
      locationStatus = "Location ready: $latitude, $longitude";
      notifyListeners();
    } catch (e) {
      locationStatus = "Location error: $e";
      locationPermissionGranted = false;
      notifyListeners();
    }
  }
}
