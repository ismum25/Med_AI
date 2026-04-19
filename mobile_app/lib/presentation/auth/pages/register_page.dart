import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/underline_text_field.dart';
import '../../../core/widgets/wave_background.dart';
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
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  String _role = 'patient';
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _specializationCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.surfaceContainerLowest,
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthRegistered) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Registration successful! Please sign in.'),
                ),
              );
              context.go(AppRoutes.login);
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            final screenHeight = MediaQuery.of(context).size.height;
            return SizedBox.expand(
              child: Stack(
                children: [
                  WaveBackground(
                    height: screenHeight * 0.22,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.go(AppRoutes.login),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.20,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Create Account',
                              style: GoogleFonts.manrope(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _RoleCard(
                                    icon: Icons.person_outline_rounded,
                                    label: 'Patient',
                                    subtitle: 'Manage your health',
                                    isSelected: _role == 'patient',
                                    onTap: isLoading
                                        ? null
                                        : () => setState(
                                            () => _role = 'patient'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _RoleCard(
                                    icon: Icons.medical_services_outlined,
                                    label: 'Doctor',
                                    subtitle: 'Care for patients',
                                    isSelected: _role == 'doctor',
                                    onTap: isLoading
                                        ? null
                                        : () =>
                                            setState(() => _role = 'doctor'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            UnderlineTextField(
                              controller: _nameCtrl,
                              enabled: !isLoading,
                              label: 'Full Name',
                              icon: Icons.person_outline_rounded,
                              validator: (v) =>
                                  Validators.required(v, 'Full name'),
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 20),
                            UnderlineTextField(
                              controller: _emailCtrl,
                              enabled: !isLoading,
                              label: 'Email',
                              icon: Icons.mail_outline_rounded,
                              validator: Validators.email,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 20),
                            UnderlineTextField(
                              controller: _passwordCtrl,
                              enabled: !isLoading,
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscure,
                              validator: Validators.password,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.onSurfaceVariant,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: _role == 'doctor'
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const SizedBox(height: 20),
                                        UnderlineTextField(
                                          controller: _specializationCtrl,
                                          enabled: !isLoading,
                                          label: 'Specialization',
                                          icon: Icons.biotech_outlined,
                                          validator: _role == 'doctor'
                                              ? (v) => Validators.required(
                                                  v, 'Specialization')
                                              : null,
                                        ),
                                        const SizedBox(height: 20),
                                        UnderlineTextField(
                                          controller: _licenseCtrl,
                                          enabled: !isLoading,
                                          label: 'License Number',
                                          icon: Icons.badge_outlined,
                                          validator: _role == 'doctor'
                                              ? (v) => Validators.required(
                                                  v, 'License number')
                                              : null,
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 28),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize:
                                    const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: AppColors.primary
                                    .withValues(alpha: 0.5),
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        context.read<AuthBloc>().add(
                                              RegisterEvent(
                                                email:
                                                    _emailCtrl.text.trim(),
                                                password: _passwordCtrl.text,
                                                role: _role,
                                                fullName:
                                                    _nameCtrl.text.trim(),
                                                specialization:
                                                    _specializationCtrl
                                                            .text.isNotEmpty
                                                        ? _specializationCtrl
                                                            .text
                                                        : null,
                                                licenseNumber: _licenseCtrl
                                                        .text.isNotEmpty
                                                    ? _licenseCtrl.text
                                                    : null,
                                              ),
                                            );
                                      }
                                    },
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Create Account',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: isLoading
                                      ? null
                                      : () => context.go(AppRoutes.login),
                                  child: Text(
                                    'Sign in',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback? onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryContainer.withValues(alpha: 0.1)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : AppColors.outline.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
