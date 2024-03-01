import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:qr_ble_connect/bleConnection/screens/bleConnectionScreen.dart';

class DataCollectionScreen extends StatefulWidget {
  const DataCollectionScreen(
      {super.key,
      required this.ssid,
      required this.deviceKey,
      required this.deviceName});
  final String ssid;
  final String deviceKey;
  final String deviceName;

  @override
  _DataCollectionScreenState createState() => _DataCollectionScreenState();
}

class _DataCollectionScreenState extends State<DataCollectionScreen> {
  late String ssid;
  late String deviceName;
  late String deviceKey;
  final _passController = TextEditingController();
  final _emailControllers = [TextEditingController(), TextEditingController()];
  final _locationController = TextEditingController();
  final _deviceIdController = TextEditingController();
  final _phoneNumController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ssid = widget.ssid;
    deviceKey = widget.deviceKey;
    deviceName = widget.deviceName;
  }

  final _formKey = GlobalKey<FormState>();
  String? _pass = '';
  String _primaryEmail = '';
  String _secondaryEmail = '';
  String _location = '';
  String _deviceId = '';
  String _phoneNum = '';

  Future<void> _saveData(BleProvider bleProvider) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Map<String, dynamic> data = {
        "ssid": ssid,
        "pass": _pass,
        "email": [_primaryEmail],
        "location": _location,
        "device_id": _deviceId,
        "device_name": deviceName,
        "phone_num": _phoneNum,
        "ifttt_key": deviceKey
      };

      if (_secondaryEmail.isNotEmpty) {
        data["email"].add(_secondaryEmail);
      }
      try {
        bleProvider.isWrite = true;
        bleProvider.isRead = false;
        if (!bleProvider.isLoading) {
          if (!bleProvider.isWriteCompleted) {
            bleProvider.isLoading = true;
            bleProvider.startBleDeviceScan(deviceName, deviceKey, data);
          }
        }
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) {
            return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                title: Text('Json Parse Error Try again'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Consumer<BleProvider>(
        builder: (context, bleProvider, _) {
          return ModalProgressHUD(
            inAsyncCall: bleProvider.isLoading,
            child: BuildWidget(context, bleProvider),
          );
        },
      ),
    );
  }

  Widget BuildWidget(BuildContext context, BleProvider bleProvider) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!bleProvider.isLoading) {
        if (bleProvider.isWriteCompleted) {
          String aleartText = "Unknown error Please try again";
          bool isHome = false;
          if (bleProvider.writeResponse.isNotEmpty) {
            if (bleProvider.writeResponse[0] == 0x80) {
              isHome = true;
              aleartText = "Connected successfully";
            } else if (bleProvider.writeResponse[0] == 0x01) {
              aleartText = "Invalid Json Retry";
            } else if (bleProvider.writeResponse[0] == 0x02) {
              aleartText = "Unable to connect to WiFi";
            } else if (bleProvider.writeResponse[0] == 0x04) {
              aleartText = "No internet";
            } else if (bleProvider.writeResponse[0] == 0Xff) {
              aleartText = "Connection exceeded";
            }
          } else {
            isHome = true;
            aleartText =
                "It takes too much time, there might be some error in the device connection";
          }
          showDialog(
            context: context,
            builder: (context) {
              return WillPopScope(
                onWillPop: () async => false,
                child: AlertDialog(
                  title: Text(aleartText),
                  actions: [
                    TextButton(
                      onPressed: () {
                        bleProvider.isLoading = false;
                        bleProvider.isWriteCompleted = false;
                        bleProvider.isWrite = false;
                        bleProvider.isRead = false;
                        bleProvider.writeResponse = [];
                        if (isHome) {
                          bleProvider.disconnect();
                          Navigator.of(context).pop(true);
                          Navigator.of(context).pop(true);
                          Navigator.of(context).pop(true);
                        } else {
                          Navigator.of(context).pop(true);
                        }
                      },
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          );
        }
      }
      // else{
      //   if(bleProvider.isWrite||bleProvider.isRead){
      //     bleProvider.isLoading = true;
      //   }
      // }
    });
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('Enter Details',
            style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ),
      body: Container(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: ssid,
                      enabled: false,
                      decoration: InputDecoration(labelText: 'SSID'),
                    ),
                    TextFormField(
                      controller: _passController,
                      decoration: InputDecoration(labelText: 'Password *'),
                      onSaved: (value) => _pass = value!,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter a password';
                        } else if (isQuatesCheck(value)) {
                          return 'Please enter a valid password';
                        }
                        return null;
                      },
                    ),
                    Column(
                      children: [
                        for (int i = 0; i < 2; i++)
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _emailControllers[i],
                                  decoration: InputDecoration(
                                    labelText: i == 0
                                        ? 'Primary Email *'
                                        : 'Secondary Email',
                                  ),
                                  onSaved: (value) => i == 0
                                      ? _primaryEmail = value!
                                      : _secondaryEmail = value!,
                                  validator: (value) {
                                    if (i == 0) {
                                      if (value!.isEmpty) {
                                        return 'Please enter a primary email';
                                      } else if (!_validateEmail(value)) {
                                        return 'Please enter a valid email';
                                      }
                                    }
                                    if (i == 1 &&
                                        value!.isNotEmpty &&
                                        !_validateEmail(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(labelText: 'Location *'),
                      onSaved: (value) => _location = value!,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter a location';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp('[a-zA-Z0-9]')),
                      ],
                      controller: _deviceIdController,
                      decoration: InputDecoration(labelText: 'Device ID *'),
                      onSaved: (value) => _deviceId = value!,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter a device id';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      initialValue: deviceName,
                      enabled: false,
                      decoration: InputDecoration(labelText: 'Device Name'),
                    ),
                    TextFormField(
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[+0-9]')),
                      ],
                      controller: _phoneNumController,
                      decoration: InputDecoration(labelText: 'Phone Number'),
                      onSaved: (value) => _phoneNum = value!,
                      // validator: (value) {
                      //   if (value!.isEmpty) {
                      //     return 'Please enter a device id';
                      //   }
                      //   return null;
                      // },
                    ),
                    TextFormField(
                      maxLines: 2,
                      textAlign: TextAlign.start,
                      initialValue: deviceKey,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Iftt Key',
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (!bleProvider.isLoading) {
                          _saveData(bleProvider);
                        }
                      },
                      child: Text('Save Data'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9.a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$');
    return emailRegex.hasMatch(email);
  }

  bool isQuatesCheck(String value) {
    bool containsBoth = value.contains('"') || value.contains("'");
    return containsBoth;
  }
}
