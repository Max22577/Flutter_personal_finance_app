import 'package:cloud_firestore/cloud_firestore.dart';


class SavingsGoal {
  final String? id;
  final String name;
  final double targetAmount;
  final double currentAmount; // Tracks total amount saved towards this goal
  final DateTime deadline;

  SavingsGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
  });

  // Factory constructor from Firestore
  factory SavingsGoal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavingsGoal(
      id: doc.id,
      name: data['name'] ?? 'New Goal',
      targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0.0,
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 365)),
    );
  }

  // Convert SavingsGoal object to a map for Firestore storage
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount, 
      'deadline': Timestamp.fromDate(deadline),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}