class UserModel {
  final String id;
  final String name;
  final String email;
  final String gender;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      gender: json['gender'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'gender': gender};
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email ,gender: $gender) ';
  }
}
