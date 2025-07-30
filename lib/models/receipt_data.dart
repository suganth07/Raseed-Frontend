class ReceiptLocation {
  final String city;
  final String state;
  final String country;

  ReceiptLocation({
    required this.city,
    required this.state,
    required this.country,
  });

  factory ReceiptLocation.fromJson(Map<String, dynamic> json) {
    return ReceiptLocation(
      city: json['city'] ?? 'Unknown',
      state: json['state'] ?? 'Unknown',
      country: json['country'] ?? 'USA',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'state': state,
      'country': country,
    };
  }
}

class ReceiptData {
  final String receiptId;
  final String businessCategory;
  final double totalAmount;
  final String currency;
  final int nodeCount;
  final int edgeCount;
  final int itemCount;
  final int warrantyCount;
  final int brandCount;
  final int categoryCount;
  final String merchantName;
  final ReceiptLocation location;
  final String shoppingPattern;
  final bool hasWarranties;
  final String? latestExpiryDate;
  final bool hasExpiringSoon;
  final int expiringSoonCount;
  final List<String> expiringSoonLabels;
  final List<String> alerts;
  final String createdAt;
  final int processingDurationMs;
  final String version;

  ReceiptData({
    required this.receiptId,
    required this.businessCategory,
    required this.totalAmount,
    required this.currency,
    required this.nodeCount,
    required this.edgeCount,
    required this.itemCount,
    required this.warrantyCount,
    required this.brandCount,
    required this.categoryCount,
    required this.merchantName,
    required this.location,
    required this.shoppingPattern,
    required this.hasWarranties,
    this.latestExpiryDate,
    required this.hasExpiringSoon,
    required this.expiringSoonCount,
    required this.expiringSoonLabels,
    required this.alerts,
    required this.createdAt,
    required this.processingDurationMs,
    required this.version,
  });

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      receiptId: json['receipt_id'] ?? '',
      businessCategory: json['business_category'] ?? 'Unknown',
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      nodeCount: json['node_count'] ?? 0,
      edgeCount: json['edge_count'] ?? 0,
      itemCount: json['item_count'] ?? 0,
      warrantyCount: json['warranty_count'] ?? 0,
      brandCount: json['brand_count'] ?? 0,
      categoryCount: json['category_count'] ?? 0,
      merchantName: json['merchant_name'] ?? 'Unknown Merchant',
      location: ReceiptLocation.fromJson(json['location'] ?? {}),
      shoppingPattern: json['shopping_pattern'] ?? 'unknown',
      hasWarranties: json['has_warranties'] ?? false,
      latestExpiryDate: json['latest_expiry_date'],
      hasExpiringSoon: json['has_expiring_soon'] ?? false,
      expiringSoonCount: json['expiring_soon_count'] ?? 0,
      expiringSoonLabels: List<String>.from(json['expiring_soon_labels'] ?? []),
      alerts: List<String>.from(json['alerts'] ?? []),
      createdAt: json['created_at'] ?? '',
      processingDurationMs: json['processing_duration_ms'] ?? 0,
      version: json['version'] ?? '1.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receipt_id': receiptId,
      'business_category': businessCategory,
      'total_amount': totalAmount,
      'currency': currency,
      'node_count': nodeCount,
      'edge_count': edgeCount,
      'item_count': itemCount,
      'warranty_count': warrantyCount,
      'brand_count': brandCount,
      'category_count': categoryCount,
      'merchant_name': merchantName,
      'location': location.toJson(),
      'shopping_pattern': shoppingPattern,
      'has_warranties': hasWarranties,
      'latest_expiry_date': latestExpiryDate,
      'has_expiring_soon': hasExpiringSoon,
      'expiring_soon_count': expiringSoonCount,
      'expiring_soon_labels': expiringSoonLabels,
      'alerts': alerts,
      'created_at': createdAt,
      'processing_duration_ms': processingDurationMs,
      'version': version,
    };
  }

  // Helper getters for UI display
  String get formattedTotal => '$currency ${totalAmount.toStringAsFixed(2)}';
  
  String get processingTime => '${(processingDurationMs / 1000).toStringAsFixed(1)}s';
  
  bool get hasAlerts => alerts.isNotEmpty;
  
  String get alertSummary => hasAlerts ? '${alerts.length} alert${alerts.length > 1 ? 's' : ''}' : 'No alerts';
  
  String get itemSummary => '$itemCount item${itemCount != 1 ? 's' : ''}';
  
  String get warrantySummary => hasWarranties ? '$warrantyCount warranty item${warrantyCount != 1 ? 's' : ''}' : 'No warranties';
}
