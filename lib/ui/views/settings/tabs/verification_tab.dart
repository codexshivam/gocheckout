import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/widgets/app_panel.dart';
import '../../../common/widgets/status_badge.dart';
import '../../../theme/app_colors.dart';
import '../settings_widgets.dart';

class SettingsVerificationTab extends StatelessWidget {
  const SettingsVerificationTab({
    super.key,
    required this.formKey,
    required this.verificationStatusLabel,
    required this.citizenshipUrlController,
    required this.businessRegUrlController,
    required this.panUrlController,
    required this.isEditing,
    required this.isSaving,
    required this.isUploadingCitizenship,
    required this.citizenshipUploadProgress,
    required this.citizenshipUploadLabel,
    required this.isUploadingBusinessReg,
    required this.businessRegUploadProgress,
    required this.businessRegUploadLabel,
    required this.isUploadingPan,
    required this.panUploadProgress,
    required this.panUploadLabel,
    required this.onPickCitizenship,
    required this.onPickBusinessReg,
    required this.onPickPan,
    required this.onViewCitizenship,
    required this.onViewBusinessReg,
    required this.onViewPan,
    required this.canViewCitizenship,
    required this.canViewBusinessReg,
    required this.canViewPan,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
    required this.softButtonStyle,
    required this.primaryButtonStyle,
    required this.canSave,
    required this.saveDisabledReason,
    required this.onRequestSupport,
  });

  final GlobalKey<FormState> formKey;
  final String verificationStatusLabel;
  final TextEditingController citizenshipUrlController;
  final TextEditingController businessRegUrlController;
  final TextEditingController panUrlController;
  final bool isEditing;
  final bool isSaving;
  final bool isUploadingCitizenship;
  final double citizenshipUploadProgress;
  final String citizenshipUploadLabel;
  final bool isUploadingBusinessReg;
  final double businessRegUploadProgress;
  final String businessRegUploadLabel;
  final bool isUploadingPan;
  final double panUploadProgress;
  final String panUploadLabel;
  final Future<void> Function() onPickCitizenship;
  final Future<void> Function() onPickBusinessReg;
  final Future<void> Function() onPickPan;
  final VoidCallback onViewCitizenship;
  final VoidCallback onViewBusinessReg;
  final VoidCallback onViewPan;
  final bool canViewCitizenship;
  final bool canViewBusinessReg;
  final bool canViewPan;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;
  final ButtonStyle softButtonStyle;
  final ButtonStyle primaryButtonStyle;
  final bool canSave;
  final String saveDisabledReason;
  final Future<void> Function() onRequestSupport;

  @override
  Widget build(BuildContext context) {
    final bool hasCitizenship = citizenshipUrlController.text.trim().isNotEmpty;
    final bool hasBusinessReg = businessRegUrlController.text.trim().isNotEmpty;
    final bool hasPan = panUrlController.text.trim().isNotEmpty;
    final bool isRejected =
        verificationStatusLabel.trim().toUpperCase() == 'REJECTED';

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                'Verification Status: ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              StatusBadge(status: verificationStatusLabel),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.8),
              width: 1.2,
            ),
            borderRadius: kRadiusMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verification Checklist',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 12),
              _ChecklistItem(
                label: 'Citizenship Document',
                done: hasCitizenship,
              ),
              _ChecklistItem(
                label: 'Business Registration Document',
                done: hasBusinessReg,
              ),
              _ChecklistItem(label: 'PAN Registration Document', done: hasPan),
              const SizedBox(height: 12),
              Text(
                'Upload clear, high-resolution original document files (JPG, PNG, WebP). Ensure text is legible and well-lit.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (isRejected)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              border: Border.all(
                color: const Color(0xFFFCA5A5).withValues(alpha: 0.5),
                width: 1.2,
              ),
              borderRadius: kRadiusMedium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFB91C1C),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Action Required: Re-verification Needed',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your verification application was rejected by the audit team. Please re-examine and upload clear documents.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF991B1B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        AppPanel(
          title: 'Verification Documents',
          child: Form(
            key: formKey,
            child: Column(
              children: [
                SettingsDocumentUploadTile(
                  title: 'Citizenship Document',
                  description:
                      'Upload a scan or clean picture of your official citizenship (both sides if applicable).',
                  documentUrl: citizenshipUrlController.text,
                  isEditing: isEditing,
                  isUploading: isUploadingCitizenship,
                  uploadProgress: citizenshipUploadProgress,
                  uploadLabel: citizenshipUploadLabel,
                  onPickAndUpload: onPickCitizenship,
                  onView: onViewCitizenship,
                  canView: canViewCitizenship,
                  softButtonStyle: softButtonStyle,
                  viewFocusOrder: 1,
                  pickFocusOrder: 2,
                ),
                const SizedBox(height: 12),
                SettingsDocumentUploadTile(
                  title: 'Business Registration',
                  description:
                      'Upload a clear copy of your formal corporate / firm registration document.',
                  documentUrl: businessRegUrlController.text,
                  isEditing: isEditing,
                  isUploading: isUploadingBusinessReg,
                  uploadProgress: businessRegUploadProgress,
                  uploadLabel: businessRegUploadLabel,
                  onPickAndUpload: onPickBusinessReg,
                  onView: onViewBusinessReg,
                  canView: canViewBusinessReg,
                  softButtonStyle: softButtonStyle,
                  viewFocusOrder: 3,
                  pickFocusOrder: 4,
                ),
                const SizedBox(height: 12),
                SettingsDocumentUploadTile(
                  title: 'PAN Document',
                  description:
                      'Upload your company tax / PAN registration certificate.',
                  documentUrl: panUrlController.text,
                  isEditing: isEditing,
                  isUploading: isUploadingPan,
                  uploadProgress: panUploadProgress,
                  uploadLabel: panUploadLabel,
                  onPickAndUpload: onPickPan,
                  onView: onViewPan,
                  canView: canViewPan,
                  softButtonStyle: softButtonStyle,
                  viewFocusOrder: 5,
                  pickFocusOrder: 6,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your changes are saved to the platform instantly after document upload. Use View to inspect files.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 20),
                SettingsPanelActions(
                  isEditing: isEditing,
                  isSaving: isSaving,
                  onEdit: onEdit,
                  onCancel: onCancel,
                  onSave: onSave,
                  primaryButtonStyle: primaryButtonStyle,
                  softButtonStyle: softButtonStyle,
                  canSave: canSave,
                  saveDisabledReason: saveDisabledReason,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppPanel(
          title: 'Verification Assistance',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRejected
                    ? 'Our support desk can help you understand compliance criteria and guide you through resubmissions.'
                    : 'If you have questions regarding document formats, size limits, or processing SLA, get in touch with our team.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              FocusTraversalOrder(
                order: const NumericFocusOrder(7),
                child: Semantics(
                  button: true,
                  label: 'Contact verification support',
                  hint:
                      'Shows support details for document verification issues',
                  child: OutlinedButton.icon(
                    style: softButtonStyle,
                    onPressed: onRequestSupport,
                    icon: const Icon(Icons.support_agent_outlined, size: 18),
                    label: Text(
                      'Contact Support Desk',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label ${done ? 'completed' : 'pending'}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: done ? AppColors.deliveredText : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: done ? AppColors.black : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
