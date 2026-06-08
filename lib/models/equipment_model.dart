class Equipment {
  final String name;
  final String factory;
  final String imageUrl;
  final String manufacturer;
  final String model;
  final String noOfHead;
  final String serialNo;
  final double tableLength;
  final String voltage;
  final double weight;

  Equipment({
    required this.name,
    required this.factory,
    required this.imageUrl,
    required this.manufacturer,
    required this.model,
    required this.noOfHead,
    required this.serialNo,
    required this.tableLength,
    required this.voltage,
    required this.weight,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return Equipment(
      name: json['name']?.toString() ?? '',
      factory: json['工場']?.toString() ?? '',
      imageUrl: json['imageURL']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      noOfHead: json['noOfHead']?.toString() ?? '',
      serialNo: json['serialNo']?.toString() ?? '',
      tableLength: parseDouble(json['tableLength']),
      voltage: json['voltage']?.toString() ?? '',
      weight: parseDouble(json['weight']),
    );
  }

  factory Equipment.empty() {
    return Equipment(
      name: '',
      factory: '',
      imageUrl: '',
      manufacturer: '',
      model: '',
      noOfHead: '',
      serialNo: '',
      tableLength: 0.0,
      voltage: '',
      weight: 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      '工場': factory,
      'imageURL': imageUrl,
      'manufacturer': manufacturer,
      'model': model,
      'noOfHead': noOfHead,
      'serialNo': serialNo,
      'tableLength': tableLength,
      'voltage': voltage,
      'weight': weight,
    };
  }
}
