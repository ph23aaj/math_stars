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
    final classId = _normaliseClassName(className);

    final classDoc = await _db.collection('classes').doc(classId).get();
    if (!classDoc.exists) {
      throw Exception('That class does not exist. Ask your teacher for the exact class name.');
    }

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
        'classId': classId,
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

    // Fetch child's name from students/{childUid}
    final studentSnap = await _db.collection('students').doc(childUid).get();
    final studentData = studentSnap.data() ?? {};

    final childFirstName = (studentData['firstName'] ?? '').toString().trim();
    final childLastName = (studentData['lastName'] ?? '').toString().trim();

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
      // Return to whatever auth state I had before verifying
      await _auth.signOut();
      if (currentBefore != null) {
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

        // If you want to keep single-child for now:
        'childUid': childUid,
        'childUsername': childLower,
        'childFirstName': childFirstName,
        'childLastName': childLastName,

        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(_db.collection('parents').doc(parentUid), {
        'childUid': childUid,
        'childUsername': childLower,
        'childFirstName': childFirstName,
        'childLastName': childLastName,

        'createdAt': FieldValue.serverTimestamp(),
      });


      batch.set(parentUsernameDoc, {
        'uid': parentUid,
        'role': 'parent',
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(
        _db.collection('parents').doc(parentUid).collection('children').doc(childUid),
        {
          'childUid': childUid,
          'childUsername': childLower,
          'linkedAt': FieldValue.serverTimestamp(),
        },
      );

      final studentDoc =
      await _db.collection('students').doc(childUid).get();

      final studentData = studentDoc.data() ?? {};
      final firstName = (studentData['firstName'] ?? '').toString();
      final lastName = (studentData['lastName'] ?? '').toString();

      batch.set(
        _db
            .collection('parents')
            .doc(parentUid)
            .collection('children')
            .doc(childUid),
        {
          'childUid': childUid,
          'childUsername': childLower,
          'childFirstName': firstName,
          'childLastName': lastName,
          'linkedAt': FieldValue.serverTimestamp(),
        },
      );



      await batch.commit();
      return cred;
    } catch (e) {
      await parentUsernameDoc.delete().catchError((_) {});
      rethrow;
    }
  }


  Future<UserCredential> signUpTeacherWithUsername({
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String className,
  }) async {
    final usernameLower = _normaliseUsername(username);
    final classNameClean = className.trim();
    final classId = _normaliseClassName(classNameClean);
    final classDoc = _db.collection('classes').doc(classId);



    if (usernameLower.isEmpty) throw Exception('Username cannot be empty.');
    if (firstName.trim().isEmpty) throw Exception('First name cannot be empty.');
    if (lastName.trim().isEmpty) throw Exception('Last name cannot be empty.');
    if (classNameClean.isEmpty) throw Exception('Class name cannot be empty.');
    if (password.length < 4) throw Exception('Password/PIN must be at least 4 characters.');

    final usernameDoc = _db.collection('usernames').doc(usernameLower);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(usernameDoc);
      if (snap.exists) throw Exception('That username is already taken.');
      tx.set(usernameDoc, {
        'reserved': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    try {
      final email = _emailForUsername(usernameLower);

      final existing = await classDoc.get();
      if (existing.exists) {
        throw Exception('That class name already exists. Choose another.');
      }

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      final batch = _db.batch();

      batch.set(_db.collection('users').doc(uid), {
        'role': 'teacher',
        'username': usernameLower,
        'classId': classId,
        'className': classNameClean,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(_db.collection('teachers').doc(uid), {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'classId': classId,
        'className': classNameClean,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(classDoc, {
        'className': classNameClean,
        'classId': classId,
        'teacherUid': uid,
        'teacherUsername': usernameLower,
        'createdAt': FieldValue.serverTimestamp(),
      });


      batch.set(usernameDoc, {
        'uid': uid,
        'role': 'teacher',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return cred;
    } catch (e) {
      await usernameDoc.delete().catchError((_) {});
      rethrow;
    }
  }

  String _normaliseClassName(String className) =>
      className.trim().toLowerCase();

}
