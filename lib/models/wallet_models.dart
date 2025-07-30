// Wallet-related data models for Flutter app.

class WalletEligibleItem {
  final String id;
  final String title;
  final String subtitle;
  final String itemType;
  
  // Receipt-specific fields
  final String? receiptId;
  final String? merchantName;
  final double? totalAmount;
  final String? currency;
  final DateTime? transactionDate;
  final int? itemCount;
  
  // Warranty-specific fields
  final String? productName;
  final String? brand;
  final String? warrantyPeriod;
  final DateTime? expiryDate;
  final DateTime? purchaseDate;
  
  // Status tracking
  final bool addedToWallet;
  final String? walletPassId;
  final DateTime createdAt;

  WalletEligibleItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.itemType,
    this.receiptId,
    this.merchantName,
    this.totalAmount,
    this.currency,
    this.transactionDate,
    this.itemCount,
    this.productName,
    this.brand,
    this.warrantyPeriod,
    this.expiryDate,
    this.purchaseDate,
    this.addedToWallet = false,
    this.walletPassId,
    required this.createdAt,
  });

  factory WalletEligibleItem.fromJson(Map<String, dynamic> json) {
    return WalletEligibleItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      itemType: json['item_type'] ?? '',
      receiptId: json['receipt_id'],
      merchantName: json['merchant_name'],
      totalAmount: json['total_amount']?.toDouble(),
      currency: json['currency'],
      transactionDate: json['transaction_date'] != null 
          ? DateTime.tryParse(json['transaction_date']) 
          : null,
      itemCount: json['item_count'],
      productName: json['product_name'],
      brand: json['brand'],
      warrantyPeriod: json['warranty_period'],
      expiryDate: json['expiry_date'] != null 
          ? DateTime.tryParse(json['expiry_date']) 
          : null,
      purchaseDate: json['purchase_date'] != null 
          ? DateTime.tryParse(json['purchase_date']) 
          : null,
      addedToWallet: json['added_to_wallet'] ?? false,
      walletPassId: json['wallet_pass_id'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'item_type': itemType,
      'receipt_id': receiptId,
      'merchant_name': merchantName,
      'total_amount': totalAmount,
      'currency': currency,
      'transaction_date': transactionDate?.toIso8601String(),
      'item_count': itemCount,
      'product_name': productName,
      'brand': brand,
      'warranty_period': warrantyPeriod,
      'expiry_date': expiryDate?.toIso8601String(),
      'purchase_date': purchaseDate?.toIso8601String(),
      'added_to_wallet': addedToWallet,
      'wallet_pass_id': walletPassId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isReceipt => itemType == 'receipt';
  bool get isWarranty => itemType == 'warranty';
  
  String get displayIcon {
    if (isReceipt) return '🧾';
    if (isWarranty) return '🛡️';
    return '📄';
  }
  
  String get formattedAmount {
    if (totalAmount != null && currency != null) {
      return '$currency ${totalAmount!.toStringAsFixed(2)}';
    }
    return '';
  }
  
  String get formattedDate {
    if (transactionDate != null) {
      return '${transactionDate!.day}/${transactionDate!.month}/${transactionDate!.year}';
    }
    if (expiryDate != null) {
      return 'Expires: ${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}';
    }
    return '';
  }
}

class WalletItemsResponse {
  final bool success;
  final List<WalletEligibleItem> items;
  final int totalReceipts;
  final int totalWarranties;
  final String? error;

  WalletItemsResponse({
    required this.success,
    required this.items,
    required this.totalReceipts,
    required this.totalWarranties,
    this.error,
  });

  factory WalletItemsResponse.fromJson(Map<String, dynamic> json) {
    return WalletItemsResponse(
      success: json['success'] ?? false,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => WalletEligibleItem.fromJson(item))
          .toList() ?? [],
      totalReceipts: json['total_receipts'] ?? 0,
      totalWarranties: json['total_warranties'] ?? 0,
      error: json['error'],
    );
  }
}

class PassGenerationRequest {
  final String itemId;
  final String passType;
  final String userId;

  PassGenerationRequest({
    required this.itemId,
    required this.passType,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'pass_type': passType,
      'user_id': userId,
    };
  }
}

class PassGenerationResponse {
  final bool success;
  final String? jwt;
  final String? passId;
  final String? walletUrl;
  final String? error;

  PassGenerationResponse({
    required this.success,
    this.jwt,
    this.passId,
    this.walletUrl,
    this.error,
  });

  factory PassGenerationResponse.fromJson(Map<String, dynamic> json) {
    return PassGenerationResponse(
      success: json['success'] ?? false,
      jwt: json['jwt'],
      passId: json['pass_id'],
      walletUrl: json['wallet_url'],
      error: json['error'],
    );
  }
}
