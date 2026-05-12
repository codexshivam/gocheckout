import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/schema/team_access_models.dart';
import '../../../common/app_styles.dart';
import '../../../state/team_access_state_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/table_exporter.dart';

class TeamAccessTab extends StatefulWidget {
  const TeamAccessTab({super.key});

  @override
  State<TeamAccessTab> createState() => _TeamAccessTabState();
}

class _TeamAccessTabState extends State<TeamAccessTab> {
  final TextEditingController _emailController = TextEditingController();

  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TeamAccessStateController controller =
        context.watch<TeamAccessStateController>();

    final List<TeamMemberRecord> activeRows = controller.rows
        .where((row) => row.status == TeamMemberStatus.active)
        .toList();
    final List<TeamMemberRecord> pendingRows = controller.rows
        .where((row) => row.status == TeamMemberStatus.pending)
        .toList()
      ..sort((TeamMemberRecord a, TeamMemberRecord b) {
        final DateTime? aExpiry = a.pendingExpiresAt;
        final DateTime? bExpiry = b.pendingExpiresAt;
        if (aExpiry == null && bExpiry == null) {
          return a.nameOrEmail.compareTo(b.nameOrEmail);
        }
        if (aExpiry == null) {
          return 1;
        }
        if (bExpiry == null) {
          return -1;
        }
        return aExpiry.compareTo(bExpiry);
      });

    return Container(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Access',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add email access for people who can view and edit your store data.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'After you add an email, access is assigned automatically when that person signs in with Google using the same email.',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _InviteActionBar(
              emailController: _emailController,
              selectedRole: controller.selectedRole,
              isLoading: controller.isLoading,
              onRoleChanged: controller.updateSelectedRole,
              onSendInvite: _sendInvite,
              onExport: _exportTeam,
            ),
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                controller.errorMessage!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.rtoText,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                children: [
                  _TeamSection(
                    title: 'Active Members',
                    count: activeRows.length,
                    child: _TeamAccessTable(
                      rows: activeRows,
                      onRemove: _removeMember,
                      onResend: _resendPendingAccess,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TeamSection(
                    title: 'Pending Email Access',
                    count: pendingRows.length,
                    child: _TeamAccessTable(
                      rows: pendingRows,
                      onRemove: _removeMember,
                      onResend: _resendPendingAccess,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractEmail(String raw) {
    final String lower = raw.toLowerCase();
    final int markerIndex = lower.lastIndexOf('•');
    if (markerIndex != -1) {
      return lower.substring(markerIndex + 1).trim();
    }
    return lower.trim();
  }

  bool _emailAlreadyExists(List<TeamMemberRecord> rows, String email) {
    final String normalized = email.toLowerCase().trim();
    return rows.any((row) => _extractEmail(row.nameOrEmail) == normalized);
  }

  void _sendInvite() {
    final TeamAccessStateController controller =
        context.read<TeamAccessStateController>();
    final String email = _emailController.text.trim();

    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address.')),
      );
      return;
    }

    if (_emailAlreadyExists(controller.rows, email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This email already has active or pending access.'),
        ),
      );
      return;
    }

    controller.sendInvite(email).then((bool ok) {
      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save pending email access.')),
        );
        return;
      }

      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email access added for $email.')),
      );
    });
  }

  Future<bool> _confirmRemoveMember(TeamMemberRecord row) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Team Member?'),
          content: Text(
            row.status == TeamMemberStatus.pending
                ? 'This will remove pending email access for ${row.nameOrEmail}.'
                : 'This will immediately remove access for ${row.nameOrEmail}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _removeMember(TeamMemberRecord row) {
    final TeamAccessStateController controller =
        context.read<TeamAccessStateController>();

    if (row.isPrimaryOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primary admin cannot be removed.')),
      );
      return;
    }

    _confirmRemoveMember(row).then((bool shouldRemove) {
      if (!mounted || !shouldRemove) {
        return;
      }

      controller.removeMember(row).then((bool ok) {
        if (!mounted || ok) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to remove member.')),
        );
      });
    });
  }

  void _resendPendingAccess(TeamMemberRecord row) {
    if (row.status != TeamMemberStatus.pending) {
      return;
    }

    final TeamAccessStateController controller =
        context.read<TeamAccessStateController>();
    controller.resendPendingAccess(row).then((bool ok) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Pending access renewed for ${row.nameOrEmail}.'
                : 'Unable to renew pending access right now.',
          ),
        ),
      );
    });
  }

  Future<void> _exportTeam(ExportFormat format) async {
    final List<TeamMemberRecord> rows =
        context.read<TeamAccessStateController>().rows;

    final List<List<String>> exportRows = rows.map((row) {
      return <String>[
        row.nameOrEmail,
        row.role == TeamRole.admin ? 'Admin' : 'Staff',
        row.status == TeamMemberStatus.active ? 'Active' : 'Pending',
      ];
    }).toList();

    final bool ok = await exportTabularData(
      baseFileName:
          'team_access_all_active_pending_${DateTime.now().toIso8601String().split('T').first}',
      headers: const <String>['Name/Email', 'Role', 'Status'],
      rows: exportRows,
      format: format,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${format.label} export downloaded (scope: active + pending).'
              : '${format.label} export is available on web builds.',
        ),
      ),
    );
  }
}

class _TeamSection extends StatelessWidget {
  const _TeamSection({
    required this.title,
    required this.count,
    required this.child,
  });

  final String title;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Text(
              '$title ($count)',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _InviteActionBar extends StatelessWidget {
  const _InviteActionBar({
    required this.emailController,
    required this.selectedRole,
    required this.isLoading,
    required this.onRoleChanged,
    required this.onSendInvite,
    required this.onExport,
  });

  final TextEditingController emailController;
  final TeamRole selectedRole;
  final bool isLoading;
  final ValueChanged<TeamRole> onRoleChanged;
  final VoidCallback onSendInvite;
  final ValueChanged<ExportFormat> onExport;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 880) {
          return Column(
            children: [
              _emailInput(),
              const SizedBox(height: 8),
              _roleDropdown(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: _sendButton(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: _exportButton(),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 3, child: _emailInput()),
            const SizedBox(width: 8),
            SizedBox(width: 190, child: _roleDropdown()),
            const SizedBox(width: 8),
            SizedBox(width: 140, child: _sendButton()),
            const SizedBox(width: 8),
            _exportButton(),
          ],
        );
      },
    );
  }

  Widget _emailInput() {
    return SizedBox(
      height: 44,
      child: FocusTraversalOrder(
        order: const NumericFocusOrder(1),
        child: Semantics(
          textField: true,
          label: 'Team member email address',
          hint: 'Enter an email to add pending team access',
          child: TextField(
            controller: emailController,
            decoration: inputDecoration('Email Address'),
          ),
        ),
      ),
    );
  }

  Widget _roleDropdown() {
    return SizedBox(
      height: 44,
      child: FocusTraversalOrder(
        order: const NumericFocusOrder(2),
        child: Semantics(
          label: 'Access role',
          hint: 'Choose admin or staff access level',
          child: DropdownButtonFormField<TeamRole>(
            initialValue: selectedRole,
            decoration: inputDecoration('Role'),
            items: TeamRole.values
                .map(
                  (TeamRole role) => DropdownMenuItem<TeamRole>(
                    value: role,
                    child: Text(
                      role == TeamRole.admin ? 'Admin' : 'Staff',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (TeamRole? role) {
              if (role != null) {
                onRoleChanged(role);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _sendButton() {
    return SizedBox(
      height: 44,
      child: FocusTraversalOrder(
        order: const NumericFocusOrder(3),
        child: Semantics(
          button: true,
          label: 'Add access',
          hint: 'Saves pending email access for the selected role',
          child: ElevatedButton(
            style: blackButtonStyle(),
            onPressed: isLoading ? null : onSendInvite,
            child: Text(
              'Add Access',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _exportButton() {
    return FocusTraversalOrder(
      order: const NumericFocusOrder(4),
      child: Semantics(
        button: true,
        label: 'Export team access list',
        hint: 'Exports active and pending access records',
        child: PopupMenuButton<ExportFormat>(
          tooltip: 'Export',
          onSelected: onExport,
          itemBuilder: (BuildContext context) => ExportFormat.values
              .map(
                (ExportFormat format) => PopupMenuItem<ExportFormat>(
                  value: format,
                  child: Text('Export ${format.label}'),
                ),
              )
              .toList(),
          child: SizedBox(
            height: 44,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: kRadiusSmall,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.download_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Export',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamAccessTable extends StatelessWidget {
  const _TeamAccessTable({
    required this.rows,
    required this.onRemove,
    required this.onResend,
  });

  final List<TeamMemberRecord> rows;
  final ValueChanged<TeamMemberRecord> onRemove;
  final ValueChanged<TeamMemberRecord> onResend;

  bool _isExpired(TeamMemberRecord row) {
    final DateTime? expiry = row.pendingExpiresAt;
    return row.status == TeamMemberStatus.pending &&
        expiry != null &&
        expiry.isBefore(DateTime.now());
  }

  String _lifecycleText(TeamMemberRecord row) {
    if (_isExpired(row)) {
      final DateTime expiry = row.pendingExpiresAt!;
      return 'Expired ${expiry.toLocal().toIso8601String().split('T').first}';
    }
    final String expires = row.pendingExpiresAt == null
        ? 'Expiry unavailable'
        : 'Expires ${row.pendingExpiresAt!.toLocal().toIso8601String().split('T').first}';
    final String sent = row.pendingLastSentAt == null
        ? 'Last sent unavailable'
        : 'Last sent ${row.pendingLastSentAt!.toLocal().toIso8601String().split('T').first}';
    return '$sent • $expires';
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Text(
          'No records yet.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: rows
                .map(
                  (TeamMemberRecord row) => Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: _TeamMemberCard(
                      row: row,
                      onRemove: onRemove,
                      onResend: onResend,
                    ),
                  ),
                )
                .toList(),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 760),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.offWhite),
              headingTextStyle: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              dataTextStyle: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              border: const TableBorder(
                top: BorderSide(color: AppColors.border, width: 1),
                bottom: BorderSide(color: AppColors.border, width: 1),
                left: BorderSide.none,
                right: BorderSide.none,
                horizontalInside: BorderSide(color: AppColors.border, width: 1),
                verticalInside: BorderSide.none,
              ),
              columns: const [
                DataColumn(label: Text('Name / Email')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Lifecycle')),
                DataColumn(label: Text('Actions')),
              ],
              rows: rows.map((TeamMemberRecord row) {
                final bool showRemove = !row.isPrimaryOwner;
                final bool showResend = row.status == TeamMemberStatus.pending;
                final bool expired = _isExpired(row);
                return DataRow(
                  color: WidgetStateProperty.all(AppColors.white),
                  cells: [
                    DataCell(Text(row.nameOrEmail)),
                    DataCell(_RoleBadge(role: row.role)),
                    DataCell(_StatusBadge(status: row.status, expired: expired)),
                    DataCell(
                      Text(
                        row.status == TeamMemberStatus.pending
                            ? _lifecycleText(row)
                            : 'Not applicable',
                      ),
                    ),
                    DataCell(
                      Wrap(
                        spacing: 4,
                        children: [
                          if (showResend)
                            Semantics(
                              button: true,
                              label:
                                  '${expired ? 'Renew' : 'Resend'} pending access for ${row.nameOrEmail}',
                              child: TextButton(
                                onPressed: () => onResend(row),
                                child: Text(expired ? 'Renew' : 'Resend'),
                              ),
                            ),
                          if (showRemove)
                            Semantics(
                              button: true,
                              label: row.status == TeamMemberStatus.pending
                                  ? 'Remove pending access for ${row.nameOrEmail}'
                                  : 'Remove team member ${row.nameOrEmail}',
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                splashRadius: 18,
                                tooltip: row.status == TeamMemberStatus.pending
                                    ? 'Remove pending access'
                                    : 'Remove member',
                                onPressed: () => onRemove(row),
                                icon: const Icon(Icons.close, size: 18),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  const _TeamMemberCard({
    required this.row,
    required this.onRemove,
    required this.onResend,
  });

  final TeamMemberRecord row;
  final ValueChanged<TeamMemberRecord> onRemove;
  final ValueChanged<TeamMemberRecord> onResend;

  bool _isExpired(TeamMemberRecord row) {
    final DateTime? expiry = row.pendingExpiresAt;
    return row.status == TeamMemberStatus.pending &&
        expiry != null &&
        expiry.isBefore(DateTime.now());
  }

  String _lifecycleText(TeamMemberRecord row) {
    if (_isExpired(row)) {
      final DateTime expiry = row.pendingExpiresAt!;
      return 'Expired ${expiry.toLocal().toIso8601String().split('T').first}';
    }
    final String expires = row.pendingExpiresAt == null
        ? 'Expiry unavailable'
        : 'Expires ${row.pendingExpiresAt!.toLocal().toIso8601String().split('T').first}';
    final String sent = row.pendingLastSentAt == null
        ? 'Last sent unavailable'
        : 'Last sent ${row.pendingLastSentAt!.toLocal().toIso8601String().split('T').first}';
    return '$sent • $expires';
  }

  @override
  Widget build(BuildContext context) {
    final bool showRemove = !row.isPrimaryOwner;
    final bool expired = _isExpired(row);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: kRadiusMedium,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.nameOrEmail,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _RoleBadge(role: row.role),
              _StatusBadge(status: row.status, expired: expired),
            ],
          ),
          if (row.status == TeamMemberStatus.pending) ...[
            const SizedBox(height: 8),
            Text(
              _lifecycleText(row),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (showRemove) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (row.status == TeamMemberStatus.pending)
                  Expanded(
                    child: Semantics(
                      button: true,
                      label:
                          '${expired ? 'Renew' : 'Resend'} pending access for ${row.nameOrEmail}',
                      child: OutlinedButton.icon(
                        onPressed: () => onResend(row),
                        icon: const Icon(Icons.refresh),
                        label: Text(expired ? 'Renew' : 'Resend'),
                      ),
                    ),
                  ),
                if (row.status == TeamMemberStatus.pending)
                  const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: row.status == TeamMemberStatus.pending
                        ? 'Remove pending access for ${row.nameOrEmail}'
                        : 'Remove team member ${row.nameOrEmail}',
                    child: OutlinedButton.icon(
                      onPressed: () => onRemove(row),
                      icon: const Icon(Icons.close),
                      label: Text(
                        row.status == TeamMemberStatus.pending
                            ? 'Remove Pending Access'
                            : 'Remove Member',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final TeamRole role;

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = role == TeamRole.admin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? AppColors.black : AppColors.offWhite,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        border: Border.all(
          color: isAdmin ? AppColors.black : AppColors.border,
          width: 1,
        ),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'Staff',
        style: GoogleFonts.inter(
          color: isAdmin ? AppColors.white : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, this.expired = false});

  final TeamMemberStatus status;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final bool active = status == TeamMemberStatus.active;
    final String text = active ? 'Active' : (expired ? 'Expired' : 'Pending');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        border: Border.all(
          color: active
              ? AppColors.black
              : (expired ? AppColors.rtoText : AppColors.border),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: active
              ? AppColors.textPrimary
              : (expired ? AppColors.rtoText : AppColors.textSecondary),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
