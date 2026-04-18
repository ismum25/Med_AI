import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../injection_container.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  String _role = 'patient';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Register')),
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthRegistered) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Registration successful! Please login.')),
              );
              context.go(AppRoutes.login);
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          enabled: !isLoading,
                          decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                          validator: (v) => Validators.required(v, 'Full name'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailCtrl,
                          enabled: !isLoading,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordCtrl,
                          enabled: !isLoading,
                          decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                          obscureText: true,
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _role,
                          decoration: const InputDecoration(labelText: 'Role'),
                          items: const [
                            DropdownMenuItem(value: 'patient', child: Text('Patient')),
                            DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                          ],
                          onChanged: isLoading ? null : (v) => setState(() => _role = v!),
                        ),
                        if (_role == 'doctor') ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _specializationCtrl,
                            enabled: !isLoading,
                            decoration: const InputDecoration(labelText: 'Specialization'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _licenseCtrl,
                            enabled: !isLoading,
                            decoration: const InputDecoration(labelText: 'License Number'),
                            validator: _role == 'doctor' ? (v) => Validators.required(v, 'License number') : null,
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AuthBloc>().add(RegisterEvent(
                                          email: _emailCtrl.text.trim(),
                                          password: _passwordCtrl.text,
                                          role: _role,
                                          fullName: _nameCtrl.text.trim(),
                                          specialization: _specializationCtrl.text.isNotEmpty
                                              ? _specializationCtrl.text
                                              : null,
                                          licenseNumber: _licenseCtrl.text.isNotEmpty
                                              ? _licenseCtrl.text
                                              : null,
                                        ));
                                  }
                                },
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Register'),
                        ),
                        TextButton(
                          onPressed: isLoading ? null : () => context.go(AppRoutes.login),
                          child: const Text('Already have an account? Login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
