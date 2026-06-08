class Product {
  final String sebanggo;
  final String productNumber;
  final String model;
  final String shape;
  final String rl;
  final String material;
  final String materialCode;
  final String materialColor;
  final String kataban;
  final int capacity;
  final String feedPitch;
  final String releasePaper;
  final String srs;
  final String imageUrl;

  Product({
    required this.sebanggo,
    required this.productNumber,
    required this.model,
    required this.shape,
    required this.rl,
    required this.material,
    required this.materialCode,
    required this.materialColor,
    required this.kataban,
    required this.capacity,
    required this.feedPitch,
    required this.releasePaper,
    required this.srs,
    required this.imageUrl,
  });

  factory Product.empty() {
    return Product(
      sebanggo: '',
      productNumber: '',
      model: '',
      shape: '',
      rl: '',
      material: '',
      materialCode: '',
      materialColor: '',
      kataban: '',
      capacity: 0,
      feedPitch: '',
      releasePaper: '',
      srs: '',
      imageUrl: '',
    );
  }

  bool get isEmpty => sebanggo.isEmpty && productNumber.isEmpty;

  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse capacity safely
    int cap = 0;
    if (json['収容数'] != null) {
      if (json['収容数'] is int) {
        cap = json['収容数'];
      } else if (json['収容数'] is double) {
        cap = (json['収容数'] as double).toInt();
      } else {
        cap = int.tryParse(json['収容数'].toString()) ?? 0;
      }
    }

    // Determine release paper value
    String rikeshi = json['離型紙上下']?.toString() ?? 
                     json['離型紙上/下']?.toString() ?? 
                     '';

    return Product(
      sebanggo: json['背番号']?.toString() ?? '',
      productNumber: json['品番']?.toString() ?? '',
      model: json['モデル']?.toString() ?? '',
      shape: json['形状']?.toString() ?? '',
      rl: json['R/L']?.toString() ?? '',
      material: json['材料']?.toString() ?? '',
      materialCode: json['材料背番号']?.toString() ?? '',
      materialColor: json['色']?.toString() ?? '',
      kataban: json['型番']?.toString() ?? '',
      capacity: cap,
      feedPitch: json['送りピッチ']?.toString() ?? '',
      releasePaper: rikeshi,
      srs: json['SRS']?.toString() ?? '',
      imageUrl: json['imageURL']?.toString() ?? 
                json['imageUrl']?.toString() ?? 
                json['htmlWebsite']?.toString() ?? 
                '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '背番号': sebanggo,
      '品番': productNumber,
      'モデル': model,
      '形状': shape,
      'R/L': rl,
      '材料': material,
      '材料背番号': materialCode,
      '色': materialColor,
      '型番': kataban,
      '収容数': capacity,
      '送りピッチ': feedPitch,
      '離型紙上下': releasePaper,
      'SRS': srs,
      'imageURL': imageUrl,
    };
  }
}
