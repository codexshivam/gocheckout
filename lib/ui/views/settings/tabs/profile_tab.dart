import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/schema/merchant_models.dart';
import '../../../common/widgets/app_panel.dart';
import '../../../theme/app_colors.dart';
import '../settings_widgets.dart';

class SettingsProfileTab extends StatelessWidget {
  const SettingsProfileTab({
    super.key,
    required this.formKey,
    required this.businessNameController,
    required this.businessAddressController,
    required this.emailController,
    required this.phoneController,
    required this.whatsappController,
    required this.status,
    required this.photoUrl,
    required this.photoPreviewBytes,
    required this.isEditing,
    required this.isSaving,
    required this.isUploadingPhoto,
    required this.uploadProgress,
    required this.uploadLabel,
    required this.onChangePhoto,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
    required this.softButtonStyle,
    required this.primaryButtonStyle,
    required this.inputDecorationBuilder,
    required this.requiredValidator,
    required this.emailValidator,
    required this.phoneValidator,
    required this.whatsappValidator,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController businessNameController;
  final TextEditingController businessAddressController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController whatsappController;
  final MerchantVerificationStatus status;
  final String photoUrl;
  final Uint8List? photoPreviewBytes;
  final bool isEditing;
  final bool isSaving;
  final bool isUploadingPhoto;
  final double uploadProgress;
  final String uploadLabel;
  final Future<void> Function() onChangePhoto;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;
  final ButtonStyle softButtonStyle;
  final ButtonStyle primaryButtonStyle;
  final InputDecoration Function(String) inputDecorationBuilder;
  final String? Function(String?, String) requiredValidator;
  final String? Function(String?) emailValidator;
  final String? Function(String?) phoneValidator;
  final String? Function(String?) whatsappValidator;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        AppPanel(
          title: 'Business Profile',
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsProfilePhotoSection(
                  photoUrl: photoUrl,
                  photoPreviewBytes: photoPreviewBytes,
                  isEditing: isEditing,
                  isUploading: isUploadingPhoto,
                  uploadProgress: uploadProgress,
                  uploadLabel: uploadLabel,
                  onChangePhoto: onChangePhoto,
                  softButtonStyle: softButtonStyle,
                  changePhotoFocusOrder: 1,
                ),
                const SizedBox(height: 20),
                Text(
                  'Business Identity',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 10),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(2),
                  child: Semantics(
                    textField: true,
                    label: 'Business Name',
                    hint: 'Required',
                    child: TextFormField(
                      controller: businessNameController,
                      enabled: isEditing,
                      decoration: inputDecorationBuilder('Business Name *'),
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.organizationName],
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textPrimary,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                      validator: (String? value) =>
                          requiredValidator(value, 'Business name'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(3),
                  child: Semantics(
                    textField: true,
                    label: 'Business Address',
                    hint: 'Required',
                    child: TextFormField(
                      controller: businessAddressController,
                      enabled: isEditing,
                      decoration: inputDecorationBuilder('Business Address *'),
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.fullStreetAddress],
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textPrimary,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                      validator: (String? value) =>
                          requiredValidator(value, 'Business address'),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Contact Information',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 10),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(4),
                  child: Semantics(
                    textField: true,
                    label: 'Email',
                    hint: 'Required',
                    child: TextFormField(
                      controller: emailController,
                      enabled: isEditing,
                      decoration: inputDecorationBuilder('Email *'),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.email],
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textPrimary,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                      validator: emailValidator,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(5),
                  child: Semantics(
                    textField: true,
                    label: 'Phone',
                    hint: 'Required',
                    child: TextFormField(
                      controller: phoneController,
                      enabled: isEditing,
                      decoration: inputDecorationBuilder('Phone *'),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.telephoneNumber],
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textPrimary,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                      validator: phoneValidator,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(6),
                  child: Semantics(
                    textField: true,
                    label: 'WhatsApp',
                    hint: 'Required',
                    child: TextFormField(
                      controller: whatsappController,
                      enabled: isEditing,
                      decoration: inputDecorationBuilder('WhatsApp *'),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofillHints: const <String>[AutofillHints.telephoneNumber],
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textPrimary,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                      validator: whatsappValidator,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Changing contact details may require verification and affect transaction alerts.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 16),
                SettingsMerchantStatusRow(status: status),
                const SizedBox(height: 20),
                SettingsPanelActions(
                  isEditing: isEditing,
                  isSaving: isSaving,
                  onEdit: onEdit,
                  onCancel: onCancel,
                  onSave: onSave,
                  primaryButtonStyle: primaryButtonStyle,
                  softButtonStyle: softButtonStyle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
