import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GameLogService {
  GameLogService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _logRef(String uid, String logId) =>
      _db.collection('students').doc(uid).collection('gameLogs').doc(logId);

  Future<String> createLog({
    required String gameId,
    required String gameName,
    required int level,
    required int totalQuestions,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in.');

    final doc = _db.collection('students').doc(uid).collection('gameLogs').doc();

    await doc.set({
      'gameId': gameId,
      'gameName': gameName,
      'level': level,
      'totalQuestions': totalQuestions,
      'questionIndex': 1,
      'correct': 0,
      'incorrect': 0,
      'status': 'in_progress',
      'startedAt': FieldValue.serverTimestamp(),
      'endedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'questions': <Map<String, dynamic>>[],
    });

    return doc.id;
  }

  Future<void> updateAfterQuestion({
    required String logId,
    required int questionIndex,
    required int correct,
    required int incorrect,
    required Map<String, dynamic> questionLog,
    required List<Map<String, dynamic>> allQuestionsSoFar,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in.');

    // We write the whole list each time (only 5 questions, so it’s fine and keeps order).
    await _logRef(uid, logId).set({
      'questionIndex': questionIndex,
      'correct': correct,
      'incorrect': incorrect,
      'questions': allQuestionsSoFar,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markCompleted({
    required String logId,
    required int correct,
    required int incorrect,
    required int avgTimeMs,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in.');

    await _logRef(uid, logId).set({
      'correct': correct,
      'incorrect': incorrect,
      'avgTimeMs': avgTimeMs,
      'status': 'completed',
      'endedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markAbandoned({
    required String logId,
    required int correct,
    required int incorrect,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in.');

    await _logRef(uid, logId).set({
      'correct': correct,
      'incorrect': incorrect,
      'status': 'abandoned',
      'endedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
