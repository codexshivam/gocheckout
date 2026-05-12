import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'shell/portal_shell.dart';
import 'state/auth_state_controller.dart';
import 'state/store_state_controller.dart';
import 'theme/app_theme.dart';
import 'views/auth/login_page.dart';
import 'views/onboarding/onboarding_flow_page.dart';
import 'views/auth/register_page.dart';

/// Set to [true] during UI development to skip the auth flow entirely.
/// Flip back to [false] before committing or testing real auth.
const bool _kBypassAuth = true;

class MerchantPortalApp extends StatelessWidget {
  const MerchantPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ── UI Dev bypass ──────────────────────────────────────────────────────
    if (_kBypassAuth) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GoCheckout Merchant Portal',
        theme: buildAppTheme(),
        home: PortalShell(onLogout: () {}),
      );
    }
    // ── Normal auth-aware routing ──────────────────────────────────────────
    final AuthStateController authController = context.watch<AuthStateController>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GoCheckout Merchant Portal',
      theme: buildAppTheme(),
      home: switch (authController.state) {
        AuthViewState.checking => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        AuthViewState.authenticated => authController.isProfileLoading
            ? const _SyncingGate()
            : (authController.activeStoreId ?? '').isNotEmpty
                ? PortalShell(onLogout: () {
                    final StoreStateController storeController =
                        context.read<StoreStateController>();
                    storeController.clearSessionState().then((_) {
                      authController.logout().then((_) {
                        if (!context.mounted) {
                          return;
                        }
                        if (authController.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(authController.errorMessage!)),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out successfully.')),
                        );
                      });
                    }).catchError((_) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to close live subscriptions before logout.'),
                        ),
                      );
                    });
                  })
                : const OnboardingFlowPage(),
        AuthViewState.unauthenticated => authController.showRegister
            ? RegisterPage(
            onRegisterSuccess: authController.signupWithGoogle,
            onRetryStartup: authController.retryStartupSessionCheck,
                onNavigateToLogin: authController.navigateToLogin,
                isLoading: authController.isLoading,
                canRetryStartup: authController.canRetryStartup,
                errorMessage: authController.errorMessage,
              )
            : LoginPage(
                onLoginSuccess: authController.loginWithGoogle,
                onRetryStartup: authController.retryStartupSessionCheck,
                onNavigateToRegister: authController.navigateToRegister,
                isLoading: authController.isLoading,
                canRetryStartup: authController.canRetryStartup,
                errorMessage: authController.errorMessage,
              ),
      },
    );
  }
}

class _SyncingGate extends StatelessWidget {
  const _SyncingGate();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
