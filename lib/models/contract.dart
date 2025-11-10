// filepath: c:\FlutterProjects\projet_mobile-voiture\lib\models\contract.dart
import 'dart:convert';
import 'dart:typed_data';

class Contract {
  int? id;
  String title;
  String terms;
  double price;
  String status; // Pending, PartiallySigned, Validated
  DateTime createdAt;
  DateTime updatedAt;

  String buyerName;
  String buyerContact;
  String sellerName;
  String sellerContact;

  Map<String, dynamic>? carSnapshot;

  Uint8List? signatureBuyer;
  Uint8List? signatureSeller;

  String? pdfPath;

  int? buyerId;
  int? sellerId;
  int? carId;

  // New fields
  DateTime? signingDate;
  DateTime? expirationDate;
  String? carMatricule;

  Contract({
    this.id,
    required this.title,
    required this.terms,
    required this.price,
    this.status = 'Pending',
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.buyerName,
    required this.buyerContact,
    required this.sellerName,
    required this.sellerContact,
    this.carSnapshot,
    this.signatureBuyer,
    this.signatureSeller,
    this.pdfPath,
    this.buyerId,
    this.sellerId,
    this.carId,
    this.signingDate,
    this.expirationDate,
    this.carMatricule,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool isSignedByBuyer() => signatureBuyer != null && signatureBuyer!.isNotEmpty;
  bool isSignedBySeller() => signatureSeller != null && signatureSeller!.isNotEmpty;
  bool isValidated() => isSignedByBuyer() && isSignedBySeller();

  factory Contract.fromMap(Map<String, dynamic> map) {
    Uint8List? decodeSig(dynamic v) {
      if (v == null) return null;
      if (v is Uint8List) return v;
      if (v is List<int>) return Uint8List.fromList(v);
      if (v is String && v.isNotEmpty) {
        try {
          return base64Decode(v);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String && v.isNotEmpty) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return Contract(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      terms: map['terms'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'Pending',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
      buyerName: map['buyerName'] as String? ?? '',
      buyerContact: map['buyerContact'] as String? ?? '',
      sellerName: map['sellerName'] as String? ?? '',
      sellerContact: map['sellerContact'] as String? ?? '',
      carSnapshot: map['carSnapshot'] != null ? jsonDecode(map['carSnapshot']) as Map<String, dynamic> : null,
      signatureBuyer: decodeSig(map['signatureBuyer']),
      signatureSeller: decodeSig(map['signatureSeller']),
      pdfPath: map['pdfPath'] as String?,
      buyerId: map['buyerId'] as int?,
      sellerId: map['sellerId'] as int?,
      carId: map['carId'] as int?,
      signingDate: parseDate(map['signingDate']),
      expirationDate: parseDate(map['expirationDate']),
      carMatricule: map['carMatricule'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    String? encodeSig(Uint8List? s) => s == null ? null : base64Encode(s);
    String? dateToStr(DateTime? d) => d == null ? null : d.toIso8601String();
    return {
      'id': id,
      'title': title,
      'terms': terms,
      'price': price,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'buyerName': buyerName,
      'buyerContact': buyerContact,
      'sellerName': sellerName,
      'sellerContact': sellerContact,
      'carSnapshot': carSnapshot != null ? jsonEncode(carSnapshot) : null,
      'signatureBuyer': encodeSig(signatureBuyer),
      'signatureSeller': encodeSig(signatureSeller),
      'pdfPath': pdfPath,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'carId': carId,
      'signingDate': dateToStr(signingDate),
      'expirationDate': dateToStr(expirationDate),
      'carMatricule': carMatricule,
    };
  }

  Contract copyWith({
    int? id,
    String? title,
    String? terms,
    double? price,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? buyerName,
    String? buyerContact,
    String? sellerName,
    String? sellerContact,
    Map<String, dynamic>? carSnapshot,
    Uint8List? signatureBuyer,
    Uint8List? signatureSeller,
    String? pdfPath,
    int? buyerId,
    int? sellerId,
    int? carId,
    DateTime? signingDate,
    DateTime? expirationDate,
    String? carMatricule,
  }) {
    return Contract(
      id: id ?? this.id,
      title: title ?? this.title,
      terms: terms ?? this.terms,
      price: price ?? this.price,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      buyerName: buyerName ?? this.buyerName,
      buyerContact: buyerContact ?? this.buyerContact,
      sellerName: sellerName ?? this.sellerName,
      sellerContact: sellerContact ?? this.sellerContact,
      carSnapshot: carSnapshot ?? this.carSnapshot,
      signatureBuyer: signatureBuyer ?? this.signatureBuyer,
      signatureSeller: signatureSeller ?? this.signatureSeller,
      pdfPath: pdfPath ?? this.pdfPath,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      carId: carId ?? this.carId,
      signingDate: signingDate ?? this.signingDate,
      expirationDate: expirationDate ?? this.expirationDate,
      carMatricule: carMatricule ?? this.carMatricule,
    );
  }
}
