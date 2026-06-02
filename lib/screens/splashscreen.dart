import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:credit_society/utils/app_colors.dart';
import 'package:credit_society/service/auth_service.dart';
import 'package:shimmer/shimmer.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _fadeOutController;
  late Animation<double> _fadeOutAnimation;
  final Color kPrimaryColor = AppColors.primary;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    _fadeOutController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeOutAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_fadeOutController);

    // 🔥 AUTO LOGIN + NAVIGATION AFTER 3 SECONDS
    Future.delayed(const Duration(seconds: 3), () async {
      // Obtain a JWT token before entering the app.
      // ⚠️ Replace the credentials below with the actual admin account.
      await AuthService().login("admin@society.com", "admin123");
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CHANGED: Use a professional dark blue background
      backgroundColor: AppColors.primary,
      body: AnimatedBuilder(
        animation: _fadeOutAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeOutAnimation.value,
            child: FadeTransition(
              opacity: _animation,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: AppColors.primary, // Keeping it consistent
                child: Center(
                  child: Column(
                    // Ensure everything is centered
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ✅ 1. BRANDED LOGO CONTAINER
                      Container(
                        width: kIsWeb ? 250 : 160,
                        height: kIsWeb ? 140 : 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Image.asset(
                            'assets/images/login.png',
                            fit: BoxFit.contain, // Contain looks more professional for logos
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ✅ 2. Shimmer Society Name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Shimmer.fromColors(
                          baseColor: AppColors.white,
                          highlightColor: AppColors.accent, // Gold shimmer
                          period: const Duration(seconds: 3),
                          child: const Text(
                            "LARSEN & TOUBRO GROUP EMPLOYEES\nCOOPERATIVE THRIFT & CREDIT SOCIETY LTD",
                            textAlign: TextAlign.center, // Center alignment
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),

                      // ✅ 3. Pulse Taglines
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final pulse = 1.0 + (0.02 * sin(_controller.value * 2 * pi * 2));

                          return Transform.scale(
                            scale: pulse,
                            child: Column(
                              children: [
                                Text(
                                  "DIGITAL EXCELLENCE IN COOPERATIVE BANKING",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.accent, // Gold
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "YOUR TRUSTED PARTNER IN FINANCIAL GROWTH",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.white70,
                                    fontSize: 13,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Attribute row centered
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("SECURE", style: TextStyle(color: AppColors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                                    Text("  •  ", style: TextStyle(color: AppColors.white54)),
                                    Text("SCALABLE", style: TextStyle(color: AppColors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                                    Text("  •  ", style: TextStyle(color: AppColors.white54)),
                                    Text("SOCIETY-FIRST", style: TextStyle(color: AppColors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}

class PulseText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const PulseText({super.key, required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.95, end: 1.05), // Zoom range (95% to 105%)
      duration: const Duration(seconds: 2), // Speed of one pulse
      curve: Curves.easeInOutSine,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      onEnd: () {
        // This creates the infinite loop
      },
      // Using a key and logic to force a rebuild for infinite animation
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }
}