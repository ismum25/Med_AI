import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;
  LoginEvent({
    required this.email,
    required this.password,
    this.rememberMe = true,
  });
  @override
  List<Object?> get props => [email, password, rememberMe];
}

class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String role;
  final String fullName;
  final String? specialization;
  final String? licenseNumber;
  RegisterEvent({
    required this.email,
    required this.password,
    required this.role,
    required this.fullName,
    this.specialization,
    this.licenseNumber,
  });
}

class LogoutEvent extends AuthEvent {}
