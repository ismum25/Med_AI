import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String role;
  final String userId;
  AuthAuthenticated({required this.role, required this.userId});
  @override
  List<Object?> get props => [role, userId];
}

class AuthRegistered extends AuthState {
  final UserEntity user;
  AuthRegistered(this.user);
}

class AuthLoggedOut extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
