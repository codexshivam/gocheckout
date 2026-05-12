part of 'settings_view.dart';

class _PaymentProviderPatch {
  const _PaymentProviderPatch({
    required this.providerKey,
    required this.providerLabel,
    required this.previous,
    required this.next,
  });

  final String providerKey;
  final String providerLabel;
  final PaymentMethodSecrets previous;
  final PaymentMethodSecrets next;
}

extension _SettingsViewLogic on _SettingsViewState {
  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  static final RegExp _phonePattern = RegExp(r'^\+?[0-9]{7,15}$');
  static final RegExp _bankAccountPattern = RegExp(r'^[0-9]{6,24}$');

  int _startVerificationUploadGeneration(String storageSlug) {
    switch (storageSlug) {
      case SettingsContracts.citizenshipStorageSlug:
        _citizenshipUploadGeneration += 1;
        return _citizenshipUploadGeneration;
      case SettingsContracts.businessRegistrationStorageSlug:
        _businessRegUploadGeneration += 1;
        return _businessRegUploadGeneration;
      case SettingsContracts.panStorageSlug:
        _panUploadGeneration += 1;
        return _panUploadGeneration;
      default:
        return 0;
    }
  }

  bool _isVerificationUploadStale(String storageSlug, int generation) {
    switch (storageSlug) {
      case SettingsContracts.citizenshipStorageSlug:
        return generation != _citizenshipUploadGeneration ||
            !_isEditingVerification;
      case SettingsContracts.businessRegistrationStorageSlug:
        return generation != _businessRegUploadGeneration ||
            !_isEditingVerification;
      case SettingsContracts.panStorageSlug:
        return generation != _panUploadGeneration || !_isEditingVerification;
      default:
        return true;
    }
  }

  Future<bool> _confirmCancelEdit(String sectionName) async {
    return showSettingsConfirmDialog(
      context: context,
      title: SettingsContracts.discardEditsTitle,
      message: 'Any unsaved changes in $sectionName will be lost.',
      confirmLabel: SettingsContracts.discardAction,
      cancelLabel: SettingsContracts.keepEditingAction,
      isDestructive: true,
    );
  }

  Future<void> _cancelProfileEditWithConfirm() async {
    final bool shouldDiscard = await _confirmCancelEdit(
      SettingsContracts.basicDetailsSection,
    );
    if (!mounted || !shouldDiscard) {
      return;
    }
    _cancelProfileEdit();
  }

  Future<void> _cancelVerificationEditWithConfirm() async {
    final bool shouldDiscard = await _confirmCancelEdit(
      SettingsContracts.documentVerificationSection,
    );
    if (!mounted || !shouldDiscard) {
      return;
    }
    _cancelVerificationEdit();
  }

  Future<void> _cancelPaymentsEditWithConfirm() async {
    final bool shouldDiscard = await _confirmCancelEdit(
      SettingsContracts.paymentSettingsSection,
    );
    if (!mounted || !shouldDiscard) {
      return;
    }
    _cancelPaymentsEdit();
  }

  String _tabLabel(String base, bool dirty) {
    return dirty ? '$base *' : base;
  }

  void _handleTabTap(BuildContext tabContext, int nextIndex) {
    if (nextIndex == _currentTabIndex) {
      return;
    }

    if (!_hasUnsavedChanges) {
      _updateState(() => _currentTabIndex = nextIndex);
      return;
    }

    final TabController? controller = DefaultTabController.maybeOf(tabContext);
    controller?.animateTo(_currentTabIndex);

    _confirmDiscardChanges().then((bool shouldDiscard) {
      if (!mounted || !shouldDiscard) {
        return;
      }
      _discardCurrentTabEdits();
      _updateState(() => _currentTabIndex = nextIndex);
      controller?.animateTo(nextIndex);
    });
  }

  Future<bool> _confirmDiscardChanges() async {
    return showSettingsConfirmDialog(
      context: context,
      title: SettingsContracts.discardUnsavedTitle,
      message: 'You have unsaved changes. If you continue, your edits will be lost.',
      confirmLabel: SettingsContracts.discardAction,
      cancelLabel: SettingsContracts.keepEditingAction,
      isDestructive: true,
    );
  }

  void _discardCurrentTabEdits() {
    switch (_currentTabIndex) {
      case 0:
        if (_isEditingProfile) {
          _cancelProfileEdit();
        }
        break;
      case 1:
        if (_isEditingVerification) {
          _cancelVerificationEdit();
        }
        break;
      case 2:
        if (_isEditingPayments) {
          _cancelPaymentsEdit();
        }
        break;
      default:
        break;
    }
  }

  void _discardAllEdits() {
    if (_isEditingProfile) {
      _cancelProfileEdit();
    }
    if (_isEditingVerification) {
      _cancelVerificationEdit();
    }
    if (_isEditingPayments) {
      _cancelPaymentsEdit();
    }
  }

  String _contentTypeFromPath(String path) {
    final String lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  bool _isMethodActive(PaymentMethodSecrets? method) {
    return method?.isActive ?? false;
  }

  int _activePaymentMethodCount(MerchantPaymentsPrivateSettings settings) {
    return (settings.esewa.isActive ? 1 : 0) +
        (settings.khalti.isActive ? 1 : 0) +
        (settings.bankTransfer.isActive ? 1 : 0) +
        (settings.cod.isActive ? 1 : 0);
  }

  Future<void> _loadSettings() async {
    try {
      final SettingsPayload payload = await _repository.fetchSettings();
      if (!mounted) {
        return;
      }
      _updateState(() {
        _merchant = payload.merchant;
        _verification = payload.verification;
        _payments = payload.payments;
        _paymentsBeforeEdit = null;
        _isLoading = false;
      });
      _hydrateControllers();
    } catch (_) {
      if (!mounted) {
        return;
      }
      _updateState(() => _isLoading = false);
      await showSettingsAlertDialog(
        context: context,
        title: 'Settings Load Failed',
        message: 'Unable to load settings right now. Please retry.',
        type: SettingsDialogType.error,
      );
    }
  }

  void _hydrateControllers() {
    final Merchant merchant = _merchant!;
    final MerchantVerificationPrivateSettings verification = _verification!;
    final MerchantPaymentsPrivateSettings payments = _payments!;

    _businessNameController.text = merchant.businessName;
    _businessAddressController.text = merchant.businessAddress;
    _emailController.text = merchant.contactInfo.email;
    _phoneController.text = merchant.contactInfo.phone;
    _whatsappController.text = merchant.contactInfo.whatsapp;
    _storeLogoUrlController.text = merchant.storeLogoUrl;

    _citizenshipUrlController.text = verification.citizenshipUrl;
    _businessRegUrlController.text = verification.businessRegUrl;
    _panUrlController.text = verification.panUrl;

    _esewaMerchantCodeController.text =
        payments.esewa.credentials['merchantCode'] ?? '';
    _esewaSecretKeyController.text =
        payments.esewa.credentials['secretKey'] ?? '';
    _khaltiPublicKeyController.text =
        payments.khalti.credentials['publicKey'] ?? '';
    _khaltiSecretKeyController.text =
        payments.khalti.credentials['secretKey'] ?? '';
    _bankNameController.text =
        payments.bankTransfer.credentials['bankName'] ?? '';
    _bankAccountNameController.text =
        payments.bankTransfer.credentials['accountName'] ?? '';
    _bankAccountNumberController.text =
        payments.bankTransfer.credentials['accountNumber'] ?? '';
  }

  String? _requiredValidator(String? value, String fieldName) {
    if ((value ?? '').trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final String? requiredError = _requiredValidator(value, 'Email');
    if (requiredError != null) {
      return requiredError;
    }

    if (!_emailPattern.hasMatch((value ?? '').trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _phoneValidator(String? value, String fieldName) {
    final String? requiredError = _requiredValidator(value, fieldName);
    if (requiredError != null) {
      return requiredError;
    }

    if (!_phonePattern.hasMatch((value ?? '').trim())) {
      return '$fieldName must be 7-15 digits (optional + prefix)';
    }
    return null;
  }

  MerchantPaymentsPrivateSettings _clonePayments(
    MerchantPaymentsPrivateSettings source,
  ) {
    return MerchantPaymentsPrivateSettings(
      esewa: PaymentMethodSecrets(
        isActive: source.esewa.isActive,
        credentials: Map<String, String>.from(source.esewa.credentials),
      ),
      khalti: PaymentMethodSecrets(
        isActive: source.khalti.isActive,
        credentials: Map<String, String>.from(source.khalti.credentials),
      ),
      bankTransfer: PaymentMethodSecrets(
        isActive: source.bankTransfer.isActive,
        credentials: Map<String, String>.from(source.bankTransfer.credentials),
      ),
      cod: PaymentMethodSecrets(
        isActive: source.cod.isActive,
        credentials: Map<String, String>.from(source.cod.credentials),
      ),
      lastModifiedAt: source.lastModifiedAt,
      lastModifiedBy: source.lastModifiedBy,
    );
  }

  bool _hasValidImageUrl(String value) {
    final Uri? uri = Uri.tryParse(value.trim());
    return uri != null && uri.isScheme('https') && uri.host.isNotEmpty;
  }

  Future<void> _openDocumentPreview(String title, String url) async {
    if (!_hasValidImageUrl(url)) {
      await showSettingsAlertDialog(
        context: context,
        title: 'Preview Unavailable',
        message: 'Please select a valid file first.',
        type: SettingsDialogType.info,
      );
      return;
    }

    await showSettingsDocumentPreviewDialog(
      context: context,
      title: title,
      url: url,
    );
  }

  Future<void> _openVerificationSupport() async {
    await showSettingsAlertDialog(
      context: context,
      title: 'Verification Support',
      message:
          'Please contact merchant support at support@gocheckout.example with your Merchant ID and document type for faster help.',
      type: SettingsDialogType.info,
    );
  }

  Future<void> _saveProfile() async {
    if (_isSaving) {
      return;
    }
    if (_isUploadingPhoto) {
      await showSettingsAlertDialog(
        context: context,
        title: 'Please Wait',
        message: 'Your selected store photo is still being prepared.',
        type: SettingsDialogType.info,
      );
      return;
    }
    if (!_profileFormKey.currentState!.validate() || _merchant == null) {
      return;
    }
    final Merchant original = _merchant!;
    final Merchant updated = Merchant(
      merchantId: original.merchantId,
      businessName: _businessNameController.text.trim(),
      businessAddress: _businessAddressController.text.trim(),
      contactInfo: MerchantContactInfo(
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
      ),
      storeLogoUrl: _storeLogoUrlController.text.trim(),
      verificationStatus: original.verificationStatus,
      stats: original.stats,
    );

    final List<String> changedFields = <String>[];
    if (original.businessName != updated.businessName) {
      changedFields.add('Business Name');
    }
    if (original.businessAddress != updated.businessAddress) {
      changedFields.add('Business Address');
    }
    if (original.contactInfo.email != updated.contactInfo.email) {
      changedFields.add('Email');
    }
    if (original.contactInfo.phone != updated.contactInfo.phone) {
      changedFields.add('Phone');
    }
    if (original.contactInfo.whatsapp != updated.contactInfo.whatsapp) {
      changedFields.add('WhatsApp');
    }
    if (original.storeLogoUrl != updated.storeLogoUrl) {
      changedFields.add('Store Photo');
    }

    if (changedFields.isEmpty) {
      _updateState(() {
        _isEditingProfile = false;
        _storePhotoPreviewBytes = null;
      });
      await showSettingsAlertDialog(
        context: context,
        title: 'No Changes to Save',
        message: 'Profile values are unchanged.',
        type: SettingsDialogType.info,
      );
      return;
    }

    _updateState(() => _isSaving = true);
    try {
      final Merchant saved = await _repository.updateMerchant(updated);
      if (!mounted) {
        return;
      }
      _updateState(() {
        _merchant = saved;
        _isEditingProfile = false;
        _isSaving = false;
      });
      await showSettingsAlertDialog(
        context: context,
        title: 'Profile Saved',
        message: changedFields.isEmpty
            ? 'No changes detected. Existing profile values were kept.'
            : 'Saved: ${changedFields.join(', ')}.',
        type: SettingsDialogType.success,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _updateState(() => _isSaving = false);
      await showSettingsAlertDialog(
        context: context,
        title: 'Save Failed',
        message: 'Unable to save profile settings. Please try again.',
        type: SettingsDialogType.error,
      );
    }
  }

  Future<void> _saveVerification() async {
    if (_isSaving) {
      return;
    }
    if (_isUploadingCitizenship || _isUploadingBusinessReg || _isUploadingPan) {
      await showSettingsAlertDialog(
        context: context,
        title: 'Please Wait',
        message:
            'One or more selected documents are still being prepared. Please wait a moment and save again.',
        type: SettingsDialogType.info,
      );
      return;
    }

    if ((_citizenshipUrlController.text).trim().isEmpty ||
        (_businessRegUrlController.text).trim().isEmpty ||
        (_panUrlController.text).trim().isEmpty) {
      await showSettingsAlertDialog(
        context: context,
        title: 'Missing Documents',
        message:
            'Please choose Citizenship, Business Registration and PAN documents before saving.',
        type: SettingsDialogType.info,
      );
      return;
    }

    if (!_hasValidImageUrl(_citizenshipUrlController.text) ||
        !_hasValidImageUrl(_businessRegUrlController.text) ||
        !_hasValidImageUrl(_panUrlController.text)) {
      await showSettingsAlertDialog(
        context: context,
        title: 'Invalid Document Link',
        message:
            'One or more document links are invalid. Please choose the files again.',
        type: SettingsDialogType.error,
      );
      return;
    }
    final MerchantVerificationPrivateSettings updated =
        MerchantVerificationPrivateSettings(
          citizenshipUrl: _citizenshipUrlController.text.trim(),
          businessRegUrl: _businessRegUrlController.text.trim(),
          panUrl: _panUrlController.text.trim(),
        );

    final MerchantVerificationPrivateSettings existing = _verification!;
    final List<String> changedDocuments = <String>[];
    if (existing.citizenshipUrl != updated.citizenshipUrl) {
      changedDocuments.add('Citizenship');
    }
    if (existing.businessRegUrl != updated.businessRegUrl) {
      changedDocuments.add('Business Registration');
    }
    if (existing.panUrl != updated.panUrl) {
      changedDocuments.add('PAN');
    }

    if (changedDocuments.isEmpty) {
      _updateState(() => _isEditingVerification = false);
      await showSettingsAlertDialog(
        context: context,
        title: 'No Changes to Save',
        message: 'Verification documents are unchanged.',
        type: SettingsDialogType.info,
      );
      return;
    }

    _updateState(() => _isSaving = true);
    try {
      final MerchantVerificationPrivateSettings saved = await _repository
          .updateVerification(updated);
      if (!mounted) {
        return;
      }
      _updateState(() {
        _verification = saved;
        _isEditingVerification = false;
        _isSaving = false;
      });
      await showSettingsAlertDialog(
        context: context,
        title: 'Verification Saved',
        message: changedDocuments.isEmpty
            ? 'No document changes detected.'
            : 'Updated documents: ${changedDocuments.join(', ')}.',
        type: SettingsDialogType.success,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _updateState(() => _isSaving = false);
      await showSettingsAlertDialog(
        context: context,
        title: 'Save Failed',
        message: 'Unable to save verification settings. Please try again.',
        type: SettingsDialogType.error,
      );
    }
  }

  Future<void> _savePayments() async {
    if (_isSaving) {
      return;
    }
    if (_payments == null) {
      return;
    }

    final List<String> providerErrors = _paymentProviderValidationErrors();
    if (providerErrors.isNotEmpty) {
      await showSettingsAlertDialog(
        context: context,
        title: 'Payment Validation Issues',
        message: providerErrors.map((error) => '• $error').join('\n'),
        type: SettingsDialogType.info,
      );
      return;
    }

    if (!_paymentsFormKey.currentState!.validate()) {
      return;
    }

    if (_activePaymentMethodCount(_payments!) == 0) {
      await showSettingsAlertDialog(
        context: context,
        title: 'No Active Payment Method',
        message:
            'Enable at least one payment method before saving. Customers cannot checkout without an active method.',
        type: SettingsDialogType.info,
      );
      return;
    }

    final MerchantPaymentsPrivateSettings existing = _payments!;
    final MerchantPaymentsPrivateSettings updated =
        MerchantPaymentsPrivateSettings(
          esewa: PaymentMethodSecrets(
            isActive: existing.esewa.isActive,
            credentials: {
              'merchantCode': _esewaMerchantCodeController.text.trim(),
              'secretKey': _esewaSecretKeyController.text.trim(),
            },
          ),
          khalti: PaymentMethodSecrets(
            isActive: existing.khalti.isActive,
            credentials: {
              'publicKey': _khaltiPublicKeyController.text.trim(),
              'secretKey': _khaltiSecretKeyController.text.trim(),
            },
          ),
          bankTransfer: PaymentMethodSecrets(
            isActive: existing.bankTransfer.isActive,
            credentials: {
              'bankName': _bankNameController.text.trim(),
              'accountName': _bankAccountNameController.text.trim(),
              'accountNumber': _bankAccountNumberController.text.trim(),
            },
          ),
          cod: PaymentMethodSecrets(
            isActive: existing.cod.isActive,
            credentials: const {},
          ),
          lastModifiedAt: existing.lastModifiedAt,
          lastModifiedBy: existing.lastModifiedBy,
        );

    final List<_PaymentProviderPatch> changedProviderPatches =
      _changedPaymentProviderPatches(existing: existing, updated: updated);
    final List<String> changedPaymentSections = changedProviderPatches
      .map((patch) => patch.providerLabel)
      .toList(growable: false);

    if (changedPaymentSections.isEmpty) {
      _updateState(() {
        _paymentsBeforeEdit = null;
        _isEditingPayments = false;
      });
      await showSettingsAlertDialog(
        context: context,
        title: 'No Changes to Save',
        message: 'Payment settings are unchanged.',
        type: SettingsDialogType.info,
      );
      return;
    }

    _updateState(() => _isSaving = true);
    try {
      final MerchantPaymentsPrivateSettings saved = await _repository
          .updatePayments(updated);
      if (!mounted) {
        return;
      }
      _updateState(() {
        _payments = saved;
        _paymentsBeforeEdit = null;
        _isEditingPayments = false;
        _isSaving = false;
      });
      await showSettingsAlertDialog(
        context: context,
        title: 'Payments Saved',
        message: changedPaymentSections.isEmpty
            ? 'No payment changes detected.'
            : 'Updated: ${changedPaymentSections.join(', ')}.',
        type: SettingsDialogType.success,
      );
    } catch (_) {
      final bool fallbackHandled = await _savePaymentsProviderByProvider(
        existing: existing,
        changedPatches: changedProviderPatches,
      );
      if (fallbackHandled) {
        return;
      }
      if (!mounted) {
        return;
      }
      _updateState(() => _isSaving = false);
      await showSettingsAlertDialog(
        context: context,
        title: 'Save Failed',
        message: 'Unable to save payment settings. Please try again.',
        type: SettingsDialogType.error,
      );
    }
  }

  bool _paymentMethodChanged(
    PaymentMethodSecrets before,
    PaymentMethodSecrets after,
  ) {
    return before.isActive != after.isActive ||
        before.credentials.toString() != after.credentials.toString();
  }

  List<_PaymentProviderPatch> _changedPaymentProviderPatches({
    required MerchantPaymentsPrivateSettings existing,
    required MerchantPaymentsPrivateSettings updated,
  }) {
    final List<_PaymentProviderPatch> patches = <_PaymentProviderPatch>[
      _PaymentProviderPatch(
        providerKey: SettingsContracts.esewaProviderKey,
        providerLabel: SettingsContracts.esewaProviderLabel,
        previous: existing.esewa,
        next: updated.esewa,
      ),
      _PaymentProviderPatch(
        providerKey: SettingsContracts.khaltiProviderKey,
        providerLabel: SettingsContracts.khaltiProviderLabel,
        previous: existing.khalti,
        next: updated.khalti,
      ),
      _PaymentProviderPatch(
        providerKey: SettingsContracts.bankTransferProviderKey,
        providerLabel: SettingsContracts.bankTransferProviderLabel,
        previous: existing.bankTransfer,
        next: updated.bankTransfer,
      ),
      _PaymentProviderPatch(
        providerKey: SettingsContracts.codProviderKey,
        providerLabel: SettingsContracts.codProviderLabel,
        previous: existing.cod,
        next: updated.cod,
      ),
    ];

    return patches
        .where(
          (patch) => _paymentMethodChanged(patch.previous, patch.next),
        )
        .toList(growable: false);
  }

  Future<bool> _savePaymentsProviderByProvider({
    required MerchantPaymentsPrivateSettings existing,
    required List<_PaymentProviderPatch> changedPatches,
  }) async {
    if (changedPatches.isEmpty) {
      return false;
    }

    MerchantPaymentsPrivateSettings latest = _clonePayments(existing);
    final List<String> savedProviders = <String>[];
    final List<String> failedProviders = <String>[];

    for (final _PaymentProviderPatch patch in changedPatches) {
      try {
        latest = await _repository.updateSinglePaymentMethod(
          providerKey: patch.providerKey,
          method: patch.next,
        );
        savedProviders.add(patch.providerLabel);
      } catch (_) {
        failedProviders.add(patch.providerLabel);
      }
    }

    if (!mounted) {
      return true;
    }

    _updateState(() {
      _payments = latest;
      _isSaving = false;
      if (failedProviders.isEmpty) {
        _paymentsBeforeEdit = null;
        _isEditingPayments = false;
      } else {
        _paymentsBeforeEdit = _clonePayments(latest);
        _isEditingPayments = true;
      }
    });

    _hydrateControllers();

    if (savedProviders.isNotEmpty && failedProviders.isEmpty) {
      await showSettingsAlertDialog(
        context: context,
        title: 'Payments Saved',
        message: 'Updated: ${savedProviders.join(', ')}.',
        type: SettingsDialogType.success,
      );
      return true;
    }

    if (savedProviders.isNotEmpty && failedProviders.isNotEmpty) {
      await showSettingsAlertDialog(
        context: context,
        title: 'Partial Payment Save',
        message:
            'Saved: ${savedProviders.join(', ')}.\nFailed: ${failedProviders.join(', ')}. Please review and try again.',
        type: SettingsDialogType.info,
      );
      return true;
    }

    await showSettingsAlertDialog(
      context: context,
      title: 'Save Failed',
      message:
          'No payment providers were saved. Failed: ${failedProviders.join(', ')}. Please try again.',
      type: SettingsDialogType.error,
    );
    return true;
  }

  void _cancelProfileEdit() {
    _photoUploadGeneration += 1;
    _hydrateControllers();
    _updateState(() {
      _storePhotoPreviewBytes = null;
      _isUploadingPhoto = false;
      _photoUploadProgress = 0;
      _isEditingProfile = false;
    });
  }

  void _cancelVerificationEdit() {
    _citizenshipUploadGeneration += 1;
    _businessRegUploadGeneration += 1;
    _panUploadGeneration += 1;
    _hydrateControllers();
    _updateState(() {
      _isUploadingCitizenship = false;
      _citizenshipUploadProgress = 0;
      _isUploadingBusinessReg = false;
      _businessRegUploadProgress = 0;
      _isUploadingPan = false;
      _panUploadProgress = 0;
      _isEditingVerification = false;
    });
  }

  void _cancelPaymentsEdit() {
    if (_paymentsBeforeEdit != null) {
      _payments = _clonePayments(_paymentsBeforeEdit!);
    }
    _hydrateControllers();
    _updateState(() {
      _isEsewaSecretObscured = true;
      _isKhaltiSecretObscured = true;
      _paymentsBeforeEdit = null;
      _isEditingPayments = false;
    });
  }

  void _toggleEsewaSecretVisibility() {
    _updateState(() => _isEsewaSecretObscured = !_isEsewaSecretObscured);
  }

  void _toggleKhaltiSecretVisibility() {
    _updateState(() => _isKhaltiSecretObscured = !_isKhaltiSecretObscured);
  }

  bool _hasEsewaCredentials() {
    return _esewaMerchantCodeController.text.trim().isNotEmpty &&
        _esewaSecretKeyController.text.trim().isNotEmpty;
  }

  bool _hasKhaltiCredentials() {
    return _khaltiPublicKeyController.text.trim().isNotEmpty &&
        _khaltiSecretKeyController.text.trim().isNotEmpty;
  }

  bool _hasBankTransferCredentials() {
    return _bankNameController.text.trim().isNotEmpty &&
        _bankAccountNameController.text.trim().isNotEmpty &&
        _bankAccountNumberController.text.trim().isNotEmpty;
  }

  List<String> _paymentProviderValidationErrors() {
    if (_payments == null) {
      return const <String>[];
    }

    final List<String> errors = <String>[];

    if (_payments!.esewa.isActive) {
      final List<String> missing = <String>[];
      if (_esewaMerchantCodeController.text.trim().isEmpty) {
        missing.add('Merchant Code');
      }
      if (_esewaSecretKeyController.text.trim().isEmpty) {
        missing.add('Secret Key');
      }
      if (missing.isNotEmpty) {
        errors.add('eSewa: missing ${missing.join(', ')}');
      }
    }

    if (_payments!.khalti.isActive) {
      final List<String> missing = <String>[];
      if (_khaltiPublicKeyController.text.trim().isEmpty) {
        missing.add('Public Key');
      }
      if (_khaltiSecretKeyController.text.trim().isEmpty) {
        missing.add('Secret Key');
      }
      if (missing.isNotEmpty) {
        errors.add('Khalti: missing ${missing.join(', ')}');
      }
    }

    if (_payments!.bankTransfer.isActive) {
      final List<String> missing = <String>[];
      if (_bankNameController.text.trim().isEmpty) {
        missing.add('Bank Name');
      }
      if (_bankAccountNameController.text.trim().isEmpty) {
        missing.add('Account Name');
      }
      final String accountNo = _bankAccountNumberController.text.trim();
      if (accountNo.isEmpty) {
        missing.add('Account Number');
      }
      if (missing.isNotEmpty) {
        errors.add('Bank Transfer: missing ${missing.join(', ')}');
      } else if (!_bankAccountPattern.hasMatch(accountNo)) {
        errors.add('Bank Transfer: Account Number must be 6-24 digits');
      }
    }

    return errors;
  }

  Future<bool> _confirmDisableMethod(String methodName) async {
    return showSettingsConfirmDialog(
      context: context,
      title: 'Disable $methodName?',
      message: 'Customers will not see $methodName at checkout after you save these changes.',
      confirmLabel: 'Disable',
      cancelLabel: 'Keep Enabled',
      isDestructive: true,
    );
  }

  Future<void> _pickAndUploadStorePhoto() async {
    int uploadGeneration = 0;
    if (!_isEditingProfile) {
      await showSettingsAlertDialog(
        context: context,
        title: 'Edit Mode Required',
        message: 'Tap Edit in Profile first to change store photo.',
        type: SettingsDialogType.info,
      );
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1400,
      );
      if (image == null) {
        return;
      }

      final Uint8List bytes = await image.readAsBytes();
      uploadGeneration = ++_photoUploadGeneration;
      _updateState(() {
        _storePhotoPreviewBytes = bytes;
        _isUploadingPhoto = true;
        _photoUploadProgress = 0.1;
        _photoUploadLabel = 'Checking connection...';
      });

      final String merchantId = _merchant?.merchantId ?? 'unknown';
      final int now = DateTime.now().millisecondsSinceEpoch;
      final String objectPath = 'merchants/$merchantId/logo_$now.jpg';

      final String generatedR2Url = await _r2UploadService.uploadFile(
        bytes: bytes,
        objectPath: objectPath,
        contentType: _contentTypeFromPath(image.path),
        timeout: const Duration(seconds: 25),
        maxRetries: 2,
        onAttempt: (int attempt) {
          if (!mounted || uploadGeneration != _photoUploadGeneration || !_isEditingProfile) {
            return;
          }
          _updateState(() {
            _photoUploadProgress = (0.2 + (attempt - 1) * 0.2).clamp(0.2, 0.8);
            _photoUploadLabel =
                attempt == 1 ? 'Uploading photo...' : 'Retrying upload (attempt $attempt)...';
          });
        },
      );

      if (!mounted || uploadGeneration != _photoUploadGeneration || !_isEditingProfile) {
        return;
      }
      _updateState(() {
        _photoUploadProgress = 1;
        _photoUploadLabel = 'Upload complete.';
        _storeLogoUrlController.text = generatedR2Url;
        _isUploadingPhoto = false;
      });

      await showSettingsAlertDialog(
        context: context,
        title: 'Photo Ready',
        message:
            'Your new store photo is ready. Click Save Changes to apply it.',
        type: SettingsDialogType.success,
      );
    } catch (_) {
      if (!mounted || uploadGeneration != _photoUploadGeneration || !_isEditingProfile) {
        return;
      }
      _updateState(() {
        _isUploadingPhoto = false;
        _photoUploadProgress = 0;
        _photoUploadLabel = 'Preparing your photo...';
      });
      await showSettingsAlertDialog(
        context: context,
        title: 'Upload Failed',
        message:
            'Could not upload image to Cloudflare R2. Please check network and try again.',
        type: SettingsDialogType.error,
      );
    }
  }

  Future<void> _pickAndPrepareVerificationDocument({
    required String fieldLabel,
    required void Function(String url) onUrlReady,
    required void Function(bool value) setUploading,
    required void Function(double value) setProgress,
    required String storageSlug,
  }) async {
    int uploadGeneration = 0;
    if (!_isEditingVerification) {
      await showSettingsAlertDialog(
        context: context,
        title: 'Edit Mode Required',
        message: 'Tap Edit in Document Verification first to change this file.',
        type: SettingsDialogType.info,
      );
      return;
    }

    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1600,
      );
      if (file == null) {
        return;
      }

      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }
      uploadGeneration = _startVerificationUploadGeneration(storageSlug);
      _updateState(() {
        setUploading(true);
        setProgress(0.1);
        if (storageSlug == SettingsContracts.citizenshipStorageSlug) {
          _citizenshipUploadLabel = 'Checking connection...';
        } else if (storageSlug ==
            SettingsContracts.businessRegistrationStorageSlug) {
          _businessRegUploadLabel = 'Checking connection...';
        } else if (storageSlug == SettingsContracts.panStorageSlug) {
          _panUploadLabel = 'Checking connection...';
        }
      });

      final String merchantId = _merchant?.merchantId ?? 'unknown';
      final int now = DateTime.now().millisecondsSinceEpoch;
      final String objectPath =
          'merchants/$merchantId/docs/${storageSlug}_$now.jpg';

      final String generatedUrl = await _r2UploadService.uploadFile(
        bytes: bytes,
        objectPath: objectPath,
        contentType: _contentTypeFromPath(file.path),
        timeout: const Duration(seconds: 25),
        maxRetries: 2,
        onAttempt: (int attempt) {
          if (!mounted || _isVerificationUploadStale(storageSlug, uploadGeneration)) {
            return;
          }
          _updateState(() {
            setProgress((0.2 + (attempt - 1) * 0.2).clamp(0.2, 0.8));
            final String message = attempt == 1
                ? 'Uploading document...'
                : 'Retrying upload (attempt $attempt)...';
            if (storageSlug == SettingsContracts.citizenshipStorageSlug) {
              _citizenshipUploadLabel = message;
            } else if (storageSlug ==
                SettingsContracts.businessRegistrationStorageSlug) {
              _businessRegUploadLabel = message;
            } else if (storageSlug == SettingsContracts.panStorageSlug) {
              _panUploadLabel = message;
            }
          });
        },
      );

      if (!mounted || _isVerificationUploadStale(storageSlug, uploadGeneration)) {
        return;
      }
      _updateState(() {
        setProgress(1);
        onUrlReady(generatedUrl);
        setUploading(false);
        if (storageSlug == SettingsContracts.citizenshipStorageSlug) {
          _citizenshipUploadLabel = 'Upload complete.';
        } else if (storageSlug ==
            SettingsContracts.businessRegistrationStorageSlug) {
          _businessRegUploadLabel = 'Upload complete.';
        } else if (storageSlug == SettingsContracts.panStorageSlug) {
          _panUploadLabel = 'Upload complete.';
        }
      });

      await showSettingsAlertDialog(
        context: context,
        title: '$fieldLabel Ready',
        message: '$fieldLabel file is ready. Click Save Changes to apply it.',
        type: SettingsDialogType.success,
      );
    } catch (_) {
      if (!mounted || _isVerificationUploadStale(storageSlug, uploadGeneration)) {
        return;
      }
      _updateState(() {
        setUploading(false);
        setProgress(0);
        if (storageSlug == SettingsContracts.citizenshipStorageSlug) {
          _citizenshipUploadLabel = 'Preparing your document...';
        } else if (storageSlug ==
            SettingsContracts.businessRegistrationStorageSlug) {
          _businessRegUploadLabel = 'Preparing your document...';
        } else if (storageSlug == SettingsContracts.panStorageSlug) {
          _panUploadLabel = 'Preparing your document...';
        }
      });
      await showSettingsAlertDialog(
        context: context,
        title: 'File Selection Failed',
        message:
            'Could not upload the selected file to Cloudflare R2. Please retry.',
        type: SettingsDialogType.error,
      );
    }
  }

  Future<void> _pickCitizenshipDocument() async {
    await _pickAndPrepareVerificationDocument(
      fieldLabel: 'Citizenship Document',
      storageSlug: SettingsContracts.citizenshipStorageSlug,
      onUrlReady: (String url) => _citizenshipUrlController.text = url,
      setUploading: (bool value) => _isUploadingCitizenship = value,
      setProgress: (double value) => _citizenshipUploadProgress = value,
    );
  }

  Future<void> _pickBusinessRegistrationDocument() async {
    await _pickAndPrepareVerificationDocument(
      fieldLabel: 'Business Registration',
      storageSlug: SettingsContracts.businessRegistrationStorageSlug,
      onUrlReady: (String url) => _businessRegUrlController.text = url,
      setUploading: (bool value) => _isUploadingBusinessReg = value,
      setProgress: (double value) => _businessRegUploadProgress = value,
    );
  }

  Future<void> _pickPanDocument() async {
    await _pickAndPrepareVerificationDocument(
      fieldLabel: 'PAN Document',
      storageSlug: SettingsContracts.panStorageSlug,
      onUrlReady: (String url) => _panUrlController.text = url,
      setUploading: (bool value) => _isUploadingPan = value,
      setProgress: (double value) => _panUploadProgress = value,
    );
  }

  void _toggleEsewa(bool value) {
    if (_payments == null) {
      return;
    }

    if (value && !_hasEsewaCredentials()) {
      showSettingsAlertDialog(
        context: context,
        title: 'Missing Credentials',
        message:
            'Enter Merchant Code and Secret Key before enabling eSewa.',
        type: SettingsDialogType.info,
      );
      return;
    }

    if (!value &&
        _payments!.esewa.isActive &&
        _activePaymentMethodCount(_payments!) == 1) {
      showSettingsAlertDialog(
        context: context,
        title: 'At Least One Method Required',
        message:
            'You cannot disable eSewa now because it is the only active method.',
        type: SettingsDialogType.info,
      );
      return;
    }

    if (!value && _payments!.esewa.isActive) {
      _confirmDisableMethod('eSewa').then((bool shouldDisable) {
        if (!mounted || !shouldDisable) {
          return;
        }

        _updateState(() {
          _payments = MerchantPaymentsPrivateSettings(
            esewa: PaymentMethodSecrets(
              isActive: false,
              credentials: _payments!.esewa.credentials,
            ),
            khalti: _payments!.khalti,
            bankTransfer: _payments!.bankTransfer,
            cod: _payments!.cod,
          );
        });
      });
      return;
    }

    _updateState(() {
      _payments = MerchantPaymentsPrivateSettings(
        esewa: PaymentMethodSecrets(
          isActive: value,
          credentials: _payments!.esewa.credentials,
        ),
        khalti: _payments!.khalti,
        bankTransfer: _payments!.bankTransfer,
        cod: _payments!.cod,
      );
    });
  }

  void _toggleKhalti(bool value) {
    if (_payments == null) {
      return;
    }

    if (value && !_hasKhaltiCredentials()) {
      showSettingsAlertDialog(
        context: context,
        title: 'Missing Credentials',
        message:
            'Enter Public Key and Secret Key before enabling Khalti.',
        type: SettingsDialogType.info,
      );
      return;
    }

    if (!value &&
        _payments!.khalti.isActive &&
        _activePaymentMethodCount(_payments!) == 1) {
      showSettingsAlertDialog(
        context: context,
        title: 'At Least One Method Required',
        message:
            'You cannot disable Khalti now because it is the only active method.',
        type: SettingsDialogType.info,
      );
      return;
    }

    if (!value && _payments!.khalti.isActive) {
      _confirmDisableMethod('Khalti').then((bool shouldDisable) {
        if (!mounted || !shouldDisable) {
          return;
        }

        _updateState(() {
          _payments = MerchantPaymentsPrivateSettings(
            esewa: _payments!.esewa,
            khalti: PaymentMethodSecrets(
              isActive: false,
              credentials: _payments!.khalti.credentials,
            ),
            bankTransfer: _payments!.bankTransfer,
            cod: _payments!.cod,
          );
        });
      });
      return;
    }

    _updateState(() {
      _payments = MerchantPaymentsPrivateSettings(
        esewa: _payments!.esewa,
        khalti: PaymentMethodSecrets(
          isActive: value,
          credentials: _payments!.khalti.credentials,
        ),
        bankTransfer: _payments!.bankTransfer,
        cod: _payments!.cod,
      );
    });
  }

  void _toggleBankTransfer(bool value) {
    if (_payments == null) {
      return;
    }

    if (value && !_hasBankTransferCredentials()) {
      showSettingsAlertDialog(
        context: context,
        title: 'Missing Credentials',
        message:
            'Enter Bank Name, Account Name and Account Number before enabling Bank Transfer.',
        type: SettingsDialogType.info,
      );
      return;
    }

    if (!value &&
        _payments!.bankTransfer.isActive &&
        _activePaymentMethodCount(_payments!) == 1) {
      showSettingsAlertDialog(
        context: context,
        title: 'At Least One Method Required',
        message:
            'You cannot disable Bank Transfer now because it is the only active method.',
        type: SettingsDialogType.info,
      );
      return;
    }

    if (!value && _payments!.bankTransfer.isActive) {
      _confirmDisableMethod('Bank Transfer').then((bool shouldDisable) {
        if (!mounted || !shouldDisable) {
          return;
        }

        _updateState(() {
          _payments = MerchantPaymentsPrivateSettings(
            esewa: _payments!.esewa,
            khalti: _payments!.khalti,
            bankTransfer: PaymentMethodSecrets(
              isActive: false,
              credentials: _payments!.bankTransfer.credentials,
            ),
            cod: _payments!.cod,
          );
        });
      });
      return;
    }

    _updateState(() {
      _payments = MerchantPaymentsPrivateSettings(
        esewa: _payments!.esewa,
        khalti: _payments!.khalti,
        bankTransfer: PaymentMethodSecrets(
          isActive: value,
          credentials: _payments!.bankTransfer.credentials,
        ),
        cod: _payments!.cod,
      );
    });
  }

  void _toggleCod(bool value) {
    if (_payments == null) {
      return;
    }

    if (!value &&
        _payments!.cod.isActive &&
        _activePaymentMethodCount(_payments!) == 1) {
      showSettingsAlertDialog(
        context: context,
        title: 'At Least One Method Required',
        message:
            'You cannot disable Cash on Delivery now because it is the only active method.',
        type: SettingsDialogType.info,
      );
      return;
    }

    if (!value && _payments!.cod.isActive) {
      _confirmDisableMethod('Cash on Delivery').then((bool shouldDisable) {
        if (!mounted || !shouldDisable) {
          return;
        }

        _updateState(() {
          _payments = MerchantPaymentsPrivateSettings(
            esewa: _payments!.esewa,
            khalti: _payments!.khalti,
            bankTransfer: _payments!.bankTransfer,
            cod: const PaymentMethodSecrets(
              isActive: false,
              credentials: {},
            ),
          );
        });
      });
      return;
    }

    _updateState(() {
      _payments = MerchantPaymentsPrivateSettings(
        esewa: _payments!.esewa,
        khalti: _payments!.khalti,
        bankTransfer: _payments!.bankTransfer,
        cod: const PaymentMethodSecrets(
          isActive: true,
          credentials: {},
        ),
      );
    });
  }
}
