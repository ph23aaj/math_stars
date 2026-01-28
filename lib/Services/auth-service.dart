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

  String friendlyAuthError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect username or password.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'email-already-in-use':
          return 'That username is already registered.';
        default:
          return e.message ?? 'Authentication error. Please try again.';
      }
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUpParentWithUsername({
    required String parentUsername,
    required String parentPassword,
    required String childUsername,
    required String childPassword,
  }) async {
    final parentLower = _normaliseUsername(parentUsername);
    final childLower = _normaliseUsername(childUsername);

    if (parentLower.isEmpty || childLower.isEmpty) {
      throw Exception('Please enter both parent and child usernames.');
    }
    if (parentPassword.length < 4) {
      throw Exception('Parent password/PIN must be at least 4 characters.');
    }
    if (childPassword.isEmpty) {
      throw Exception('Please enter your child’s password/PIN.');
    }

    // 1) Verify child account exists by checking username mapping
    final childUsernameDoc = await _db.collection('usernames').doc(childLower).get();
    if (!childUsernameDoc.exists) {
      throw Exception('Child username not found.');
    }

    final childUid = childUsernameDoc.data()?['uid'] as String?;
    final childRole = childUsernameDoc.data()?['role'] as String?;
    if (childUid == null || childRole != 'student') {
      throw Exception('That child username is not a student account.');
    }

    // 2) Verify the child's password/PIN is correct (sign in briefly)
    final childEmail = _emailForUsername(childLower);

    User? currentBefore = _auth.currentUser;

    try {
      await _auth.signInWithEmailAndPassword(email: childEmail, password: childPassword);
    } on FirebaseAuthException {
      throw Exception('Child username/password is incorrect.');
    } finally {
      // Return to whatever auth state we had before verifying
      await _auth.signOut();
      if (currentBefore != null) {
        // We don't have the password to restore session; just keep signed out.
        // In your flow, parent is signing up now anyway.
      }
    }

    // 3) Reserve parent username
    final parentUsernameDoc = _db.collection('usernames').doc(parentLower);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(parentUsernameDoc);
      if (snap.exists) {
        throw Exception('That username is already taken.');
      }
      tx.set(parentUsernameDoc, {
        'reserved': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    try {
      // 4) Create parent auth account
      final parentEmail = _emailForUsername(parentLower);

      final cred = await _auth.createUserWithEmailAndPassword(
        email: parentEmail,
        password: parentPassword,
      );

      final parentUid = cred.user!.uid;

      final batch = _db.batch();

      batch.set(_db.collection('users').doc(parentUid), {
        'role': 'parent',
        'username': parentLower,
        'childUid': childUid,
        'childUsername': childLower,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(_db.collection('parents').doc(parentUid), {
        'childUid': childUid,
        'childUsername': childLower,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(parentUsernameDoc, {
        'uid': parentUid,
        'role': 'parent',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return cred;
    } catch (e) {
      await parentUsernameDoc.delete().catchError((_) {});
      rethrow;
    }
  }

}
