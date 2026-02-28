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
      final u = _users[idx];
      _users[idx] = AdminUserModel(
        uid: u.uid,
        email: u.email,
        displayName: u.displayName,
        walletAddress: u.walletAddress,
        kycStatus: status,
        merchantStatus: u.merchantStatus,
        createdAt: u.createdAt,
        lastLoginAt: u.lastLoginAt,
        firestoreDocId: u.firestoreDocId,
        kycFullName: u.kycFullName,
        kycDocType: u.kycDocType,
        kycDocNumber: u.kycDocNumber,
        kycPhone: u.kycPhone,
        kycFrontUrl: u.kycFrontUrl,
        kycBackUrl: u.kycBackUrl,
        kycSelfieUrl: u.kycSelfieUrl,
        kycSubmittedAt: u.kycSubmittedAt,
      );
      notifyListeners();
    }
  }
}
