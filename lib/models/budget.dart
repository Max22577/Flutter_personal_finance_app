import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a monthly budget limit set for a specific category.
class Budget {
  final String id; // This will typically be a combination of userId_categoryId_monthYear
  final String userId;
  final String categoryId;
  final double amount;
  final String monthYear; // Format: YYYY-MM (e.g., 2025-12)

  Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.monthYear,
  });

  /// Factory constructor to create a Budget from a Firestore Document Snapshot.
  factory Budget.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Budget(
      id: doc.id,
      userId: data['userId'] as String,
      categoryId: data['categoryId'] as String,
      amount: (data['amount'] as num).toDouble(),
      monthYear: data['monthYear'] as String,
    );
  }

  /// Converts the Budget object to a Map for saving to Firestore.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'categoryId': categoryId,
      'amount': amount,
      'monthYear': monthYear,
    };
  }
}
