import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressService {
  ProgressService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<void> recordGameResultSimple({
    required String gameId,
    required int correct,
    required int incorrect,
    required int level,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in.');

    final ref = _db.collection('progress').doc(uid);

    await ref.set({
      'totalGamesPlayed': FieldValue.increment(1),
      'totalCorrect': FieldValue.increment(correct),
      'totalIncorrect': FieldValue.increment(incorrect),
      'lastPlayedAt': FieldValue.serverTimestamp(),
      'byGame.$gameId.gamesPlayed': FieldValue.increment(1),
      'byGame.$gameId.correct': FieldValue.increment(correct),
      'byGame.$gameId.incorrect': FieldValue.increment(incorrect),
      'byGame.$gameId.byLevel.level$level.gamesPlayed': FieldValue.increment(1),
      'byGame.$gameId.byLevel.level$level.correct': FieldValue.increment(correct),
      'byGame.$gameId.byLevel.level$level.incorrect': FieldValue.increment(incorrect),
    }, SetOptions(merge: true));
  }


  Future<void> recordGameResult({
    required String gameId, // e.g. "timed_addition"
    required int correct,
    required int incorrect,
    required int level, // 1, 2, 3
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in.');

    final ref = _db.collection('progress').doc(uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        // If for some reason missing, create it
        tx.set(ref, {
          'totalGamesPlayed': 0,
          'totalCorrect': 0,
          'totalIncorrect': 0,
          'lastPlayedAt': null,
          'byGame': {},
        });
      }

      tx.set(ref, {
        'totalGamesPlayed': FieldValue.increment(1),
        'totalCorrect': FieldValue.increment(correct),
        'totalIncorrect': FieldValue.increment(incorrect),
        'lastPlayedAt': FieldValue.serverTimestamp(),

        // Per-game totals (nested map)
        'byGame.$gameId.gamesPlayed': FieldValue.increment(1),
        'byGame.$gameId.correct': FieldValue.increment(correct),
        'byGame.$gameId.incorrect': FieldValue.increment(incorrect),

        // Optional: track per level too
        'byGame.$gameId.byLevel.level$level.gamesPlayed': FieldValue.increment(1),
        'byGame.$gameId.byLevel.level$level.correct': FieldValue.increment(correct),
        'byGame.$gameId.byLevel.level$level.incorrect': FieldValue.increment(incorrect),
      }, SetOptions(merge: true));
    });
  }
}
