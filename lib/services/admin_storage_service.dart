import 'package:firebase_storage/firebase_storage.dart';
import '../core/constants/admin_constants.dart';

class AdminStorageService {
  static final AdminStorageService _instance = AdminStorageService._internal();
  factory AdminStorageService() => _instance;
  AdminStorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: AdminConstants.storageBucket,
  );

  Future<String> getDownloadUrl(String path) async {
    final ref = _storage.ref().child(path);
    return await ref.getDownloadURL();
  }

  Future<List<String>> listFolderUrls(String folderPath) async {
    try {
      final result = await _storage.ref().child(folderPath).listAll();
      final urls = await Future.wait(
        result.items.map((ref) => ref.getDownloadURL()),
      );
      return urls;
    } catch (_) {
      return [];
    }
  }
}
