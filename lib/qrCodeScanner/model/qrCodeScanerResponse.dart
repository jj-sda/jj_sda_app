class QrCodeScnnerResponse {
  final String name;
  final String key;

  QrCodeScnnerResponse({required this.name, required this.key});

  factory QrCodeScnnerResponse.fromJson(Map<String, dynamic> json) {
    return QrCodeScnnerResponse(
      name: json['name'],
      key: json['key'],
    );
  }
}
