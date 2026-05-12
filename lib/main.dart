import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/service_locator.dart';
import 'ui/state/auth_state_controller.dart';
import 'ui/state/onboarding_state_controller.dart';
import 'ui/state/store_state_controller.dart';
import 'ui/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Boot all repositories and services. Reads --dart-define flags to decide
  // whether to use sample data (default) or a real Appwrite backend.
  ServiceLocator.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthStateController>(
          create: (_) => AuthStateController(
            authService: ServiceLocator.instance.authService,
          )..bootstrapSession(),
        ),
        ChangeNotifierProvider<OnboardingStateController>(
          create: (_) => OnboardingStateController(),
        ),
        ChangeNotifierProvider<StoreStateController>(
          create: (_) => StoreStateController(),
        ),
      ],
      child: const MerchantPortalApp(),
    ),
  );
}
