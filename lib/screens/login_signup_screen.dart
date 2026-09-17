import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginSignUpScreen extends StatefulWidget {
  final bool isModal;
  const LoginSignUpScreen({super.key, this.isModal = false});

  @override
  State<LoginSignUpScreen> createState() => _LoginSignUpScreenState();
}

class _LoginSignUpScreenState extends State<LoginSignUpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Login Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;

  // Signup Controllers (Minimal info: Name, Email, Password)
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  bool _obscureSignupPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    super.dispose();
  }

  void _proceedToApp() {
    if (widget.isModal) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthService>();
    final success = await auth.signInWithGoogle();
    if (success && mounted) {
      _proceedToApp();
    }
  }

  Future<void> _handleEmailLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final success = await auth.signInWithEmail(
      email: _loginEmailController.text,
      password: _loginPasswordController.text,
    );
    if (success && mounted) {
      _proceedToApp();
    }
  }

  Future<void> _handleEmailSignup() async {
    if (!_signupFormKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final success = await auth.signUpWithEmail(
      email: _signupEmailController.text,
      password: _signupPasswordController.text,
      displayName: _signupNameController.text,
    );

    if (success && mounted) {
      // Show Verification Sent Dialog
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read_rounded, color: Color(0xFF10B981), size: 28),
              SizedBox(width: 10),
              Text('Verify Your Email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to PowerNews, ${_signupNameController.text.trim().isEmpty ? "Executive" : _signupNameController.text.trim()}!',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'We have sent a verification email to ${_signupEmailController.text.trim()}. Open the email and tap the verification button to activate full security.',
                style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF047857)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can start exploring all power briefings right away!',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF047857), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Start Reading', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (mounted) {
        _proceedToApp();
      }
    }
  }

  void _handleForgotPassword() async {
    final emailController = TextEditingController(text: _loginEmailController.text);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your registered email address and we will send you a password reset button.',
              style: TextStyle(fontSize: 12.5, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                await context.read<AuthService>().sendPasswordReset(email);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password reset link sent to $email')),
                  );
                }
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Brand Logo & Title
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PowerNews',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Curated Indian Power Sector Intelligence',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Auth Box
                  Container(
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Google One-Tap Sign In
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: auth.isLoading ? null : _handleGoogleSignIn,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              side: BorderSide(color: borderColor, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                  width: 20,
                                  height: 20,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata_rounded, size: 24, color: Color(0xFF4285F4)),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Divider OR
                        Row(
                          children: [
                            Expanded(child: Divider(color: borderColor)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR EMAIL',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: borderColor)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Tab Switcher (Sign In vs Create Account)
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: Colors.white,
                            unselectedLabelColor: textSecondary,
                            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            tabs: const [
                              Tab(text: 'Sign In'),
                              Tab(text: 'Create Account'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Error Banner
                        if (auth.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    auth.errorMessage!,
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // TabBarView for Login vs Signup Forms
                        SizedBox(
                          height: 230,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // 1. Sign In Form
                              Form(
                                key: _loginFormKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _loginEmailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        labelText: 'Email Address',
                                        prefixIcon: const Icon(Icons.email_outlined, size: 18),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _loginPasswordController,
                                      obscureText: _obscureLoginPassword,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                                        suffixIcon: IconButton(
                                          icon: Icon(_obscureLoginPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                                          onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      validator: (val) => val == null || val.length < 6 ? 'Password min 6 chars' : null,
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _handleForgotPassword,
                                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                        child: const Text('Forgot Password?', style: TextStyle(fontSize: 11.5)),
                                      ),
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: ElevatedButton(
                                        onPressed: auth.isLoading ? null : _handleEmailLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2563EB),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: auth.isLoading
                                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 2. Create Account Form (Minimal: Name, Email, Password)
                              Form(
                                key: _signupFormKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _signupNameController,
                                      decoration: InputDecoration(
                                        labelText: 'Your Name / Title',
                                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter your name' : null,
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _signupEmailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        labelText: 'Work / Personal Email',
                                        prefixIcon: const Icon(Icons.email_outlined, size: 18),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _signupPasswordController,
                                      obscureText: _obscureSignupPassword,
                                      decoration: InputDecoration(
                                        labelText: 'Create Password (6+ chars)',
                                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                                        suffixIcon: IconButton(
                                          icon: Icon(_obscureSignupPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                                          onPressed: () => setState(() => _obscureSignupPassword = !_obscureSignupPassword),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      validator: (val) => val == null || val.length < 6 ? 'Password min 6 chars' : null,
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: ElevatedButton(
                                        onPressed: auth.isLoading ? null : _handleEmailSignup,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10B981),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: auth.isLoading
                                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Guest Bypass Option
                  TextButton.icon(
                    onPressed: () {
                      context.read<AuthService>().continueAsGuest();
                      _proceedToApp();
                    },
                    icon: Icon(Icons.arrow_forward_rounded, size: 16, color: textSecondary),
                    label: Text(
                      'Explore as Guest without Signing In',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
