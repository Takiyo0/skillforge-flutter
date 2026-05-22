import 'dart:convert';

class UserPreference {
  UserPreference({
    required this.darkModeEnabled,
    required this.preferredLocale,
    required this.onboardingCompleted,
  });

  final bool darkModeEnabled;
  final String preferredLocale;
  final bool onboardingCompleted;

  UserPreference copyWith({
    bool? darkModeEnabled,
    String? preferredLocale,
    bool? onboardingCompleted,
  }) => UserPreference(
    darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
    preferredLocale: preferredLocale ?? this.preferredLocale,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
  );

  factory UserPreference.fromJson(Map<String, dynamic> json) => UserPreference(
    darkModeEnabled: json['darkModeEnabled'] == true,
    preferredLocale: (json['preferredLocale'] ?? 'en') as String,
    onboardingCompleted: json['onboardingCompleted'] == true,
  );
}

class User {
  User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.roles,
    required this.preference,
    required this.bio,
    this.avatarS3Key,
  });

  final String id;
  final String email;
  final String displayName;
  final String bio;
  final String? avatarS3Key;
  final List<String> roles;
  final UserPreference preference;

  User copyWith({
    String? email,
    String? displayName,
    String? bio,
    String? avatarS3Key,
    List<String>? roles,
    UserPreference? preference,
  }) => User(
    id: id,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    bio: bio ?? this.bio,
    avatarS3Key: avatarS3Key ?? this.avatarS3Key,
    roles: roles ?? this.roles,
    preference: preference ?? this.preference,
  );

  factory User.fromJson(Map<String, dynamic> json) {
    final roles = (json['roles'] as List<dynamic>? ?? const [])
        .map((e) => e.toString().toLowerCase())
        .toList();

    return User(
      id: json['id'].toString(),
      email: (json['email'] ?? '') as String,
      displayName: (json['displayName'] ?? '') as String,
      bio: (json['bio'] ?? '') as String,
      avatarS3Key: json['avatarS3Key'] as String?,
      roles: roles,
      preference: UserPreference.fromJson(
        (json['preference'] as Map<String, dynamic>? ?? const {}),
      ),
    );
  }
}

class AuthResponse {
  AuthResponse({required this.accessToken, required this.user});

  final String accessToken;
  final User user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken: (json['accessToken'] ?? '') as String,
    user: User.fromJson(json['user'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> decodeObject(String body) =>
    jsonDecode(body) as Map<String, dynamic>;
