import 'package:cloud_firestore/cloud_firestore.dart';

class ExchangeRate {
  final String code;        // e.g., 'KSh'
  final double rateToBase;  // How much of this currency equals 1 USD
  final DateTime timestamp; // When this rate was last fetched

  const ExchangeRate({
    required this.code,
    required this.rateToBase,
    required this.timestamp,
  });

  // Factory to convert from Firestore or API JSON
  factory ExchangeRate.fromMap(Map<String, dynamic> map) {
    return ExchangeRate(
      code: map['code'] as String,
      rateToBase: (map['rateToBase'] as num).toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'rateToBase': rateToBase,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}