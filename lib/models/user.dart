import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class User {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;

  User({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
  });

  factory User.fromFirebase(firebase_auth.User firebaseUser) {
    return User(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
    );
  }
}
