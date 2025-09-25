import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:snapalyze/models/user_model.dart';

class FirebaseService {
  static CollectionReference<UserModel> getUsersCollection() =>
      FirebaseFirestore.instance
          .collection('users')
          .withConverter(
            fromFirestore: (docSnapshot, _) =>
                UserModel.fromJson(docSnapshot.data()!),
            toFirestore: (user, _) => user.toJson(),
          );

  static Future<UserModel> register({
    required String name,
    required String password,
    required String email,
    required String gender,
  }) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      log(userCredential.user!.uid);

      UserModel userModel = UserModel(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        gender: gender,
      );

      CollectionReference<UserModel> usersCollection = getUsersCollection();
      await usersCollection.doc(userModel.id).set(userModel);

      return userModel;
    } catch (error) {
      log('Firebase registration error: ${error.toString()}');

      String errorMessage = 'Registration failed. Please try again.';

      if (error is FirebaseAuthException) {
        switch (error.code) {
          case 'email-already-in-use':
            errorMessage = 'This email is already registered.';
            break;
          case 'invalid-email':
            errorMessage = 'Please enter a valid email address.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Email/password accounts are not enabled.';
            break;
          case 'weak-password':
            errorMessage = 'Password is too weak.';
            break;
          default:
            errorMessage = error.message ?? 'Registration failed.';
        }
      } else if (error is FirebaseException) {
        errorMessage = error.message ?? 'Firebase error occurred.';
      }
      throw Exception(errorMessage);
    }
  }

  static Future<UserModel> logIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      CollectionReference<UserModel> usersCollection = getUsersCollection();
      DocumentSnapshot<UserModel> docSnapshot = await usersCollection
          .doc(userCredential.user!.uid)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return docSnapshot.data()!;
      } else {
        throw Exception('User data not found. Please contact support.');
      }
    } on FirebaseAuthException catch (e) {
      log('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } on FirebaseException catch (e) {
      log('Firestore Error: ${e.code} - ${e.message}');
      throw Exception('Failed to access user data. Please try again.');
    } catch (e) {
      log('Unexpected error during login: $e');

      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  static Future<void> signOut() => FirebaseAuth.instance.signOut();
}
