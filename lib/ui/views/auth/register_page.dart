import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

class RegisterPage extends StatefulWidget {
  final Future<void> Function() onRegisterSuccess;
  final Future<void> Function()? onRetryStartup;
  final VoidCallback onNavigateToLogin;
  final bool isLoading;
  final bool canRetryStartup;
  final String? errorMessage;

  const RegisterPage({
    super.key,
    required this.onRegisterSuccess,
    this.onRetryStartup,
    required this.onNavigateToLogin,
    required this.isLoading,
    this.canRetryStartup = false,
    required this.errorMessage,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  Future<void> _handleGoogleSignUp() async {
    await widget.onRegisterSuccess();
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
                      'Create Your Account',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign up with Google to get started!',
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

                    // Google Sign Up Button.
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: const RoundedRectangleBorder(
                          borderRadius: kRadiusSmall,
                        ),
                      ),
                        onPressed: widget.isLoading ? null : _handleGoogleSignUp,
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
                              'Sign up with Google',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Benefits section.
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: kRadiusSmall,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Why sign up?',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _BenefitRow(
                            icon: Icons.check_circle_outline,
                            text: 'Centralize all your orders in one place',
                          ),
                          const SizedBox(height: 8),
                          _BenefitRow(
                            icon: Icons.check_circle_outline,
                            text: 'Get real-time delivery & financial insights',
                          ),
                          const SizedBox(height: 8),
                          _BenefitRow(
                            icon: Icons.check_circle_outline,
                            text: 'Manage coupons and checkout links easily',
                          ),
                        ],
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

                    // Sign In Link.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onNavigateToLogin,
                          child: Text(
                            'Sign in',
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

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.deliveredText,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
