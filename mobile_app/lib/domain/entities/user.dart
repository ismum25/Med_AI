class UserEntity {
  final String id;
  final String email;
  final String role;
  final bool isActive;

  const UserEntity({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
  });
}
