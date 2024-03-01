import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_ble_connect/bleConnection/screens/bleConnectionScreen.dart';
import 'package:qr_ble_connect/wifiDetailCollection/screens/wifiDetailCollectionScreen.dart';

class WifiNameListScreen extends StatefulWidget {
  const WifiNameListScreen(
      {super.key,
      required this.wifiNameList,
      required this.deviceName,
      required this.deviceKey});

  final List<String> wifiNameList;
  final String deviceName;
  final String? deviceKey;

  @override
  State<WifiNameListScreen> createState() => WifiNameListScreenState();
}

class WifiNameListScreenState extends State<WifiNameListScreen> {
  late List<String> items;
  late String deviceName;
  late String deviceKey;

  @override
  void initState() {
    super.initState();
    items = widget.wifiNameList;
    deviceName = widget.deviceName;
    deviceKey = widget.deviceKey!;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Consumer<BleProvider>(builder: (context, bleProvider, child) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.blue,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  bleProvider.disconnect();
                  Navigator.of(context).pop(true);
                },
              ),
              title: Text('Wifi List',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center),
            ),
            body: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(items[index]),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DataCollectionScreen(
                            ssid: items[index],
                            deviceKey: deviceKey,
                            deviceName: deviceName),
                      ),
                    );
                  },
                );
              },
            ),
          );
        }));
  }
}
