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
    } on FirebaseAuthException catch (e) {
      throw Exception(
        e.code,
      ).toString().replaceFirst('Exception:', '').replaceAll('-', ' ');
    } on FirebaseException catch (e) {
      log('Firestore Error: ${e.code} - ${e.message}');

      throw Exception('Failed to access user data. Please try again.');
    } catch (error) {
      // throw Exception('An unexpected error occurred. Please try again.');
      log('Firebase registration error: ${error.toString()}');

      String errorMessage = 'Registration failed. Please try again.';

      throw Exception(
        errorMessage
            .toString()
            .replaceFirst('Exception:', '')
            .replaceAll('-', ' '),
      );
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
      throw Exception(
        e.code,
      ).toString().replaceFirst('Exception:', '').replaceAll('-', ' ');
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
