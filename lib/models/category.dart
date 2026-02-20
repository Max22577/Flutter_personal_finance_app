
import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  /// Factory constructor to create a Category from a Firestore Document Snapshot.
  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      // The Firestore document ID is used as the Category ID
      id: doc.id,
      // The 'name' field is extracted from the document data
      name: data['name'] as String? ?? 'Unnamed Category', 
    );
  }
}
  