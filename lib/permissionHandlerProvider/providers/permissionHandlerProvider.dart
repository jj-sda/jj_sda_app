import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsProvider extends ChangeNotifier {
  PermissionsProvider() {
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.locationWhenInUse,
        Permission.locationAlways,
        Permission.camera,
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
      ].request();
      if (statuses[Permission.camera] == PermissionStatus.granted &&
          (statuses[Permission.locationAlways] == PermissionStatus.granted ||
              statuses[Permission.locationWhenInUse] ==
                  PermissionStatus.granted ||
              statuses[Permission.location] == PermissionStatus.granted) &&
          (statuses[Permission.bluetooth] == PermissionStatus.granted ||
              statuses[Permission.bluetoothScan] == PermissionStatus.granted ||
              statuses[Permission.bluetoothAdvertise] ==
                  PermissionStatus.granted ||
              statuses[Permission.bluetoothConnect] ==
                  PermissionStatus.granted)) {
        _isPermissionGranted = true;
      } else {
        _isPermissionGranted = false;
        if (statuses[Permission.camera] == PermissionStatus.granted) {
          _isCameraGranted = true;
        }
        if (statuses[Permission.locationAlways] == PermissionStatus.granted ||
            statuses[Permission.location] == PermissionStatus.granted ||
            statuses[Permission.locationWhenInUse] ==
                PermissionStatus.granted) {
          _islocationGranted = true;
        }
        if (statuses[Permission.bluetooth] == PermissionStatus.granted ||
            statuses[Permission.bluetoothScan] == PermissionStatus.granted ||
            statuses[Permission.bluetoothAdvertise] ==
                PermissionStatus.granted ||
            statuses[Permission.bluetoothConnect] == PermissionStatus.granted) {
          _isBlutoothGranted = true;
        }
      }
      // }
      // await checkThreePermissions();
      notifyListeners();
    }
    if (Platform.isAndroid) {
      await Permission.location.request();
      await Permission.camera.request();
      await Permission.bluetooth.request();
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.bluetoothAdvertise.request();
      await checkThreePermissions();
      notifyListeners();
    }
  }

  bool _isPermissionGranted = false;
  bool _isCameraGranted = false;
  bool _isBlutoothGranted = false;
  bool _islocationGranted = false;

  bool get isPermissionGranted => _isPermissionGranted;
  bool get isCameraGranted => _isCameraGranted;
  bool get isBlutoothGranted => _isBlutoothGranted;
  bool get isLocationGranted => _islocationGranted;

  Future<void> checkThreePermissions() async {
    // Check camera permission
    PermissionStatus cameraStatus = await Permission.camera.status;
    // Check Bluetooth permission
    PermissionStatus bluetoothScan = await Permission.bluetoothScan.status;
    // Check Bluetooth permission
    PermissionStatus bluetoothConnect =
        await Permission.bluetoothConnect.status;
    // Check Bluetooth permission
    PermissionStatus bluetoothAdvertise =
        await Permission.bluetoothAdvertise.status;
    // Check location permission
    PermissionStatus locationStatus = await Permission.location.status;

    if (cameraStatus == PermissionStatus.granted &&
        locationStatus == PermissionStatus.granted &&
        bluetoothAdvertise == PermissionStatus.granted &&
        bluetoothConnect == PermissionStatus.granted &&
        bluetoothScan == PermissionStatus.granted) {
      _isPermissionGranted = true;
    } else {
      _isPermissionGranted = false;
      if (cameraStatus == PermissionStatus.granted) {
        _isCameraGranted = true;
      } else {
        if (await Permission.camera.isDenied) {
          openAppSettings();
        }
      }
      if (bluetoothConnect == PermissionStatus.granted ||
          bluetoothAdvertise != PermissionStatus.granted ||
          bluetoothScan == PermissionStatus.granted) {
        _isBlutoothGranted = true;
      } else {
        await Permission.bluetoothConnect.request();
      }

      if (locationStatus == PermissionStatus.granted) {
        _islocationGranted = true;
      }
      if (await Permission.location.isDenied) {
        openAppSettings();
      }
    }
  }
}
