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
    } catch (e) {
      log('Firebase registration error: $e');
      rethrow;
    }
  }
}
