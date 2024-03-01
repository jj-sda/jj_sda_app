import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleServices {
  BleStatus _status = BleStatus.unknown;
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  late StreamSubscription<BleStatus> bleStatusSubscription;
  late bool _isInitialBleStatusChange; // Initialize the flag to true
  FlutterBluePlus flutterBluePlus = FlutterBluePlus();

  // Private constructor
  BleServices._private();

  // Singleton instance
  static final BleServices _instance = BleServices._private();

  // Factory constructor to provide the same instance each time
  factory BleServices() => _instance;

  Future<void> startListening({bool isInitialBleStatusChange = true}) async {
    _isInitialBleStatusChange = isInitialBleStatusChange;
    // Add a small delay before starting to listen to the BLE status stream.
    bleStatusSubscription = _ble.statusStream.listen((status) async {
      if (_isInitialBleStatusChange) {
        // Skip showing the toast for the initial status
        _isInitialBleStatusChange = false;
      } else if (_isInitialBleStatusChange == false) {
        _status = status;
        if (_status == BleStatus.ready) {
          showBluetoothConnectivityToast();
        } else if (_status == BleStatus.poweredOff) {
          showNoBluetoothConnectivityToast();
          /*if (Platform.isAndroid) {
            if (kDebugMode) {
              print("Bluetooth is off");
            }
            bool value = await FlutterBluePlus.turnOn();
            if (value) {
              if (kDebugMode) {
                print("Bluetooth turned on successfully");
              }
            }
          }*/
        } else {}
      }
    });
  }

  void stopListening() {
    bleStatusSubscription.cancel();
  }

  void showNoBluetoothConnectivityToast() {
    // connectivityLostToast(LipStrings.bleIsOff);
    print('bleOff');
  }

  void showBluetoothConnectivityToast() {
    print('bleOn');
  }
}
