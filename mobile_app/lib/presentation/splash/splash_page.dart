import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_routes.dart';
import '../../core/storage/session_persistence.dart';
import '../../core/theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Logo
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // Halo rings
  late final Animation<double> _ring1Scale;
  late final Animation<double> _ring1Opacity;
  late final Animation<double> _ring2Scale;
  late final Animation<double> _ring2Opacity;

  // Brand text
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  String? _targetRoute;
  bool _animDone = false;
  bool _routeReady = false;

  static final _brandStyle = GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -0.5,
  );

  static final _taglineStyle = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.white60,
  );

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Logo: scale 0.82→1.0, opacity 0→1 over first 60%
    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    // Halo ring 1: starts small, expands outward and fades
    _ring1Scale = Tween<double>(begin: 0.5, end: 2.2).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
      ),
    );
    _ring1Opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.7, curve: Curves.easeIn),
      ),
    );

    // Halo ring 2: starts later, expands slower
    _ring2Scale = Tween<double>(begin: 0.4, end: 1.8).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.25, 0.8, curve: Curves.easeOut),
      ),
    );
    _ring2Opacity = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.25, 0.8, curve: Curves.easeIn),
      ),
    );

    // Brand text: slides up + fades in over last 40%
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.58, 0.85, curve: Curves.easeOut),
      ),
    );
    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.58, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animDone = true;
        _maybeNavigate();
      }
    });

    _ctrl.forward();
    _resolveRoute();
  }

  Future<void> _resolveRoute() async {
    final session = await SessionPersistence.loadForStartup();
    String route;
    if (session.token != null && session.role != null) {
      route = session.role == 'doctor'
          ? AppRoutes.doctorDashboard
          : AppRoutes.patientDashboard;
    } else if (session.welcomeSeen != 'true' && session.remember == null) {
      route = AppRoutes.welcome;
    } else {
      route = AppRoutes.login;
    }
    _targetRoute = route;
    _routeReady = true;
    _maybeNavigate();
  }

  void _maybeNavigate() {
    if (_animDone && _routeReady && mounted) {
      // Restore status bar to dark icons for the main app
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ));
      context.go(_targetRoute!);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Halo + logo stack
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ring 2 (outer)
                          Transform.scale(
                            scale: _ring2Scale.value,
                            child: Opacity(
                              opacity: _ring2Opacity.value
                                  .clamp(0.0, 1.0),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Ring 1 (inner)
                          Transform.scale(
                            scale: _ring1Scale.value,
                            child: Opacity(
                              opacity: _ring1Opacity.value
                                  .clamp(0.0, 1.0),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Logo
                          Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoOpacity.value,
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withValues(alpha: 0.18),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.30),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(19),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Brand text
                    FadeTransition(
                      opacity: _textOpacity,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          children: [
                            Text('Health Care', style: _brandStyle),
                            const SizedBox(height: 6),
                            Text(
                              'Your health, our priority',
                              style: _taglineStyle,
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
        ),
      ),
    );
  }
}
