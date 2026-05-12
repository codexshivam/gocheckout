import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/widgets/app_panel.dart';
import '../../../theme/app_colors.dart';
import '../settings_widgets.dart';

class SettingsPaymentsTab extends StatelessWidget {
  const SettingsPaymentsTab({
    super.key,
    required this.formKey,
    required this.esewaEnabled,
    required this.khaltiEnabled,
    required this.bankTransferEnabled,
    required this.codEnabled,
    required this.isEditing,
    required this.isSaving,
    required this.lastModifiedAt,
    required this.lastModifiedBy,
    required this.esewaMerchantCodeController,
    required this.esewaSecretKeyController,
    required this.khaltiPublicKeyController,
    required this.khaltiSecretKeyController,
    required this.bankNameController,
    required this.bankAccountNameController,
    required this.bankAccountNumberController,
    required this.isEsewaSecretObscured,
    required this.isKhaltiSecretObscured,
    required this.onToggleEsewaSecretVisibility,
    required this.onToggleKhaltiSecretVisibility,
    required this.onToggleEsewa,
    required this.onToggleKhalti,
    required this.onToggleBankTransfer,
    required this.onToggleCod,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
    required this.softButtonStyle,
    required this.primaryButtonStyle,
    required this.inputDecorationBuilder,
  });

  final GlobalKey<FormState> formKey;
  final bool esewaEnabled;
  final bool khaltiEnabled;
  final bool bankTransferEnabled;
  final bool codEnabled;
  final bool isEditing;
  final bool isSaving;
  final String? lastModifiedAt;
  final String? lastModifiedBy;
  final TextEditingController esewaMerchantCodeController;
  final TextEditingController esewaSecretKeyController;
  final TextEditingController khaltiPublicKeyController;
  final TextEditingController khaltiSecretKeyController;
  final TextEditingController bankNameController;
  final TextEditingController bankAccountNameController;
  final TextEditingController bankAccountNumberController;
  final bool isEsewaSecretObscured;
  final bool isKhaltiSecretObscured;
  final VoidCallback onToggleEsewaSecretVisibility;
  final VoidCallback onToggleKhaltiSecretVisibility;
  final ValueChanged<bool> onToggleEsewa;
  final ValueChanged<bool> onToggleKhalti;
  final ValueChanged<bool> onToggleBankTransfer;
  final ValueChanged<bool> onToggleCod;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;
  final ButtonStyle softButtonStyle;
  final ButtonStyle primaryButtonStyle;
  final InputDecoration Function(String) inputDecorationBuilder;

  String? _bankAccountNumberValidator(String? value) {
    final String raw = (value ?? '').trim();
    final RegExp digitsOnly = RegExp(r'^[0-9]{6,24}$');
    if (!digitsOnly.hasMatch(raw)) {
      return 'Account Number must be 6-24 digits';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final int activeMethodCount =
        (esewaEnabled ? 1 : 0) + (khaltiEnabled ? 1 : 0) + (bankTransferEnabled ? 1 : 0) + (codEnabled ? 1 : 0);
    final String updatedAtText =
      (lastModifiedAt ?? '').trim().isEmpty ? 'Not available' : lastModifiedAt!;
    final String updatedByText =
      (lastModifiedBy ?? '').trim().isEmpty ? 'Unknown' : lastModifiedBy!;

    return Form(
      key: formKey,
      child: ListView(
        children: [
          AppPanel(
            title: 'Checkout Guardrails',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      activeMethodCount > 0 ? Icons.shield_outlined : Icons.gpp_maybe_outlined,
                      color: activeMethodCount > 0 ? AppColors.deliveredText : AppColors.rtoText,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active Gateways: $activeMethodCount of 4',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: activeMethodCount > 0 ? AppColors.deliveredText : AppColors.rtoText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Keep at least one verified payment gateway active so your store can accept transactions seamlessly.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Status and configuration modifications are applied to your active store only after you click Save Changes.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SettingsPaymentAccordion(
            title: 'Cash on Delivery (COD)',
            enabled: codEnabled,
            readOnly: !isEditing,
            fields: const [],
            onToggle: onToggleCod,
            inputDecorationBuilder: inputDecorationBuilder,
            baseFocusOrder: 0,
          ),
          const SizedBox(height: 12),
          SettingsPaymentAccordion(
            title: 'eSewa Integration',
            enabled: esewaEnabled,
            readOnly: !isEditing,
            fields: [
              SettingsPaymentField(
                label: 'Merchant Code',
                controller: esewaMerchantCodeController,
                textInputAction: TextInputAction.next,
                semanticLabel: 'eSewa Merchant Code',
                semanticHint: 'Required when eSewa is enabled',
              ),
              SettingsPaymentField(
                label: 'Secret Key',
                controller: esewaSecretKeyController,
                obscureText: true,
                isObscured: isEsewaSecretObscured,
                onToggleObscure: onToggleEsewaSecretVisibility,
                textInputAction: TextInputAction.done,
                semanticLabel: 'eSewa Secret Key',
                semanticHint: 'Required when eSewa is enabled',
              ),
            ],
            onToggle: onToggleEsewa,
            inputDecorationBuilder: inputDecorationBuilder,
            baseFocusOrder: 10,
          ),
          const SizedBox(height: 12),
          SettingsPaymentAccordion(
            title: 'Khalti Integration',
            enabled: khaltiEnabled,
            readOnly: !isEditing,
            fields: [
              SettingsPaymentField(
                label: 'Public Key',
                controller: khaltiPublicKeyController,
                textInputAction: TextInputAction.next,
                semanticLabel: 'Khalti Public Key',
                semanticHint: 'Required when Khalti is enabled',
              ),
              SettingsPaymentField(
                label: 'Secret Key',
                controller: khaltiSecretKeyController,
                obscureText: true,
                isObscured: isKhaltiSecretObscured,
                onToggleObscure: onToggleKhaltiSecretVisibility,
                textInputAction: TextInputAction.done,
                semanticLabel: 'Khalti Secret Key',
                semanticHint: 'Required when Khalti is enabled',
              ),
            ],
            onToggle: onToggleKhalti,
            inputDecorationBuilder: inputDecorationBuilder,
            baseFocusOrder: 20,
          ),
          const SizedBox(height: 12),
          SettingsPaymentAccordion(
            title: 'Direct Bank Transfer',
            enabled: bankTransferEnabled,
            readOnly: !isEditing,
            fields: [
              SettingsPaymentField(
                label: 'Bank Name',
                controller: bankNameController,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.organizationName],
                semanticLabel: 'Bank Transfer Bank Name',
                semanticHint: 'Required when bank transfer is enabled',
              ),
              SettingsPaymentField(
                label: 'Account Name',
                controller: bankAccountNameController,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.name],
                semanticLabel: 'Bank Transfer Account Name',
                semanticHint: 'Required when bank transfer is enabled',
              ),
              SettingsPaymentField(
                label: 'Account Number',
                controller: bankAccountNumberController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.creditCardNumber],
                validator: _bankAccountNumberValidator,
                semanticLabel: 'Bank Transfer Account Number',
                semanticHint: 'Required when bank transfer is enabled',
              ),
            ],
            onToggle: onToggleBankTransfer,
            inputDecorationBuilder: inputDecorationBuilder,
            baseFocusOrder: 30,
          ),
          const SizedBox(height: 20),
          AppPanel(
            title: 'Gateway Maintenance Details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Click Edit to activate/deactivate standard provider toggles and adjust credentials safely. Double check credentials to prevent checkout failures.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Last modified:',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    Text(
                      updatedAtText,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Modified by:',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    Text(
                      updatedByText,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SettingsPanelActions(
                  isEditing: isEditing,
                  isSaving: isSaving,
                  onEdit: onEdit,
                  onCancel: onCancel,
                  onSave: onSave,
                  primaryButtonStyle: primaryButtonStyle,
                  softButtonStyle: softButtonStyle,
                  canSave: activeMethodCount > 0,
                  saveDisabledReason: 'Enable at least one payment method to save.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
