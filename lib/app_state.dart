import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class AppState extends ChangeNotifier {
  double? latitude;
  double? longitude;
  String? city;
  String? state;
  String selectedLanguage = "en";

  void setLanguage(String language) {
    var normalized = language.trim().toLowerCase();
    if (normalized.isEmpty) {
      normalized = "en";
    }
    if (normalized != "en") {
      debugPrint("Language override enforced to en.");
      normalized = "en";
    }
    if (normalized == selectedLanguage) {
      return;
    }
    selectedLanguage = normalized;
    notifyListeners();
  }

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
      await _resolvePlacemark(pos.latitude, pos.longitude);
      notifyListeners();
    } catch (e) {
      locationStatus = "Location error: $e";
      locationPermissionGranted = false;
      notifyListeners();
    }
  }

  Future<void> _resolvePlacemark(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      final placemark = placemarks.isNotEmpty ? placemarks.first : null;
      final iso = placemark?.isoCountryCode?.toUpperCase();
      if (iso != "US") {
        city = null;
        state = null;
        locationStatus = "Location outside US. Showing US-wide news.";
        return;
      }

      city = placemark?.locality?.trim().isNotEmpty == true
          ? placemark?.locality?.trim()
          : placemark?.subAdministrativeArea?.trim();
      state = placemark?.administrativeArea?.trim();

      if ((city?.isNotEmpty ?? false) || (state?.isNotEmpty ?? false)) {
        locationStatus = "Location ready: ${city ?? ""}${city != null && state != null ? ", " : ""}${state ?? ""}".trim();
      } else {
        locationStatus = "Location ready. Showing US-wide news.";
      }
    } catch (error) {
      city = null;
      state = null;
      locationStatus = "Location lookup failed. Showing US-wide news.";
    }
  }
}
