enum TeamRole { admin, staff }

enum TeamMemberStatus { active, pending }

class TeamMemberRecord {
  const TeamMemberRecord({
    required this.id,
    required this.nameOrEmail,
    required this.role,
    required this.status,
    required this.isPrimaryOwner,
    this.pendingExpiresAt,
    this.pendingLastSentAt,
  });

  final String id;
  final String nameOrEmail;
  final TeamRole role;
  final TeamMemberStatus status;
  final bool isPrimaryOwner;
  final DateTime? pendingExpiresAt;
  final DateTime? pendingLastSentAt;
}
