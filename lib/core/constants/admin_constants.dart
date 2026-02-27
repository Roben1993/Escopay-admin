class AdminConstants {
  AdminConstants._();

  static const List<String> adminEmails = [
    'admin@escopay.com',
  ];

  // Firestore collections (same as main app)
  static const String usersCollection = 'users';
  static const String escrowsCollection = 'escrows';
  static const String p2pAdsCollection = 'p2p_ads';
  static const String p2pOrdersCollection = 'p2p_orders';
  static const String p2pDisputesCollection = 'p2p_disputes';
  static const String merchantsCollection = 'merchants';
  static const String countersCollection = 'counters';

  // Storage bucket
  static const String storageBucket = 'escopay-storage';

  // Pagination
  static const int pageSize = 25;
}
