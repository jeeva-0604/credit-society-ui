import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';import 'package:credit_society/utils/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../service/apiservice.dart';

class RotatingBorderContainer extends StatefulWidget {
  final Widget child;
  const RotatingBorderContainer({super.key, required this.child});

  @override
  State<RotatingBorderContainer> createState() => _RotatingBorderContainerState();
}

class _RotatingBorderContainerState extends State<RotatingBorderContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Speed of the rotation
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            // ✅ ADD THE BOX SHADOW HERE
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.4), // Fiona Gold Glow
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
            gradient: SweepGradient(
              transform: GradientRotation(_rotationController.value * 2 * 3.14159),
              colors: const [
                AppColors.accent,  // Gold
                AppColors.primary, // Navy
                AppColors.accent,  // Gold
                AppColors.primary, // Navy
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  // --- THEME COLORS ---
  final Color kPrimaryColor = AppColors.primary;
  final Color kSurfaceColor = AppColors.surface;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isOtpSent = false;
  bool _isLoading = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // Speed of the pulse
      vsync: this,
    )..repeat(reverse: true); // ✅ This makes it zoom in and out forever
  }

  @override
  void dispose() {
    _controller.dispose();   // 🔥 THIS LINE FIXES YOUR CRASH
    _phoneController.dispose(); // ✅ good practice
    _otpController.dispose();   // ✅ good practice
    super.dispose();
  }

  // --- HELPER: GENERATE OTP ---
  String generateCustomOtp() {
    return '123456'; // Testing purposes
  }

  // --- HELPER: GENERATE REAL OTP ---
  String generateRealOtp() {
    var rng = Random();
    // Generates a random 6-digit number between 100000 and 999999
    var code = rng.nextInt(900000) + 100000;
    return code.toString();
  }

  // Update this inside _LoginScreenState
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    final phone = _phoneController.text;

    // ✅ Switch logic based on Environment
    // For School 2 (UAT), you might want to use Default OTP to save SMS costs
    bool isProduction = !kDebugMode;

    String otp;
    bool success = false;

    try {
      if (isProduction) {
        otp = generateRealOtp();
        final Uri url = Uri.parse("${ApiService.getBaseUrl()}/sms_gateway/send-otp?phone=$phone&otp=$otp&name=User");
        final response = await http.post(url);
        success = (response.statusCode == 200);
      } else {
        // ✅ Default OTP for testing (123456)
        otp = generateCustomOtp();
        await Future.delayed(const Duration(seconds: 1)); // Mock delay
        success = true;
      }

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_otp', otp);
        await prefs.setString('otp_phone', phone);

        setState(() => _isOtpSent = true);
        _showSnackBar('OTP sent successfully 🎉', AppColors.success);
      }
    } catch (e) {
      _showSnackBar('Error: $e', AppColors.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

// Helper for clean SnackBars
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // --- 2. SETUP FCM TOKEN ---
  Future<String> setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      return token ?? "";
    }

    return "";
  }

  // --- 3. VERIFY OTP LOGIC ---
  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text("Please enter the OTP")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final savedOtp = prefs.getString('pending_otp');

    // Compare the text field with the saved OTP
    if (_otpController.text != savedOtp) {
      setState(() => _isLoading = false); // Stop the loading spinner

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Incorrect OTP. Please check and try again.")
        ),
      );
      return; // 🛑 Stop execution right here! Don't call the API.
    }

    try {
      // final userDetails = await CommonServiceAPI().getLoginOtp(
      //     _phoneController.text,
      //     _otpController.text
      // );
      //
      // if (userDetails != null) {
      //   final prefs = await SharedPreferences.getInstance();
      //   await prefs.setBool('isLoggedIn', true);
      //   await prefs.setString('parent_mobile', userDetails.phone);
      //
      //   if (!kIsWeb) {
      //     try {
      //       String token = await setupPushNotifications();
      //       if (token.isNotEmpty) {
      //         await StudentServiceWeb().uploadFcmToken(token);
      //       }
      //     } catch (e) {
      //       print("FCM Skip/Error: $e");
      //     }
      //   } else {
      //     print("Running on Web: Skipping FCM Token registration for now.");
      //   }
      //
      //   if (!mounted) return;
      //   final provider = Provider.of<UserProvider>(context, listen: false);
      //
      //   // ✅ 1. Give Provider the MAIN user (Admin, Teacher, or Parent)
      //   provider.setLoginData([userDetails], designations: userDetails.allDesignations!);
      //
      //   // ✅ 2. Give Provider the CHILDREN (if they exist)
      //   if (userDetails.profiles != null && userDetails.profiles!.isNotEmpty) {
      //     provider.setStudentProfiles(userDetails.profiles!);
      //   } else {
      //     provider.setStudentProfiles([]);
      //   }

        // ✅ 3. Let the RoleWrapperScreen handle the routing!
        // Navigator.of(context).pushReplacement(
        //   MaterialPageRoute(builder: (context) => const RoleWrapperScreen()),
        // );

      // } else {
      //   if (!mounted) return;
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(backgroundColor: Colors.red, content: Text("Login Failed. Invalid Phone or OTP.")),
      //   );
      // }
    } catch (e) {
      print("Login Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text("An error occurred: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==========================================
  // MAIN BUILD METHOD (Responsive)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurfaceColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // If the screen is wider than 850px, show the Web layout
          if (constraints.maxWidth >= 850) {
            return _buildWebLayout();
          }
          // Otherwise, show the normal Mobile layout
          else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  // ==========================================
  // MOBILE LAYOUT
  // ==========================================
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeaderSection(isWeb: false),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildLoginCard(),
          ),
          const SizedBox(height: 30),
          _buildEnquirySection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================
  // WEB LAYOUT
  // ==========================================
  Widget _buildWebLayout() {
    return Row(
      children: [
        // LEFT SIDE: Full Height Branding
        Expanded(
          flex: 5,
          child: _buildHeaderSection(isWeb: true),
        ),

        Expanded(
          flex: 4,
          child: Align(
            alignment: Alignment.topRight, // Forces it to the top right corner
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 60, right: 60, left: 20),
              child: SizedBox(
                width: 450, // Limits the width of the card on large screens
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLoginCard(),
                    const SizedBox(height: 30),
                    _buildEnquirySection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection({required bool isWeb}) {
    return Container(
      // ✅ INCREASED HEIGHT from 320 to 380 to prevent overflow
      height: isWeb ? double.infinity : 380,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: isWeb
            ? BorderRadius.zero
            : const BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20), // Added padding for safety
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. ROTATING LOGO
            RotatingBorderContainer(
              child: Container(
                width: isWeb ? 300 : 160, // Slightly reduced logo size to save space
                height: isWeb ? 170 : 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.white, AppColors.white],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent, width: 1.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                        'assets/images/login.png',
                        fit: BoxFit.fill),
                  ),
                ),
              ),
            ),


            AnimatedBuilder(
              animation: _controller, // Uses your 3-second splash controller
              builder: (context, child) {
                // This creates a smooth sine wave for the scale (0.98 to 1.02)
                final pulse = 1.0 + (0.02 * sin(_controller.value * 2 * pi));

                return Transform.scale(
                  scale: pulse,
                  child: Column(
                    children: [
                      Text(
                      "DIGITAL EXCELLENCE IN COOPERATIVE BANKING",
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: AppColors.accent.withOpacity(0.5), blurRadius: 10)
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "YOUR TRUSTED PARTNER IN FINANCIAL GROWTH",
                        style: TextStyle(color: AppColors.white70, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "SECURE SCALABLE SOCIETY-FIRST",
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 15,
                            fontStyle: FontStyle.italic
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

// INPUT DECORATION HELPER
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary), // ✅ Navy Icons
      counterText: "",
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5) // ✅ Gold focus border
      ),
    );
  }

  // LOGIN CARD
  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isOtpSent ? "Enter OTP" : "Mobile Number",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 10),

            if (!_isOtpSent)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                // ✅ 1. Physical limit (prevents typing more than 10)
                maxLength: 10,
                inputFormatters: [
                  // ✅ 2. Only allow digits (0-9)
                  FilteringTextInputFormatter.digitsOnly,
                  // ✅ 3. Double-check length limit
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your mobile number';
                  }
                  // ✅ 4. Strict Validation: Must be exactly 10 digits
                  if (value.length != 10) {
                    return 'Mobile number must be exactly 10 digits';
                  }
                  return null;
                },
                decoration: _inputDecoration("9876543210", Icons.phone),
              ),

            if (_isOtpSent)
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Enter OTP", Icons.lock_outline),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_isOtpSent ? _verifyOtp : _sendOtp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isOtpSent ? "Login" : "Get OTP", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),

            if (_isOtpSent)
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isOtpSent = false;
                      _otpController.clear();
                    });
                  },
                  child: Text("Change Number", style: TextStyle(color: kPrimaryColor)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ENQUIRY SECTION
  Widget _buildEnquirySection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Looking for Admission?", style: TextStyle(color: Colors.grey)),

      ],
    );
  }
}
