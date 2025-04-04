import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import '../utils/dialog_helper.dart';
import 'package:get/get.dart';

/// Service for handling location-related operations
class LocationService {
  /// Check if location services are enabled
  Future<bool> checkLocationServices() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission from user
  Future<LocationPermission> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    
    if (permission == LocationPermission.denied) {
      // Show dialog with platform-specific instructions
      await DialogHelper.showLocationPermissionDialog(Get.context!);
    }
    
    return permission;
  }

  /// Get current position with permission handling
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      if (!await checkLocationServices()) {
        throw Exception('Location services are disabled');
      }

      // Check and request permission if needed
      final permission = await checkPermission();
      
      if (permission == LocationPermission.denied) {
        final newPermission = await requestPermission();
        if (newPermission != LocationPermission.whileInUse && 
            newPermission != LocationPermission.always) {
          return null;
        }
      } else if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied forever');
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }
}
