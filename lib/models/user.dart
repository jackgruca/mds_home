// Update lib/models/user.dart
class User {
  final String id;
  final String name;
  final String email;
  final bool isSubscribed;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String? resetToken;
  final DateTime? resetTokenExpiry;
  final List<String>? favoriteTeams;
  final Map<String, dynamic>? draftPreferences;
  final List<dynamic>? customDraftData; // Changed to List<dynamic>?

  User({
    required this.id,
    required this.name,
    required this.email,
    this.isSubscribed = false,
    required this.createdAt,
    required this.lastLoginAt,
    this.resetToken,
    this.resetTokenExpiry,
    this.favoriteTeams,
    this.draftPreferences,
    this.customDraftData, // Added this parameter
  });

  // Update factory constructor
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      isSubscribed: json['isSubscribed'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: DateTime.parse(json['lastLoginAt']),
      resetToken: json['resetToken'],
      resetTokenExpiry: json['resetTokenExpiry'] != null 
          ? DateTime.parse(json['resetTokenExpiry']) 
          : null,
      favoriteTeams: json['favoriteTeams'] != null
          ? List<String>.from(json['favoriteTeams'])
          : null,
      draftPreferences: json['draftPreferences'],
      customDraftData: json['customDraftData'], // Added this field
    );
  }

  // Update toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isSubscribed': isSubscribed,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'resetToken': resetToken,
      'resetTokenExpiry': resetTokenExpiry?.toIso8601String(),
      'favoriteTeams': favoriteTeams,
      'draftPreferences': draftPreferences,
      'customDraftData': customDraftData, // Added this field
    };
  }

  // Update copyWith method
  User copyWith({
    String? id,
    String? name,
    String? email,
    bool? isSubscribed,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? resetToken,
    DateTime? resetTokenExpiry,
    List<String>? favoriteTeams,
    Map<String, dynamic>? draftPreferences,
    List<dynamic>? customDraftData, // Added this parameter
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      resetToken: resetToken ?? this.resetToken,
      resetTokenExpiry: resetTokenExpiry ?? this.resetTokenExpiry,
      favoriteTeams: favoriteTeams ?? this.favoriteTeams,
      draftPreferences: draftPreferences ?? this.draftPreferences,
      customDraftData: customDraftData ?? this.customDraftData, // Added this field
    );
  }
}