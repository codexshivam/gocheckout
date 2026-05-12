import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../data/models/schema/merchant_models.dart';
import '../../../data/models/schema/private_settings_models.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/service_locator.dart';
import '../../../data/services/r2_upload_service.dart';
import '../../common/app_styles.dart';
import '../../state/team_access_state_controller.dart';
import '../../theme/app_colors.dart';
import 'settings_contracts.dart';
import 'settings_dialogs.dart';
import 'tabs/payments_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/team_access_tab.dart';
import 'tabs/verification_tab.dart';

part 'settings_view_logic.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({
    super.key,
    this.repository,
    this.r2UploadService,
    this.imagePicker,
    this.teamAccessTabBuilder,
  });

  final SettingsRepository? repository;
  final R2UploadService? r2UploadService;
  final ImagePicker? imagePicker;
  final Widget Function(String storeId)? teamAccessTabBuilder;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final SettingsRepository _repository =
      widget.repository ?? ServiceLocator.instance.settingsRepository;
  late final R2UploadService _r2UploadService =
      widget.r2UploadService ?? ServiceLocator.instance.uploadService;
  late final ImagePicker _imagePicker = widget.imagePicker ?? ImagePicker();

  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessAddressController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _storeLogoUrlController = TextEditingController();

  final TextEditingController _citizenshipUrlController =
      TextEditingController();
  final TextEditingController _businessRegUrlController =
      TextEditingController();
  final TextEditingController _panUrlController = TextEditingController();

  final TextEditingController _esewaMerchantCodeController =
      TextEditingController();
  final TextEditingController _esewaSecretKeyController =
      TextEditingController();
  final TextEditingController _khaltiPublicKeyController =
      TextEditingController();
  final TextEditingController _khaltiSecretKeyController =
      TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankAccountNameController =
      TextEditingController();
  final TextEditingController _bankAccountNumberController =
      TextEditingController();

  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _verificationFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _paymentsFormKey = GlobalKey<FormState>();

  Merchant? _merchant;
  MerchantVerificationPrivateSettings? _verification;
  MerchantPaymentsPrivateSettings? _payments;
  MerchantPaymentsPrivateSettings? _paymentsBeforeEdit;

  Uint8List? _storePhotoPreviewBytes;
  bool _isUploadingPhoto = false;
  double _photoUploadProgress = 0;
  String _photoUploadLabel = 'Preparing your photo...';
  int _photoUploadGeneration = 0;

  bool _isUploadingCitizenship = false;
  double _citizenshipUploadProgress = 0;
  String _citizenshipUploadLabel = 'Preparing your document...';
  int _citizenshipUploadGeneration = 0;
  bool _isUploadingBusinessReg = false;
  double _businessRegUploadProgress = 0;
  String _businessRegUploadLabel = 'Preparing your document...';
  int _businessRegUploadGeneration = 0;
  bool _isUploadingPan = false;
  double _panUploadProgress = 0;
  String _panUploadLabel = 'Preparing your document...';
  int _panUploadGeneration = 0;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditingProfile = false;
  bool _isEditingVerification = false;
  bool _isEditingPayments = false;
  bool _isEsewaSecretObscured = true;
  bool _isKhaltiSecretObscured = true;
  int _currentTabIndex = 0;

  bool get _hasUnsavedChanges =>
      _isEditingProfile || _isEditingVerification || _isEditingPayments;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _storeLogoUrlController.dispose();
    _citizenshipUrlController.dispose();
    _businessRegUrlController.dispose();
    _panUrlController.dispose();
    _esewaMerchantCodeController.dispose();
    _esewaSecretKeyController.dispose();
    _khaltiPublicKeyController.dispose();
    _khaltiSecretKeyController.dispose();
    _bankNameController.dispose();
    _bankAccountNameController.dispose();
    _bankAccountNumberController.dispose();
    super.dispose();
  }

  ButtonStyle _primaryButtonStyle() => primaryAccentButtonStyle();

  ButtonStyle _softButtonStyle() => outlinedStyle();

  void _updateState(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_merchant == null || _verification == null || _payments == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Unable to load settings.'),
            const SizedBox(height: 8),
            OutlinedButton(
              style: _softButtonStyle(),
              onPressed: _loadSettings,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Builder(
        builder: (BuildContext tabContext) {
          return PopScope(
            canPop: !_hasUnsavedChanges,
            onPopInvokedWithResult: (bool didPop, Object? _) async {
              if (didPop || !_hasUnsavedChanges) {
                return;
              }

              final bool shouldDiscard = await _confirmDiscardChanges();
              if (!mounted || !shouldDiscard) {
                return;
              }

              _discardAllEdits();
              if (!tabContext.mounted) {
                return;
              }

              Navigator.of(tabContext).maybePop();
            },
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Store Settings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your business identity, verification documents, and payment gateway integrations.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9), // Sleek iOS/macOS styled capsule background
                      borderRadius: kRadiusMedium,
                    ),
                    child: Semantics(
                      label: 'Store configuration tabs',
                      hint: 'Use these tabs to switch between settings sections',
                      child: TabBar(
                        onTap: (int nextIndex) {
                          _handleTabTap(tabContext, nextIndex);
                        },
                        dividerColor: Colors.transparent,
                        labelColor: AppColors.black,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicator: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: kRadiusSmall,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        tabs: [
                          Tab(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                _tabLabel(
                                  SettingsTabId.basicDetails.label,
                                  _isEditingProfile,
                                ),
                              ),
                            ),
                          ),
                          Tab(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                _tabLabel(
                                  SettingsTabId.documentVerification.label,
                                  _isEditingVerification,
                                ),
                              ),
                            ),
                          ),
                          Tab(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                _tabLabel(
                                  SettingsTabId.paymentSettings.label,
                                  _isEditingPayments,
                                ),
                              ),
                            ),
                          ),
                          const Tab(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(SettingsContracts.teamAccessSection),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FocusTraversalGroup(
                      policy: OrderedTraversalPolicy(),
                      child: TabBarView(
                        physics: _hasUnsavedChanges
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        children: [
                  SettingsProfileTab(
                    formKey: _profileFormKey,
                    businessNameController: _businessNameController,
                    businessAddressController: _businessAddressController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    whatsappController: _whatsappController,
                    status: _merchant!.verificationStatus,
                    photoUrl: _storeLogoUrlController.text,
                    photoPreviewBytes: _storePhotoPreviewBytes,
                    isEditing: _isEditingProfile,
                    isSaving: _isSaving,
                    isUploadingPhoto: _isUploadingPhoto,
                    uploadProgress: _photoUploadProgress,
                    uploadLabel: _photoUploadLabel,
                    onChangePhoto: _pickAndUploadStorePhoto,
                    onEdit: () => setState(() => _isEditingProfile = true),
                    onCancel: () {
                      _cancelProfileEditWithConfirm();
                    },
                    onSave: _saveProfile,
                    softButtonStyle: _softButtonStyle(),
                    primaryButtonStyle: _primaryButtonStyle(),
                    inputDecorationBuilder: inputDecoration,
                    requiredValidator: _requiredValidator,
                    emailValidator: _emailValidator,
                    phoneValidator: (String? value) =>
                      _phoneValidator(value, 'Phone'),
                    whatsappValidator: (String? value) =>
                      _phoneValidator(value, 'WhatsApp'),
                  ),
                  SettingsVerificationTab(
                    formKey: _verificationFormKey,
                    verificationStatusLabel: _merchant!.verificationStatus.name
                        .toUpperCase(),
                    citizenshipUrlController: _citizenshipUrlController,
                    businessRegUrlController: _businessRegUrlController,
                    panUrlController: _panUrlController,
                    isEditing: _isEditingVerification,
                    isSaving: _isSaving,
                    isUploadingCitizenship: _isUploadingCitizenship,
                    citizenshipUploadProgress: _citizenshipUploadProgress,
                    citizenshipUploadLabel: _citizenshipUploadLabel,
                    isUploadingBusinessReg: _isUploadingBusinessReg,
                    businessRegUploadProgress: _businessRegUploadProgress,
                    businessRegUploadLabel: _businessRegUploadLabel,
                    isUploadingPan: _isUploadingPan,
                    panUploadProgress: _panUploadProgress,
                    panUploadLabel: _panUploadLabel,
                    onPickCitizenship: _pickCitizenshipDocument,
                    onPickBusinessReg: _pickBusinessRegistrationDocument,
                    onPickPan: _pickPanDocument,
                    onViewCitizenship: () => _openDocumentPreview(
                      'Citizenship Document',
                      _citizenshipUrlController.text,
                    ),
                    onViewBusinessReg: () => _openDocumentPreview(
                      'Business Registration',
                      _businessRegUrlController.text,
                    ),
                    onViewPan: () => _openDocumentPreview(
                      'PAN Document',
                      _panUrlController.text,
                    ),
                    canViewCitizenship: _hasValidImageUrl(
                      _citizenshipUrlController.text,
                    ),
                    canViewBusinessReg: _hasValidImageUrl(
                      _businessRegUrlController.text,
                    ),
                    canViewPan: _hasValidImageUrl(_panUrlController.text),
                    onEdit: () => setState(() => _isEditingVerification = true),
                    onCancel: () {
                      _cancelVerificationEditWithConfirm();
                    },
                    onSave: _saveVerification,
                    softButtonStyle: _softButtonStyle(),
                    primaryButtonStyle: _primaryButtonStyle(),
                    canSave: !_isUploadingCitizenship &&
                      !_isUploadingBusinessReg &&
                      !_isUploadingPan &&
                      _hasValidImageUrl(_citizenshipUrlController.text) &&
                      _hasValidImageUrl(_businessRegUrlController.text) &&
                      _hasValidImageUrl(_panUrlController.text),
                    saveDisabledReason: SettingsContracts.verificationSaveDisabledReason,
                    onRequestSupport: _openVerificationSupport,
                  ),
                   SettingsPaymentsTab(
                    formKey: _paymentsFormKey,
                    esewaEnabled: _isMethodActive(_payments?.esewa),
                    khaltiEnabled: _isMethodActive(_payments?.khalti),
                    bankTransferEnabled: _isMethodActive(
                      _payments?.bankTransfer,
                    ),
                    codEnabled: _isMethodActive(_payments?.cod),
                    isEditing: _isEditingPayments,
                    isSaving: _isSaving,
                    lastModifiedAt: _payments?.lastModifiedAt,
                    lastModifiedBy: _payments?.lastModifiedBy,
                    esewaMerchantCodeController: _esewaMerchantCodeController,
                    esewaSecretKeyController: _esewaSecretKeyController,
                    khaltiPublicKeyController: _khaltiPublicKeyController,
                    khaltiSecretKeyController: _khaltiSecretKeyController,
                    bankNameController: _bankNameController,
                    bankAccountNameController: _bankAccountNameController,
                    bankAccountNumberController: _bankAccountNumberController,
                    isEsewaSecretObscured: _isEsewaSecretObscured,
                    isKhaltiSecretObscured: _isKhaltiSecretObscured,
                    onToggleEsewaSecretVisibility: _toggleEsewaSecretVisibility,
                    onToggleKhaltiSecretVisibility: _toggleKhaltiSecretVisibility,
                    onToggleEsewa: _toggleEsewa,
                    onToggleKhalti: _toggleKhalti,
                    onToggleBankTransfer: _toggleBankTransfer,
                    onToggleCod: _toggleCod,
                    onEdit: () => setState(() {
                      _paymentsBeforeEdit = _clonePayments(_payments!);
                      _isEditingPayments = true;
                    }),
                    onCancel: () {
                      _cancelPaymentsEditWithConfirm();
                    },
                    onSave: _savePayments,
                    softButtonStyle: _softButtonStyle(),
                    primaryButtonStyle: _primaryButtonStyle(),
                    inputDecorationBuilder: inputDecoration,
                  ),
                  widget.teamAccessTabBuilder != null
                      ? widget.teamAccessTabBuilder!(_merchant!.merchantId)
                      : ChangeNotifierProvider<TeamAccessStateController>(
                          create: (_) => TeamAccessStateController(
                            storeId: _merchant!.merchantId,
                          )..load(),
                          child: const TeamAccessTab(),
                        ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
