import 'package:flutter/material.dart';
import 'package:snapalyze/models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? currentUser;
  void setUser(UserModel user) {
    currentUser = user;
    notifyListeners();
  }
}
