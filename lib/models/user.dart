// lib/models/user.dart
class User {
  final String id;
  final String name;
  final String email;
  final bool isSubscribed;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.isSubscribed = false,
    required this.createdAt,
    required this.lastLoginAt,
  });

  // Factory constructor to create a User from a Map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      isSubscribed: json['isSubscribed'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: DateTime.parse(json['lastLoginAt']),
    );
  }

  // Convert User to a Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isSubscribed': isSubscribed,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  // Create a copy of the user with some updated fields
  User copyWith({
    String? id,
    String? name,
    String? email,
    bool? isSubscribed,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}