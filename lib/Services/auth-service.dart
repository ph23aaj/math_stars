import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  String _normaliseUsername(String username) => username.trim().toLowerCase();

  String _emailForUsername(String usernameLower) =>
      '$usernameLower@mathsstars.local';

  Future<UserCredential> signInWithUsername({
    required String username,
    required String password,
  }) async {
    final u = _normaliseUsername(username);
    final email = _emailForUsername(u);

    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUpStudentWithUsername({
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String className,
  }) async {
    final usernameLower = _normaliseUsername(username);

    if (usernameLower.isEmpty) {
      throw Exception('Username cannot be empty.');
    }
    if (password.length < 4) {
      throw Exception('Password/PIN must be at least 4 characters.');
    }

    final usernameDoc = _db.collection('usernames').doc(usernameLower);

    // Reserve username atomically
    await _db.runTransaction((tx) async {
      final snap = await tx.get(usernameDoc);
      if (snap.exists) {
        throw Exception('That username is already taken.');
      }
      tx.set(usernameDoc, {
        'reserved': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    try {
      final email = _emailForUsername(usernameLower);

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      final batch = _db.batch();

      batch.set(_db.collection('users').doc(uid), {
        'role': 'student',
        'username': usernameLower,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(_db.collection('students').doc(uid), {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'className': className.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(_db.collection('progress').doc(uid), {
        'totalGamesPlayed': 0,
        'totalCorrect': 0,
        'totalIncorrect': 0,
        'lastPlayedAt': null,
        'byGame': {},
      });

      batch.set(usernameDoc, {
        'uid': uid,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return cred;
    } catch (e) {
      // Clean up reserved username if sign-up fails
      await usernameDoc.delete().catchError((_) {});
      rethrow;
    }
  }
}
