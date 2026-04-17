import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  final FirebaseFirestore _db;
  ProfileService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  DocumentReference _getProfileDocRef(String userId) {
    const String appId = String.fromEnvironment('app_id', defaultValue: 'default-app-id');
    return _db.collection('artifacts').doc(appId)
        .collection('users').doc(userId)
        .collection('profile_data').doc('details_doc');
  }

  Stream<DocumentSnapshot> getProfileStream(String userId) {
    return _getProfileDocRef(userId).snapshots();
  }

  Future<void> updateProfileData(String userId, Map<String, dynamic> data) {
    return _getProfileDocRef(userId).set({
      ...data,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}