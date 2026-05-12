import 'package:flutter/foundation.dart';

import '../../data/models/schema/team_access_models.dart';
import '../../data/services/team_access_service.dart';

class TeamAccessStateController extends ChangeNotifier {
  TeamAccessStateController({
    required this.storeId,
    TeamAccessService? service,
  }) : _service = service ?? TeamAccessService();

  final String storeId;
  final TeamAccessService _service;

  List<TeamMemberRecord> _rows = <TeamMemberRecord>[];
  TeamRole _selectedRole = TeamRole.staff;
  bool _isLoading = false;
  String? _errorMessage;

  List<TeamMemberRecord> get rows => _rows;
  TeamRole get selectedRole => _selectedRole;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void updateSelectedRole(TeamRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rows = await _service.listTeamMembers(storeId);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendInvite(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.sendInvite(storeId: storeId, email: email, role: _selectedRole);
      _rows = await _service.listTeamMembers(storeId);
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeMember(TeamMemberRecord record) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.removeMember(storeId: storeId, record: record);
      _rows = await _service.listTeamMembers(storeId);
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resendPendingAccess(TeamMemberRecord record) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.resendPendingAccess(record: record);
      _rows = await _service.listTeamMembers(storeId);
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
