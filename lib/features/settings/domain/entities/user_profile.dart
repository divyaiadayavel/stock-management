class UserProfile {
  final int id;
  final String name;
  final String role;
  final String profilePicture;

  const UserProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.profilePicture,
  });

  UserProfile copyWith({
    int? id,
    String? name,
    String? role,
    String? profilePicture,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }
}