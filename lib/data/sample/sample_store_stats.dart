const Map<String, dynamic> sampleStoreStats = <String, dynamic>{
  'financials': <String, dynamic>{
    'totalRevenue': 620000,
    'totalCollected': 548500,
    'pendingBalance': 71500,
  },
  'orderMetrics': <String, dynamic>{
    'totalOrders': 1680,
    'deliveredCount': 1324,
    'rtoCount': 212,
    'pendingCount': 144,
  },
  'rtoAnalytics': <String, dynamic>{
    'overallRate': 12.6,
    'lossEstimated': 67840,
    'byDistrict': <String, int>{
      'Kathmandu': 62,
      'Pokhara': 33,
      'Lalitpur': 24,
      'Bhaktapur': 19,
      'Biratnagar': 16,
    },
  },
  'monthlyHistory': <Map<String, dynamic>>[
    <String, dynamic>{'month': '2025-10', 'revenue': 84000, 'orders': 210, 'rto': 26},
    <String, dynamic>{'month': '2025-11', 'revenue': 92000, 'orders': 246, 'rto': 31},
    <String, dynamic>{'month': '2025-12', 'revenue': 98000, 'orders': 258, 'rto': 35},
    <String, dynamic>{'month': '2026-01', 'revenue': 101000, 'orders': 274, 'rto': 38},
    <String, dynamic>{'month': '2026-02', 'revenue': 115000, 'orders': 322, 'rto': 39},
    <String, dynamic>{'month': '2026-03', 'revenue': 130000, 'orders': 370, 'rto': 43},
  ],
};
