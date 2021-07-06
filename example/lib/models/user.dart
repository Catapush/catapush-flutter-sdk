import 'dart:convert';

import 'package:equatable/equatable.dart';

class User extends Equatable{
  static const empty = User(identifier: '', password: '');

  const User({
    required this.identifier,
    required this.password,
  });

  final String identifier;
  final String password;

  factory User.fromJson(String str) => User.fromMap(json.decode(str) as Map<String, dynamic>);

  String toJson() => json.encode(toMap());

  factory User.fromMap(Map<String, dynamic> json) => User(
    identifier: json['identifier'] as String,
    password: json['password'] as String,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'identifier': identifier,
    'password': password,
  };

  @override
  List<Object?> get props => [identifier, password];
}
