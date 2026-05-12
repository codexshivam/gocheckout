class StoreFinancials {
  const StoreFinancials({
    required this.totalRevenue,
    required this.totalCollected,
    required this.pendingBalance,
  });

  final num totalRevenue;
  final num totalCollected;
  final num pendingBalance;

  Map<String, dynamic> toMap() => {
    'totalRevenue': totalRevenue,
    'totalCollected': totalCollected,
    'pendingBalance': pendingBalance,
  };

  factory StoreFinancials.fromMap(Map<String, dynamic> map) {
    return StoreFinancials(
      totalRevenue: map['totalRevenue'] as num? ?? 0,
      totalCollected: map['totalCollected'] as num? ?? 0,
      pendingBalance: map['pendingBalance'] as num? ?? 0,
    );
  }
}

class StoreOrderMetrics {
  const StoreOrderMetrics({
    required this.totalOrders,
    required this.deliveredCount,
    required this.rtoCount,
    required this.pendingCount,
  });

  final int totalOrders;
  final int deliveredCount;
  final int rtoCount;
  final int pendingCount;

  Map<String, dynamic> toMap() => {
    'totalOrders': totalOrders,
    'deliveredCount': deliveredCount,
    'rtoCount': rtoCount,
    'pendingCount': pendingCount,
  };

  factory StoreOrderMetrics.fromMap(Map<String, dynamic> map) {
    return StoreOrderMetrics(
      totalOrders: map['totalOrders'] as int? ?? 0,
      deliveredCount: map['deliveredCount'] as int? ?? 0,
      rtoCount: map['rtoCount'] as int? ?? 0,
      pendingCount: map['pendingCount'] as int? ?? 0,
    );
  }
}

class StoreRtoAnalytics {
  const StoreRtoAnalytics({
    required this.overallRate,
    required this.lossEstimated,
    required this.byDistrict,
  });

  final num overallRate;
  final num lossEstimated;
  final Map<String, int> byDistrict;

  Map<String, dynamic> toMap() => {
    'overallRate': overallRate,
    'lossEstimated': lossEstimated,
    'byDistrict': byDistrict,
  };

  factory StoreRtoAnalytics.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> districtRaw =
        (map['byDistrict'] as Map<dynamic, dynamic>? ?? const <dynamic, dynamic>{})
            .map((key, value) => MapEntry(key.toString(), value));

    return StoreRtoAnalytics(
      overallRate: map['overallRate'] as num? ?? 0,
      lossEstimated: map['lossEstimated'] as num? ?? 0,
      byDistrict: districtRaw.map(
        (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
      ),
    );
  }
}

class StoreMonthlyHistoryItem {
  const StoreMonthlyHistoryItem({
    required this.month,
    required this.revenue,
    required this.orders,
    required this.rto,
  });

  final String month;
  final num revenue;
  final int orders;
  final int rto;

  Map<String, dynamic> toMap() => {
    'month': month,
    'revenue': revenue,
    'orders': orders,
    'rto': rto,
  };

  factory StoreMonthlyHistoryItem.fromMap(Map<String, dynamic> map) {
    return StoreMonthlyHistoryItem(
      month: map['month'] as String? ?? '',
      revenue: map['revenue'] as num? ?? 0,
      orders: map['orders'] as int? ?? 0,
      rto: map['rto'] as int? ?? 0,
    );
  }
}

class StoreStatsDocument {
  const StoreStatsDocument({
    required this.storeId,
    required this.financials,
    required this.orderMetrics,
    required this.rtoAnalytics,
    required this.monthlyHistory,
  });

  final String storeId;
  final StoreFinancials financials;
  final StoreOrderMetrics orderMetrics;
  final StoreRtoAnalytics rtoAnalytics;
  final List<StoreMonthlyHistoryItem> monthlyHistory;

  Map<String, dynamic> toMap() => {
    'financials': financials.toMap(),
    'orderMetrics': orderMetrics.toMap(),
    'rtoAnalytics': rtoAnalytics.toMap(),
    'monthlyHistory': monthlyHistory.map((item) => item.toMap()).toList(),
  };

  factory StoreStatsDocument.fromMap(String storeId, Map<String, dynamic> map) {
    final List<StoreMonthlyHistoryItem> parsedHistory =
        ((map['monthlyHistory'] as List<dynamic>?) ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(StoreMonthlyHistoryItem.fromMap)
            .toList();

    return StoreStatsDocument(
      storeId: storeId,
      financials: StoreFinancials.fromMap(
        (map['financials'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
      orderMetrics: StoreOrderMetrics.fromMap(
        (map['orderMetrics'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
      rtoAnalytics: StoreRtoAnalytics.fromMap(
        (map['rtoAnalytics'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      ),
      monthlyHistory: parsedHistory,
    );
  }
}
