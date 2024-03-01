// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
// import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
// import 'package:qr_ble_connect/bleConnection/screens/bleConnectionScreen.dart';
// import 'package:qr_ble_connect/detailsEnter/screens/detailsEnterScreen.dart';
// import 'package:qr_ble_connect/permissionHandlerProvider/providers/permissionHandlerProvider.dart';
// import 'package:qr_ble_connect/wifiNameList/Screens/wifiNameListScreen.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);
//   // SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//   runApp(MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (context) => BleProvider()),
//         ChangeNotifierProvider(create: (context) => PermissionsProvider())
//       ],
//       child: const MaterialApp(
//           debugShowCheckedModeBanner: false, home: MyHome())));
// }

// class MyHome extends StatelessWidget {
//   const MyHome({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final permissionsProvider = Provider.of<PermissionsProvider>(context);
//     return Scaffold(
//       appBar: AppBar(title: const Text('QR BLE Connect')),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () async {
//             await permissionsProvider.requestPermissions();
//             if (permissionsProvider.isPermissionGranted) {
//               Navigator.of(context).push(MaterialPageRoute(
//                 builder: (context) => const QRViewExample(),
//               ));
//             } else {
//               if (!permissionsProvider.isCameraGranted) {
//                 aleartPermission(
//                     context,
//                     'Please grant camera permission to continue.',
//                     permissionsProvider);
//               }
//               if (!permissionsProvider.isLocationGranted) {
//                 aleartPermission(
//                     context,
//                     'Please grant location permission to continue.',
//                     permissionsProvider);
//               }
//               if (!permissionsProvider.isBlutoothGranted) {
//                 aleartPermission(
//                     context,
//                     'Please grant bluetooth permission to continue.',
//                     permissionsProvider);
//               }
//             }
//           },
//           child: const Text('Scan QR CODE'),
//         ),
//       ),
//     );
//   }

//   Future<void> aleartPermission(BuildContext context, String msg,
//       PermissionsProvider permissionsProvider) async {
//     AlertDialog alertDialog = AlertDialog(
//       title: Text('Permission Required'),
//       content: Text(msg),
//       actions: [
//         TextButton(
//           child: Text('OK'),
//           onPressed: () async {
//             Navigator.of(context).pop();
//             await permissionsProvider.requestPermissions();
//           },
//         ),
//       ],
//     );
//     showDialog(
//         context: context, builder: (BuildContext context) => alertDialog);
//   }
// }

// class QRViewExample extends StatefulWidget {
//   const QRViewExample({Key? key}) : super(key: key);

//   @override
//   State<StatefulWidget> createState() => _QRViewExampleState();
// }

// class _QRViewExampleState extends State<QRViewExample> {
//   Barcode? result;
//   QRViewController? controller;
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

//   // In order to get hot reload to work we need to pause the camera if the platform
//   // is android, or resume the camera if the platform is iOS.
//   @override
//   void reassemble() {
//     super.reassemble();
//     if (Platform.isAndroid) {
//       controller!.pauseCamera();
//     }
//     controller!.resumeCamera();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//         onWillPop: () async => false,
//         child: Consumer<BleProvider>(builder: (context, bleProvider, child) {
//           WidgetsBinding.instance.addPostFrameCallback(
//             (timeStamp) {
//               if (result != null) {
//                 if (!bleProvider.isLoading) {
//                   try {
//                     String? deviceName = null;
//                     String? deviceKey = null;
//                     Map<String, dynamic> jsonData = stringToJson(result!.code!);
//                     if (jsonData.containsKey('key')) {
//                       deviceKey = jsonData[
//                           'key']; // get the value for the key, value will be 'one'
//                     } else {
//                       deviceKey = "";
//                     }
//                     // get the value for the key, value will be 'one'
//                     if (jsonData.containsKey('name')) {
//                       deviceName = jsonData['name'];
//                       if (deviceName != "") {
//                         nextScreen(context, deviceName, deviceKey, bleProvider);
//                       }
//                     } else {
//                       customDialogBox();
//                     }
//                   } catch (e) {
//                     customDialogBox();
//                   }
//                 }
//               }
//             },
//           );
//           return Scaffold(
//             appBar: AppBar(
//               title: const Text('QR BLE Connect'),
//               leading: IconButton(
//                 icon: Icon(Icons.arrow_back_ios, color: Colors.black),
//                 onPressed: () {
//                   Navigator.of(context).pop(true);
//                 },
//               ),
//             ),
//             body: ModalProgressHUD(
//               inAsyncCall: bleProvider.isLoading,
//               child: Column(children: <Widget>[
//                 Expanded(flex: 4, child: _buildQrView(context)),
//               ]),
//             ),
//           );
//         }));
//   }

//   Widget _buildQrView(BuildContext context) {
//     // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
//     var scanArea = (MediaQuery.of(context).size.width < 400 ||
//             MediaQuery.of(context).size.height < 400)
//         ? 300.0
//         : 400.0;
//     // To ensure the Scanner view is properly sizes after rotation
//     // we need to listen for Flutter SizeChanged notification and update controller
//     return QRView(
//       key: qrKey,
//       onQRViewCreated: _onQRViewCreated,
//       overlay: QrScannerOverlayShape(
//           borderColor: Colors.red,
//           borderRadius: 10,
//           borderLength: 30,
//           borderWidth: 10,
//           cutOutSize: scanArea),
//       onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
//     );
//   }

//   void _onQRViewCreated(QRViewController controller) {
//     setState(() {
//       this.controller = controller;
//     });
//     controller.scannedDataStream.listen((scanData) {
//       if (result == null) {
//         setState(() {
//           result = scanData;
//           controller.pauseCamera();
//         });
//       }
//     });
//   }

//   void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
//     log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
//     if (!p) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('no Permission')),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }

//   Map<String, dynamic> stringToJson(String jsonString) {
//     return jsonDecode(jsonString);
//   }

//   nextScreen(BuildContext context, String? deviceName, String? deviceKey,
//       BleProvider bleProvider) {
//     if (deviceName != null) {
//       if (!bleProvider.isLoading) {
//         if (bleProvider.isDeviceFound) {
//           if (!(bleProvider.AscciStringValue != null &&
//               bleProvider.AscciStringValue != '')) {
//             bleProvider.isRead = true;
//             bleProvider.isWrite = false;
//             bleProvider.startBleDeviceScan(deviceName, deviceKey, null);
//           } else {
//             List<String> wifiNameList =
//                 convertStringtoList(bleProvider.AscciStringValue);
//             showDialog(
//               context: context,
//               builder: (context) {
//                 return WillPopScope(
//                   onWillPop: () async => false,
//                   child: AlertDialog(
//                     title: Text(
//                         "Bluetooth connection and Wi-Fi scanning is complete"),
//                     actions: [
//                       TextButton(
//                         onPressed: () {
//                           Navigator.pushAndRemoveUntil(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (BuildContext context) =>
//                                       WifiNameListScreen(
//                                           wifiNameList: wifiNameList,
//                                           deviceName: deviceName,
//                                           deviceKey: deviceKey)),
//                               ModalRoute.withName(
//                                   '/') // Replace this with your root screen's route name (usually '/')
//                               );
//                           bleProvider.isRead = false;
//                           bleProvider.isLoading = false;
//                           bleProvider.isDeviceFound = true;
//                           bleProvider.AscciStringValue = '';
//                           // bleProvider.disconnect();
//                         },
//                         child: Text('OK'),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             );
//           }
//         } else if (!(bleProvider.AscciStringValue != null &&
//             bleProvider.AscciStringValue != '')) {
//           showDialog(
//             context: context,
//             builder: (context) {
//               return WillPopScope(
//                 onWillPop: () async => false,
//                 child: AlertDialog(
//                   title: Text('Device not found, please try again'),
//                   actions: [
//                     TextButton(
//                       onPressed: () {
//                         Navigator.pushAndRemoveUntil(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (BuildContext context) => MyHome()),
//                             ModalRoute.withName(
//                                 '/') // Replace this with your root screen's route name (usually '/')
//                             );
//                         bleProvider.isRead = false;
//                         bleProvider.isLoading = false;
//                         bleProvider.isDeviceFound = true;
//                         bleProvider.disconnect();
//                       },
//                       child: Text('OK'),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         }
//       }
//     }

//     // if (bleProvider.isDeviceConnectedSuccessfully) {
//     //   Fluttertoast.showToast(
//     //       msg: "Device Successfully Connected ",
//     //       toastLength: Toast.LENGTH_SHORT,
//     //       gravity: ToastGravity.CENTER,
//     //       timeInSecForIosWeb: 1,
//     //       backgroundColor: Colors.red,
//     //       textColor: Colors.white,
//     //       fontSize: 16.0);
//     // }
//     // if (bleProvider.connectionState == BmConnectionStateEnum.connected) {
//     //   Fluttertoast.showToast(
//     //       msg: "Device  Connected Successfully",
//     //       toastLength: Toast.LENGTH_SHORT,
//     //       gravity: ToastGravity.CENTER,
//     //       timeInSecForIosWeb: 1,
//     //       backgroundColor: Colors.red,
//     //       textColor: Colors.white,
//     //       fontSize: 16.0);
//     // }
//   }

//   void customDialogBox() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return WillPopScope(
//           onWillPop: () async => false,
//           child: AlertDialog(
//             title: Text('Invalid QR Code'),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pushAndRemoveUntil(
//                       context,
//                       MaterialPageRoute(
//                           builder: (BuildContext context) => MyHome()),
//                       ModalRoute.withName(
//                           '/') // Replace this with your root screen's route name (usually '/')
//                       );
//                 },
//                 child: Text('OK'),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// List<String> convertStringtoList(String ascciStringValue) {
//   return ascciStringValue.split('\n');
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_ble_connect/bleConnection/screens/bleConnectionScreen.dart';
import 'package:qr_ble_connect/home/screens/home.dart';
import 'package:qr_ble_connect/permissionHandlerProvider/providers/permissionHandlerProvider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BleProvider()),
        ChangeNotifierProvider(create: (context) => PermissionsProvider())
      ],
      child:
          const MaterialApp(debugShowCheckedModeBanner: false, home: Home())));
}
