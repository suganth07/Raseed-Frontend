import 'package:flutter/material.dart';
import '../models/wallet_models.dart';

class WalletItemCard extends StatelessWidget {
  final WalletEligibleItem item;
  final VoidCallback onAddToWallet;
  final bool isLoading;

  const WalletItemCard({
    super.key,
    required this.item,
    required this.onAddToWallet,
    this.isLoading = false,
  });

  static const Color googleBlue = Color(0xFF1976D2);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              item.isReceipt
                  ? googleBlue.withOpacity(0.10)
                  : const Color(0xFFFF6B35).withOpacity(0.10),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Text(
                    item.displayIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  if (item.addedToWallet)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: const Text(
                        'Added',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Details Row
              if (item.isReceipt && item.formattedAmount.isNotEmpty)
                _buildDetailRow('Amount', item.formattedAmount),

              if (item.isReceipt && item.itemCount != null)
                _buildDetailRow('Items', '${item.itemCount} items'),

              if (item.isWarranty && item.brand != null)
                _buildDetailRow('Brand', item.brand!),

              if (item.isWarranty && item.warrantyPeriod != null)
                _buildDetailRow('Warranty', item.warrantyPeriod!),

              if (item.formattedDate.isNotEmpty)
                _buildDetailRow(
                  item.isReceipt ? 'Date' : 'Expiry',
                  item.formattedDate,
                ),

              const SizedBox(height: 16),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: item.addedToWallet || isLoading ? null : onAddToWallet,
                  icon: isLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : item.addedToWallet
                      ? const Icon(Icons.check, color: Colors.white)
                      : const Icon(Icons.account_balance_wallet, color: Colors.white),
                  label: Text(
                    isLoading
                        ? 'Adding to Wallet...'
                        : item.addedToWallet
                        ? 'Added to Wallet'
                        : 'Add to Wallet',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.addedToWallet
                        ? Colors.green
                        : item.isReceipt
                        ? googleBlue
                        : const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF2D3748),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
