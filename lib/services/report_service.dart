import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> reportQuestion({
    required String questionId,
    required String reason,
    String? details,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    await _db.collection('question_reports').add({
      'questionId': questionId,
      'userId': userId,
      'reason': reason,
      'details': details,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
