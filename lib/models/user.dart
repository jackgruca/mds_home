// lib/models/user.dart
class User {
  final String uid;
  final String name;
  final String email;
  final bool isSubscribed;
  final Map<String, dynamic>? preferences;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? photoUrl;

  User({
    required this.uid,
    required this.name,
    required this.email,
    this.isSubscribed = false,
    this.preferences,
    required this.createdAt,
    this.lastLoginAt,
    this.photoUrl,
  });

  factory User.fromFirestore(Map<String, dynamic> data, String id) {
    return User(
      uid: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      isSubscribed: data['isSubscribed'] ?? false,
      preferences: data['preferences'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      lastLoginAt: data['lastLoginAt']?.toDate(),
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'isSubscribed': isSubscribed,
      'preferences': preferences ?? {},
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
      'photoUrl': photoUrl,
    };
  }

  User copyWith({
    String? uid,
    String? name,
    String? email,
    bool? isSubscribed,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? photoUrl,
  }) {
    return User(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}