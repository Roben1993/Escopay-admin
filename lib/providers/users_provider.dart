import 'package:flutter/foundation.dart';
import '../models/admin_user_model.dart';
import '../services/admin_firestore_service.dart';

class UsersProvider extends ChangeNotifier {
  final AdminFirestoreService _service = AdminFirestoreService();

  bool _isLoading = false;
  String? _error;
  List<AdminUserModel> _users = [];
  String _kycFilter = 'all';

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AdminUserModel> get users => _users;
  String get kycFilter => _kycFilter;

  Future<void> loadUsers({String? kycStatus}) async {
    _isLoading = true;
    _error = null;
    if (kycStatus != null) _kycFilter = kycStatus;
    notifyListeners();
    try {
      _users = await _service.getUsers(
        kycStatusFilter: _kycFilter == 'all' ? null : _kycFilter,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateKycStatus(String uid, String status) async {
    await _service.updateKycStatus(uid, status);
    final idx = _users.indexWhere((u) => u.uid == uid);
    if (idx != -1) {
      _users[idx] = AdminUserModel(
        uid: _users[idx].uid,
        email: _users[idx].email,
        displayName: _users[idx].displayName,
        walletAddress: _users[idx].walletAddress,
        kycStatus: status,
        merchantStatus: _users[idx].merchantStatus,
        createdAt: _users[idx].createdAt,
        lastLoginAt: _users[idx].lastLoginAt,
        firestoreDocId: _users[idx].firestoreDocId,
      );
      notifyListeners();
    }
  }
}
