import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final double baseAmount;    // Converted amount in USD (e.g., 7.69)
  final String currency;      // The currency code at time of entry (e.g., 'KSH')
  final String type; // 'Income' or 'Expense'
  final String categoryId;
  final DateTime? updatedAt;
  
  final DateTime date;
 
  Transaction({
    this.id = '',
    required this.userId,
    required this.title,
    required this.amount,
    required this.baseAmount,
    required this.currency,
    required this.type,
    required this.categoryId,
    required this.date,
    this.updatedAt, 
  });

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    double? baseAmount,
    String? currency,
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
      baseAmount: baseAmount ?? this.baseAmount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  
  factory Transaction.fromMap(Map<String, dynamic> map){
    return Transaction(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      baseAmount: (map['baseAmount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'USD',
      type: map['type'] ?? 'Expense',
      categoryId: map['categoryId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null, 
    );    
  }
  
  // Factory constructor from Firestore
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Inject the document ID into the map data structure
    data['id'] = doc.id; 
    
    return Transaction.fromMap(data);
  }

  // Convert Transaction object to a map for Firestore storage
   Map<String, dynamic> toFirestore() {
    final map = {
      'userId': userId,
      'title': title,
      'amount': amount,
      'baseAmount': baseAmount,
      'currency': currency,
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
