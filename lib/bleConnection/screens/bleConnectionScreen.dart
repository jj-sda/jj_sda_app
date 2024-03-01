import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_ble_connect/configrations/bleServices.dart' as BP;
import 'dart:io';

class BleProvider with ChangeNotifier {
  BluetoothEvents flutterBluePlusEvents = FlutterBluePlus.events;
  // BluetoothDevice? get connectedDevice => _connectedDevice;
  BmConnectionStateEnum connectionState = BmConnectionStateEnum.disconnected;
  List<BluetoothDevice> devices = [];
  bool isLoading = false;
  bool isDeviceConnected = false;
  bool isDeviceFound = true;
  bool isDeviceConnectedSuccessfully = false;
  bool isStartCalled = false;
  BluetoothDevice? targetDevice;
  bool unpair = false;
  List<BluetoothService> services = [];
  bool initialSetupComplete = false;
  StreamSubscription<List<int>>? notifySubscription;
  final BP.BleServices bleProvider = BP.BleServices();
  BluetoothCharacteristic? writeBle;
  List<List<double>> dataList = [];
  bool isUpdateData = false;
  String AscciStringValue = "";
  bool isRead = false;
  bool isWrite = false;
  bool isWriteStarted = false;
  bool isWriteCompleted = false;
  List<int> writeResponse = [];
  String collectedData = "";

  Future<void> startBleDeviceScan(String? deviceName, String? deviceKey,
      [Map<String, dynamic>? data]) async {
    var collectedDetails = "";
    if (isWrite && !isRead) {
      if (data != null) {
        collectedDetails = jsonEncode(data);
        print("collected data:$collectedDetails:End");
        collectedData = collectedDetails;
      } else {
        Fluttertoast.showToast(
            msg: "Invalid Data",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            textColor: Colors.blueAccent,
            fontSize: 16.0);
      }
    }
    const locationPermission = Permission.location;
    final isLocationEnabled = await locationPermission.serviceStatus.isEnabled;
    if (!isLocationEnabled) {
      Fluttertoast.showToast(
          msg: "Make sure your location is enabled",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          textColor: Colors.blueAccent,
          fontSize: 16.0);
      return;
    }

    final locationPermissionStatus = await locationPermission.status;
    if (locationPermissionStatus.isGranted) {
      if (Platform.isIOS) {
        var subscription = FlutterBluePlus.adapterState
            .listen((BluetoothAdapterState state) async {
          print(state);
          if (state == BluetoothAdapterState.on) {
            await startScan(
              deviceName,
              deviceKey,
            );
          } else {
            Fluttertoast.showToast(
                msg: "Make sure your Bluetooth is turned on",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                textColor: Colors.blueAccent,
                fontSize: 16.0);
          }
        });
      } else {
        final bluetoothOn = await FlutterBluePlus.isOn;
        if (bluetoothOn) {
          await startScan(deviceName, deviceKey);
        } else {
          await FlutterBluePlus.turnOn();
          await startScan(deviceName, deviceKey);
        }
      }
    } else if (locationPermissionStatus.isDenied) {
      await locationPermission.request();
      // Handle case when location permission is denied
    } else if (locationPermissionStatus.isPermanentlyDenied) {
      // Handle case when location permission is permanently denied
      // openAppSettings();
    }
  }

  Future<void> startScan(String? deviceName, String? deviceKey) async {
    isLoading = true;
    if (!isDeviceConnected) {
      isDeviceFound = true;
      notifyListeners();
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      FlutterBluePlus.scanResults.listen(
        (results) {},
        onDone: () async {
          await stopScan();
          notifyListeners();
        },
        onError: (error) async {
          print("HIT ON ERROR : $error");
          await stopScan();
          notifyListeners();
        },
      );
      Future.delayed(Duration(seconds: 10), () {
        var lastScanResults = FlutterBluePlus.lastScanResults;
        devices.clear();
        isDeviceFound = false;
        for (ScanResult r in lastScanResults) {
          if (r.device.advName == deviceName) {
            isDeviceFound = true;
            FlutterBluePlus.stopScan();
            connectToDevice(r.device);
            break;
          }
        }
        if (!isDeviceFound) {
          stopScan();
          Fluttertoast.showToast(
              msg: "Device not found",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              textColor: Colors.blueAccent,
              fontSize: 16.0);
          isDeviceFound = false;
          isLoading = false;
          notifyListeners();
        }
      });
    } else {
      notifyListeners();
      discoverServices(true);
    }
  }

  stopScan() async {
    isLoading = false;
    FlutterBluePlus.stopScan();
    notifyListeners();
  }

  disconnect() async {
    if (targetDevice != null) {
      if (targetDevice!.isConnected) {
        AscciStringValue = '';
        await targetDevice!.disconnect(timeout: 1, queue: false);
        targetDevice = null;
        isDeviceConnected = false;
        isDeviceConnectedSuccessfully = false;
        // notifyListeners();
      }
    }
  }

  Future<void> connectToDevice(BluetoothDevice tDevice) async {
    targetDevice = tDevice;
    try {
      await targetDevice?.connect(autoConnect: false).then((value) {
        // UserSessionManager.setDeviceMacId(targetDevice!.name.toString());
      });
      unpair = false;
      isLoading = true;
      isDeviceConnected = true;
      isDeviceConnectedSuccessfully = true;
      isDeviceFound = true;
      discoverServices(true);
      print("CONNECTION STATUS : connected");
    } on PlatformException catch (e) {
      if (e.code != 'already_connected') {
        rethrow;
      }
    }
  }

  Future<void> discoverServices([bool? reconnect]) async {
    if (targetDevice == null) return;
    services.clear();
    if (targetDevice?.isConnected ?? false) {
      services = (await targetDevice?.discoverServices())!;
    } else {
      isLoading = false;
      isDeviceConnected = false;
      Fluttertoast.showToast(
          msg: "Device not connected",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          textColor: Colors.blueAccent,
          fontSize: 16.0);
    }
    // services = (await targetDevice?.discoverServices())!;
    await notifyBleValues();
    // initialSetupComplete = true;
    // notifyListeners();
  }

  notifyBleValues() async {
    notifySubscription?.cancel();
    notifySubscription = null;
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        // isDeviceConnected = true;
        if (isRead && !isWrite) {
          print("DATA ARRIVED : DATA");
          if (characteristic.uuid.toString() ==
              "6e400004-b5a3-f393-e0a9-e50e24dcca9e") {
            Future.delayed(Duration(milliseconds: 50), () {
              characteristic.read().then((value) {
                List<int> assciiResponse = value;
                print("Characteristic value: ${value.toString()}");
                var stringResponse = String.fromCharCodes(assciiResponse);
              });
              notifySubscription = characteristic.lastValueStream.listen(
                (value) {
                  print("DATA ARRIVED : value = $value");
                  List<String> hexData = decimalToHex(value);
                  print("DATA ARRIVED : hexData = $hexData");
                  // Convert hex strings to integers
                  try {
                    List<int> byteList = hexData
                        .map((hex) => int.parse(hex, radix: 16))
                        .toList();

                    print(byteList);
                    String result = utf8.decode(byteList);
                    print("DATA ARRIVED : asciiString = $result");
                    if (result != null && result != "") {
                      AscciStringValue = result;
                      isLoading = false;
                      isDeviceFound = true;
                      notifyListeners();
                    }
                  } catch (e) {
                    print("Error: $e");
                  }
                },
              );
            });
          }
        } else if (isWrite && !isRead) {
          if (characteristic.uuid.toString() ==
              "6e400003-b5a3-f393-e0a9-e50e24dcca9e") {
            // Enable notifications for the characteristic
            // await characteristic.setNotifyValue(true);
            // Show toast if response is unsuccessful
            Fluttertoast.showToast(
                msg: 'start write and waiting for result',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                textColor: Colors.blueAccent,
                fontSize: 16.0);
            // Write data to the characteristic and listen for the response
            writeDataAndListenForResponse(characteristic, collectedData);
            isWriteStarted = true;
            //   }
            // }
          }
        }
      }
    }
    if (isWriteStarted) {
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid.toString() ==
              "6e400002-b5a3-f393-e0a9-e50e24dcca9e") {
            print(characteristic.uuid);
            // characteristic.read().then((value) {
            //   List<int> assciiResponse = value;
            //   print("Characteristic value: ${value.toString()}");
            //   var stringResponse = String.fromCharCodes(assciiResponse);
            // });
            await characteristic.setNotifyValue(true);
            notifySubscription = characteristic.onValueReceived.listen(
              (value) {
                if (value != null && value.isNotEmpty && value[0] != 0x00) {
                  notifySubscription!.cancel();
                  print("DATA ARRIVED : value = $value");
                  // var writeResponseDecimal = toDecimalByte(writeResponse);
                  isWriteStarted = false;
                  writeResponse = value;
                  isWriteCompleted = true;
                  isLoading = false;
                  isLoading = false;
                  notifyListeners();
                }
              },
            );
            Timer(Duration(minutes: 2), () {
              if (isWriteStarted) {
                isWriteStarted = false;
                writeResponse = [];
                isWriteCompleted = true;
                isLoading = false;
                isLoading = false;
                notifyListeners();
              }
            });
          }
        }
      }
    }
  }
}

decimalToHex(List<int> decimalValue) {
  List<String> hexList = [];
  for (int decimal in decimalValue) {
    String hex = decimal.toRadixString(16).padLeft(2, '0');
    hexList.add(hex);
  }
  print("Hexadecimal: $hexList");
  return hexList;
}

void writeDataAndListenForResponse(
    BluetoothCharacteristic characteristic, String collectedData) async {
  // Write data to the characteristic
  characteristic.write(utf8.encode(collectedData));
}

String byteToDecimalString(String byteStr) {
  int decimal = int.parse(byteStr, radix: 16);
  return decimal.toString();
}

int toDecimalByte(String byteStr) {
  int byte = int.parse(byteStr.substring(1, byteStr.length - 1), radix: 10);
  return byte & 0xFF;
}
