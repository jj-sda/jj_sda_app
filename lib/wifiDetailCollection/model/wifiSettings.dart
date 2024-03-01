class WifiSettings {
  final String ssid;
  final String pass;
  final List<String> email;
  final String location;
  final String deviceId;
  final String deviceName;
  final String phoneNum;
  final String iftttKey;

  WifiSettings({
    required this.ssid,
    required this.pass,
    required this.email,
    required this.location,
    required this.deviceId,
    required this.deviceName,
    required this.phoneNum,
    required this.iftttKey,
  });

  Map<String, dynamic> toJson() => {
        "ssid": ssid,
        "pass": pass,
        "email": email,
        "location": location,
        "device_id": deviceId,
        "device_name": deviceName,
        "phone_num": phoneNum,
        "ifttt_key": iftttKey,
      };
}
