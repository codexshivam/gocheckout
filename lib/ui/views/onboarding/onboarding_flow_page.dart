import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../common/app_styles.dart';
import '../../state/auth_state_controller.dart';
import '../../state/onboarding_state_controller.dart';
import '../../state/store_state_controller.dart';
import '../../theme/app_colors.dart';
import '../../../data/services/onboarding_service.dart';

class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();

  bool _forceCreateStore = false;
  bool _storeListenerAttached = false;
  bool _isPaywallVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_storeListenerAttached) {
      return;
    }

    context.read<StoreStateController>().addListener(_onStoreStateChanged);
    _storeListenerAttached = true;
  }

  @override
  void dispose() {
    if (_storeListenerAttached) {
      context.read<StoreStateController>().removeListener(_onStoreStateChanged);
    }
    _phoneController.dispose();
    _addressController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  void _onStoreStateChanged() {
    if (!mounted) {
      return;
    }

    final StoreStateController storeController = context.read<StoreStateController>();
    if (!storeController.isSubscriptionActive || !_isPaywallVisible) {
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();
    _isPaywallVisible = false;

    context.read<AuthStateController>().refreshUserProfile();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment is active. Redirecting to dashboard.'),
      ),
    );
  }

  Future<void> _submitProfile() async {
    final String phone = _phoneController.text.trim();
    final String address = _addressController.text.trim();

    if (phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone and address are required.')),
      );
      return;
    }

    final AuthStateController authController = context.read<AuthStateController>();
    final User? user = authController.currentUser;
    if (user == null) {
      return;
    }

    final bool ok = await authController.completeProfile(phone: phone, address: address);
    if (!ok || !mounted) {
      return;
    }

    if ((authController.activeStoreId ?? '').isNotEmpty) {
      return;
    }

    final OnboardingStateController onboardingController =
        context.read<OnboardingStateController>();
    final OnboardingRouteState? route = await onboardingController.evaluateUserPath(
      uid: user.$id,
      email: user.email,
    );

    if (!mounted || route == null) {
      if (mounted && onboardingController.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(onboardingController.errorMessage!)),
        );
      }
      return;
    }

    if (route == OnboardingRouteState.redirectToDashboard) {
      await authController.refreshUserProfile();
      return;
    }

    setState(() {
      _forceCreateStore = true;
    });
  }

  Future<void> _createStore() async {
    final String businessName = _businessNameController.text.trim();
    if (businessName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business name is required.')),
      );
      return;
    }

    final AuthStateController authController = context.read<AuthStateController>();
    final User? user = authController.currentUser;
    if (user == null) {
      return;
    }

    final StoreStateController storeController = context.read<StoreStateController>();
    final String? storeId = await storeController.createStore(
      businessName: businessName,
      ownerUid: user.$id,
    );

    if (!mounted || storeId == null) {
      if (mounted && storeController.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(storeController.errorMessage!)),
        );
      }
      return;
    }

    storeController.listenToPaymentStatus(storeId);
    await _showPaywallModal(storeId);
  }

  Future<void> _showPaywallModal(String storeId) async {
    if (_isPaywallVisible) {
      return;
    }

    _isPaywallVisible = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Consumer<StoreStateController>(
          builder: (context, storeController, _) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: kRadiusMedium,
              ),
              title: Text(
                'Activate Subscription',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Store ID: $storeId',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Payment status is being monitored in real-time. This dialog will close automatically once subscription status becomes active.',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(),
                  if (storeController.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      storeController.errorMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.rtoText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );

    _isPaywallVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    final AuthStateController authController = context.watch<AuthStateController>();
    final OnboardingStateController onboardingController =
        context.watch<OnboardingStateController>();
    final StoreStateController storeController = context.watch<StoreStateController>();

    final bool profileComplete = authController.hasCompletedProfile;
    final bool hasStore = (authController.activeStoreId ?? '').isNotEmpty;

    final bool showProfileStep = !profileComplete && !_forceCreateStore;
    final bool showCreateStoreStep = _forceCreateStore || (profileComplete && !hasStore);

    if (authController.isProfileLoading || authController.currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!showProfileStep && !showCreateStoreStep) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: showProfileStep
                ? _ProfileCompletionCard(
                    phoneController: _phoneController,
                    addressController: _addressController,
                    isLoading: authController.isLoading || onboardingController.isLoading,
                    errorMessage: authController.errorMessage ?? onboardingController.errorMessage,
                    onSubmit: _submitProfile,
                  )
                : _CreateStoreCard(
                    businessNameController: _businessNameController,
                    isLoading: storeController.isLoading,
                    errorMessage: storeController.errorMessage,
                    onSubmit: _createStore,
                  ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCompletionCard extends StatelessWidget {
  const _ProfileCompletionCard({
    required this.phoneController,
    required this.addressController,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
  });

  final TextEditingController phoneController;
  final TextEditingController addressController;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: kRadiusMedium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete Your Profile',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add phone and address to continue onboarding.',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: inputDecoration('Phone Number'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: addressController,
            decoration: inputDecoration('Address'),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: GoogleFonts.inter(
                color: AppColors.rtoText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: blackButtonStyle(),
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateStoreCard extends StatelessWidget {
  const _CreateStoreCard({
    required this.businessNameController,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
  });

  final TextEditingController businessNameController;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: kRadiusMedium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Your Store',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No invite found. Create your first store to continue.',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: businessNameController,
            decoration: inputDecoration('Business Name'),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: GoogleFonts.inter(
                color: AppColors.rtoText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: blackButtonStyle(),
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Store'),
            ),
          ),
        ],
      ),
    );
  }
}
