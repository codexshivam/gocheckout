enum SettingsTabId {
  basicDetails,
  documentVerification,
  paymentSettings,
  teamAccess,
}

extension SettingsTabIdValue on SettingsTabId {
  int get index {
    switch (this) {
      case SettingsTabId.basicDetails:
        return 0;
      case SettingsTabId.documentVerification:
        return 1;
      case SettingsTabId.paymentSettings:
        return 2;
      case SettingsTabId.teamAccess:
        return 3;
    }
  }

  String get label {
    switch (this) {
      case SettingsTabId.basicDetails:
        return SettingsContracts.basicDetailsSection;
      case SettingsTabId.documentVerification:
        return SettingsContracts.documentVerificationSection;
      case SettingsTabId.paymentSettings:
        return SettingsContracts.paymentSettingsSection;
      case SettingsTabId.teamAccess:
        return SettingsContracts.teamAccessSection;
    }
  }
}

class SettingsContracts {
  static const String basicDetailsSection = 'Basic Details';
  static const String documentVerificationSection = 'Document Verification';
  static const String paymentSettingsSection = 'Payment Settings';
  static const String teamAccessSection = 'Team Access';

  static const String discardEditsTitle = 'Discard Edits?';
  static const String discardUnsavedTitle = 'Discard Unsaved Changes?';
  static const String keepEditingAction = 'Keep Editing';
  static const String discardAction = 'Discard';

  static const String citizenshipStorageSlug = 'citizenship';
  static const String businessRegistrationStorageSlug = 'business_registration';
  static const String panStorageSlug = 'pan';

  static const String esewaProviderKey = 'esewa';
  static const String khaltiProviderKey = 'khalti';
  static const String bankTransferProviderKey = 'bankTransfer';
  static const String codProviderKey = 'cod';

  static const String esewaProviderLabel = 'eSewa';
  static const String khaltiProviderLabel = 'Khalti';
  static const String bankTransferProviderLabel = 'Bank Transfer';
  static const String codProviderLabel = 'Cash on Delivery';

  static const String verificationSaveDisabledReason =
      'Attach valid Citizenship, Business Registration, and PAN files to enable save.';
}
