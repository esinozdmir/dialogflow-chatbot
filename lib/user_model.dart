import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    return UserModel(
      id: doc.id,
      name: doc['name'],
      email: doc['email'],
      gender: doc['gender'],
    );
  }
}
