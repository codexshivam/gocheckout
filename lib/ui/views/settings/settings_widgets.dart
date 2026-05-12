import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/schema/merchant_models.dart';
import '../../theme/app_colors.dart';
import '../../common/widgets/status_badge.dart';

class SettingsMerchantStatusRow extends StatelessWidget {
  const SettingsMerchantStatusRow({super.key, required this.status});

  final MerchantVerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final String label;
    switch (status) {
      case MerchantVerificationStatus.pending:
        label = 'Pending Verification';
      case MerchantVerificationStatus.verified:
        label = 'Verified Store';
      case MerchantVerificationStatus.rejected:
        label = 'Verification Rejected';
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          'Verification Status:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        StatusBadge(status: label),
      ],
    );
  }
}

class SettingsProfilePhotoSection extends StatelessWidget {
  const SettingsProfilePhotoSection({
    super.key,
    this.photoUrl = '',
    this.photoPreviewBytes,
    this.isEditing,
    this.isUploading,
    this.uploadProgress,
    this.uploadLabel,
    this.changePhotoFocusOrder,
    required this.onChangePhoto,
    required this.softButtonStyle,
  });

  final String photoUrl;
  final Uint8List? photoPreviewBytes;
  final bool? isEditing;
  final bool? isUploading;
  final double? uploadProgress;
  final String? uploadLabel;
  final double? changePhotoFocusOrder;
  final Future<void> Function() onChangePhoto;
  final ButtonStyle softButtonStyle;

  @override
  Widget build(BuildContext context) {
    final bool editing = isEditing ?? false;
    final bool uploading = isUploading ?? false;
    final double progress = uploadProgress ?? 0;
    final ImageProvider<Object>? provider = photoPreviewBytes != null
        ? MemoryImage(photoPreviewBytes!)
        : (photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: kRadiusMedium,
        color: AppColors.offWhite,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.8),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.white,
              backgroundImage: provider,
              child: provider == null
                  ? const Icon(
                      Icons.storefront_outlined,
                      color: AppColors.textSecondary,
                      size: 32,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Store Logo / Cover Photo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This brand logo will represent your store on checkout pages and is visible to all customers.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                FocusTraversalOrder(
                  order: NumericFocusOrder(changePhotoFocusOrder ?? 1),
                  child: Semantics(
                    button: true,
                    label: 'Choose and upload store photo',
                    hint:
                        'Select an image for your store logo. Changes apply after saving profile.',
                    child: OutlinedButton.icon(
                      style: softButtonStyle,
                      onPressed: editing && !uploading ? onChangePhoto : null,
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: Text(
                        'Upload Brand Photo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                if (uploading) ...<Widget>[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      color: AppColors.primary,
                      backgroundColor: AppColors.border,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    uploadLabel ??
                        'Preparing photo... ${(progress * 100).round()}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPaymentField {
  const SettingsPaymentField({
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.isObscured,
    this.onToggleObscure,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.semanticLabel,
    this.semanticHint,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final bool? isObscured;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final String? semanticLabel;
  final String? semanticHint;
}

class SettingsDocumentUploadTile extends StatelessWidget {
  const SettingsDocumentUploadTile({
    super.key,
    required this.title,
    required this.description,
    this.documentUrl = '',
    this.isEditing,
    this.isUploading,
    this.uploadProgress,
    this.uploadLabel,
    required this.onPickAndUpload,
    required this.onView,
    required this.canView,
    required this.softButtonStyle,
    this.viewSemanticLabel,
    this.pickSemanticLabel,
    this.viewSemanticHint,
    this.pickSemanticHint,
    this.viewFocusOrder,
    this.pickFocusOrder,
  });

  final String title;
  final String description;
  final String documentUrl;
  final bool? isEditing;
  final bool? isUploading;
  final double? uploadProgress;
  final String? uploadLabel;
  final Future<void> Function() onPickAndUpload;
  final VoidCallback onView;
  final bool canView;
  final ButtonStyle softButtonStyle;
  final String? viewSemanticLabel;
  final String? pickSemanticLabel;
  final String? viewSemanticHint;
  final String? pickSemanticHint;
  final double? viewFocusOrder;
  final double? pickFocusOrder;

  @override
  Widget build(BuildContext context) {
    final bool editing = isEditing ?? false;
    final bool uploading = isUploading ?? false;
    final double progress = uploadProgress ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: kRadiusMedium,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.8),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 160, maxWidth: 320),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      documentUrl.isEmpty
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      size: 14,
                      color: documentUrl.isEmpty
                          ? AppColors.textSecondary
                          : AppColors.deliveredText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        documentUrl.isEmpty
                            ? 'No file uploaded yet'
                            : 'Document attached & validated',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: documentUrl.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.deliveredText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FocusTraversalOrder(
                order: NumericFocusOrder(viewFocusOrder ?? 1),
                child: Semantics(
                  button: true,
                  label: viewSemanticLabel ?? 'View $title',
                  hint:
                      viewSemanticHint ??
                      'Opens a preview of the selected document',
                  child: OutlinedButton(
                    style: softButtonStyle.copyWith(
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                    onPressed: canView ? onView : null,
                    child: Text(
                      'View Document',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              FocusTraversalOrder(
                order: NumericFocusOrder(pickFocusOrder ?? 2),
                child: Semantics(
                  button: true,
                  label: pickSemanticLabel ?? 'Choose file for $title',
                  hint:
                      pickSemanticHint ??
                      'Select and upload a replacement file',
                  child: OutlinedButton.icon(
                    style: softButtonStyle.copyWith(
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                    onPressed: editing && !uploading ? onPickAndUpload : null,
                    icon: const Icon(Icons.upload_file_outlined, size: 16),
                    label: Text(
                      'Choose File',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (uploading) ...<Widget>[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: AppColors.primary,
                backgroundColor: AppColors.border,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              uploadLabel ??
                  'Preparing document... ${(progress * 100).round()}%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SettingsPaymentAccordion extends StatelessWidget {
  const SettingsPaymentAccordion({
    super.key,
    required this.title,
    required this.enabled,
    required this.readOnly,
    required this.fields,
    required this.onToggle,
    required this.inputDecorationBuilder,
    this.baseFocusOrder,
  });

  final String title;
  final bool enabled;
  final bool readOnly;
  final List<SettingsPaymentField> fields;
  final ValueChanged<bool> onToggle;
  final InputDecoration Function(String label) inputDecorationBuilder;
  final double? baseFocusOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          backgroundColor: AppColors.white,
          collapsedBackgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.border.withValues(alpha: 0.8),
              width: 1.2,
            ),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.border.withValues(alpha: 0.8),
              width: 1.2,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.black,
            ),
          ),
          childrenPadding: const EdgeInsets.all(16),
          children: [
            if (fields.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Accept cash payment or scan-on-delivery upon product arrival at the customer\'s doorstep. No external API integration or credentials are required.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            for (int index = 0; index < fields.length; index++) ...<Widget>[
              FocusTraversalOrder(
                order: NumericFocusOrder((baseFocusOrder ?? 100) + index),
                child: Semantics(
                  textField: true,
                  label:
                      fields[index].semanticLabel ??
                      '${fields[index].label} field',
                  hint: fields[index].semanticHint,
                  child: TextFormField(
                    controller: fields[index].controller,
                    enabled: !readOnly,
                    obscureText:
                        fields[index].isObscured ?? fields[index].obscureText,
                    keyboardType: fields[index].keyboardType,
                    textInputAction: fields[index].textInputAction,
                    autofillHints: fields[index].autofillHints,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: inputDecorationBuilder(fields[index].label)
                        .copyWith(
                          suffixIcon: fields[index].onToggleObscure == null
                              ? null
                              : Semantics(
                                  button: true,
                                  label:
                                      (fields[index].isObscured ??
                                          fields[index].obscureText)
                                      ? 'Show ${fields[index].label}'
                                      : 'Hide ${fields[index].label}',
                                  child: IconButton(
                                    tooltip:
                                        (fields[index].isObscured ??
                                            fields[index].obscureText)
                                        ? 'Show'
                                        : 'Hide',
                                    onPressed: fields[index].onToggleObscure,
                                    icon: Icon(
                                      (fields[index].isObscured ??
                                              fields[index].obscureText)
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                    ),
                                  ),
                                ),
                        ),
                    validator: (String? value) {
                      if (enabled && (value ?? '').trim().isEmpty) {
                        return '${fields[index].label} is required when $title is enabled';
                      }
                      if (enabled && fields[index].validator != null) {
                        return fields[index].validator!(value);
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 8),
            FocusTraversalOrder(
              order: NumericFocusOrder(
                (baseFocusOrder ?? 100) + fields.length + 1,
              ),
              child: Semantics(
                toggled: enabled,
                label: 'Enable or disable $title',
                hint:
                    'Controls whether this payment provider is available at checkout',
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Enable / Disable Integration',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  value: enabled,
                  onChanged: readOnly ? null : onToggle,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPanelActions extends StatelessWidget {
  const SettingsPanelActions({
    super.key,
    required this.isEditing,
    required this.isSaving,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
    required this.primaryButtonStyle,
    required this.softButtonStyle,
    this.canSave = true,
    this.saveDisabledReason,
  });

  final bool isEditing;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;
  final ButtonStyle primaryButtonStyle;
  final ButtonStyle softButtonStyle;
  final bool canSave;
  final String? saveDisabledReason;

  @override
  Widget build(BuildContext context) {
    if (!isEditing) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          button: true,
          label: 'Edit section',
          child: OutlinedButton.icon(
            style: softButtonStyle,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(
              'Edit',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 430;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!canSave && (saveDisabledReason ?? '').isNotEmpty) ...[
                Text(
                  saveDisabledReason!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Semantics(
                button: true,
                label: 'Cancel editing',
                child: OutlinedButton(
                  style: softButtonStyle,
                  onPressed: isSaving ? null : onCancel,
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Semantics(
                button: true,
                label: 'Save changes',
                hint: canSave
                    ? 'Commits your updates for this section'
                    : (saveDisabledReason ?? 'Save is currently unavailable'),
                child: ElevatedButton.icon(
                  style: primaryButtonStyle,
                  onPressed: isSaving || !canSave ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    isSaving ? 'Saving...' : 'Save Changes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!canSave && (saveDisabledReason ?? '').isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    saveDisabledReason!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ),
            Semantics(
              button: true,
              label: 'Cancel editing',
              child: OutlinedButton(
                style: softButtonStyle,
                onPressed: isSaving ? null : onCancel,
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Save changes',
              hint: canSave
                  ? 'Commits your updates for this section'
                  : (saveDisabledReason ?? 'Save is currently unavailable'),
              child: ElevatedButton.icon(
                style: primaryButtonStyle,
                onPressed: isSaving || !canSave ? null : onSave,
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(
                  isSaving ? 'Saving...' : 'Save Changes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
