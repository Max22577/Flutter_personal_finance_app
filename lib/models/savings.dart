import 'package:cloud_firestore/cloud_firestore.dart';
class SavingsGoal {
  final String id;
  final String name;
  final String currency;
  final double targetAmount;
  final double currentAmount;
  final double targetBaseAmount; 
  final double currentBaseAmount; 
  final DateTime deadline;

  SavingsGoal({
    this.id = '',
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.currency,
    required this.targetBaseAmount,
    required this.currentBaseAmount,
    required this.deadline,
  });

  SavingsGoal copyWith({
    String? id,
    String? name,
    String? currency,
    double? targetAmount,
    double? currentAmount,
    double? targetBaseAmount,
    double? currentBaseAmount,
    DateTime? deadline,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetBaseAmount: targetBaseAmount ?? this.targetBaseAmount,
      currentBaseAmount: currentBaseAmount ?? this.currentBaseAmount,
      deadline: deadline ?? this.deadline,
    );
  }

  // Factory constructor from Firestore
  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unnamed Goal',
      currency: map['currency'] ?? 'USD',
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetBaseAmount: (map['targetBaseAmount'] as num?)?.toDouble() ?? 0.0,
      currentBaseAmount: (map['currentBaseAmount'] as num?)?.toDouble() ?? 0.0,
      deadline: (map['deadline'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 365)),
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