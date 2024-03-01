import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_ble_connect/main.dart';
import 'package:qr_ble_connect/permissionHandlerProvider/providers/permissionHandlerProvider.dart';
import 'package:qr_ble_connect/qrCodeScanner/screens/q_r_view_example.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final permissionsProvider = Provider.of<PermissionsProvider>(context);
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text('QR BLE Connect',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center)),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await permissionsProvider.requestPermissions();
            if (permissionsProvider.isPermissionGranted) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const QRViewExample(),
              ));
            } else {
              if (!permissionsProvider.isCameraGranted) {
                aleartPermission(
                    context,
                    'Please grant camera permission to continue.',
                    permissionsProvider);
              }
              if (!permissionsProvider.isLocationGranted) {
                aleartPermission(
                    context,
                    'Please grant location permission to continue.',
                    permissionsProvider);
              }
              if (!permissionsProvider.isBlutoothGranted) {
                aleartPermission(
                    context,
                    'Please grant bluetooth permission to continue.',
                    permissionsProvider);
              }
            }
          },
          child: const Text('Scan QR CODE'),
        ),
      ),
    );
  }

  Future<void> aleartPermission(BuildContext context, String msg,
      PermissionsProvider permissionsProvider) async {
    AlertDialog alertDialog = AlertDialog(
      title: Text('Permission Required'),
      content: Text(msg),
      actions: [
        TextButton(
          child: Text('OK'),
          onPressed: () async {
            Navigator.of(context).pop();
            await permissionsProvider.requestPermissions();
          },
        ),
      ],
    );
    showDialog(
        context: context, builder: (BuildContext context) => alertDialog);
  }
}
