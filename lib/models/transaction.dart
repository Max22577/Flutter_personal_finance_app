import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  final String? id;
  final String userId;
  final String title;
  final double amount;
  final String type; // 'Income' or 'Expense'
  final String categoryId;
  final DateTime? updatedAt;
  
  final DateTime date;
 
  Transaction({
    this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.updatedAt, 
  });

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? type,
    String? categoryId,
    DateTime? date,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Factory constructor from Firestore
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      type: data['type'] ?? 'Expense',
      categoryId: data['categoryId'] ?? '',
      // Removed: accountId: data['accountId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),

      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null, 
    );
  }

  // Convert Transaction object to a map for Firestore storage
   Map<String, dynamic> toFirestore() {
    final map = {
      'userId': userId,
      'title': title,
      'amount': amount,
      'type': type,
      'categoryId': categoryId,
      'date': Timestamp.fromDate(date),
      'updatedAt': FieldValue.serverTimestamp(), // Always update timestamp
    };
    
    // Only include ID if creating new (Firestore auto-generates)
    // For updates, ID goes in the document path, not the data
    return map;
  }
}
