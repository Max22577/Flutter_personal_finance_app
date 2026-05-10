import 'package:cloud_firestore/cloud_firestore.dart';
class SavingsGoal {
  final String? id;
  final String name;
  final String currency;
  final double targetAmount;
  final double currentAmount;
  final double targetBaseAmount; 
  final double currentBaseAmount; 
  final DateTime deadline;

  SavingsGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.currency,
    required this.targetBaseAmount,
    required this.currentBaseAmount,
    required this.deadline,
  });

  // Factory constructor from Firestore
  factory SavingsGoal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavingsGoal(
      id: doc.id,
      name: data['name'] ?? data['goalName'] ?? 'Unnamed Goal',
      currency: data['currency'] ?? 'USD',
      targetAmount: (data['targetAmount'] ?? data['target_amount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (data['currentAmount'] ?? data['current_amount'] as num?)?.toDouble() ?? 0.0,
      targetBaseAmount: (data['targetBaseAmount'] as num?)?.toDouble() ?? 0.0,
      currentBaseAmount: (data['currentBaseAmount'] as num?)?.toDouble() ?? 0.0,
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 365)),
    );
  }

  // Convert SavingsGoal object to a map for Firestore storage
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'currency': currency,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetBaseAmount': targetBaseAmount,
      'currentBaseAmount': currentBaseAmount,
      'deadline': Timestamp.fromDate(deadline),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}