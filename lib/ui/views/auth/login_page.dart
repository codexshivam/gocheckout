import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

class LoginPage extends StatefulWidget {
  final Future<void> Function() onLoginSuccess;
  final Future<void> Function()? onRetryStartup;
  final VoidCallback onNavigateToRegister;
  final bool isLoading;
  final bool canRetryStartup;
  final String? errorMessage;

  const LoginPage({
    super.key,
    required this.onLoginSuccess,
    this.onRetryStartup,
    required this.onNavigateToRegister,
    required this.isLoading,
    this.canRetryStartup = false,
    required this.errorMessage,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Future<void> _handleGoogleSignIn() async {
    await widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo / Branding.
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.black,
                              borderRadius: kRadiusSmall,
                            ),
                            child: const Center(
                              child: Text(
                                'GC',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'GoCheckout',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Merchant Portal',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Heading.
                    Text(
                      'Welcome Back',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in with your Google account to access your store',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Error message.
                    if (widget.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.rtoBg,
                          border: Border.all(color: AppColors.rtoText),
                          borderRadius: kRadiusSmall,
                        ),
                        child: Text(
                          widget.errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.rtoText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (widget.onRetryStartup != null) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: widget.canRetryStartup && !widget.isLoading
                              ? widget.onRetryStartup
                              : null,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Startup Check'),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],

                    // Google Sign In Button.
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: const RoundedRectangleBorder(
                          borderRadius: kRadiusSmall,
                        ),
                      ),
                        onPressed: widget.isLoading ? null : _handleGoogleSignIn,
                        child: widget.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(AppColors.white),
                              ),
                            )
                          : Text(
                              'Sign in with Google',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: AppColors.border,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: AppColors.border,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Sign Up Link.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onNavigateToRegister,
                          child: Text(
                            'Sign up',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.black,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
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
        ),
      ),
    );
  }
}
