import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api_services.dart';
import '../services/auth_service.dart';
import '../models/receipt_data.dart';
import '../utils/profile_refresh.dart';

class IngestionScreen extends StatefulWidget {
  final String userId;

  const IngestionScreen({required this.userId, Key? key}) : super(key: key);

  @override
  _IngestionScreenState createState() => _IngestionScreenState();
}

class _IngestionScreenState extends State<IngestionScreen> {
  dynamic _image; // Can be File (mobile) or Uint8List (web)
  bool _isProcessing = false;
  bool _isUploaded = false;
  bool _buildGraph = true; // Default to true for new format
  ReceiptData? _receiptData; // Store parsed receipt data
  Map<String, dynamic>? _extractedContent; // Stores extraction
  Map<String, dynamic>? _fullResponse; // Store full backend response for display

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? selected = await picker.pickImage(
        source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (selected != null) {
        _showToast("Image selected successfully!");
        if (kIsWeb) {
          final bytes = await selected.readAsBytes();
          setState(() {
            _image = bytes;
            _isUploaded = false;
            _extractedContent = null;
            _fullResponse = null;
          });
        } else {
          setState(() {
            _image = File(selected.path);
            _isUploaded = false;
            _extractedContent = null;
            _fullResponse = null;
          });
        }
      } else {
        Fluttertoast.showToast(
          msg: "No image selected",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: const Color(0xFF1976D2),
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error selecting image: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color(0xFFD32F2F),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? selected = await picker.pickImage(source: ImageSource.gallery);

    if (selected != null) {
      if (kIsWeb) {
        final bytes = await selected.readAsBytes();
        setState(() {
          _image = bytes;
          _isUploaded = false;
          _extractedContent = null;
          _fullResponse = null;
        });
      } else {
        setState(() {
          _image = File(selected.path);
          _isUploaded = false;
          _extractedContent = null;
          _fullResponse = null;
        });
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) {
      _showToast("Please select an image first");
      return;
    }

    setState(() {
      _isProcessing = true;
      _receiptData = null;
    });

    try {
      _showToast("Processing receipt...");

      if (_buildGraph) {
        // Use only the image argument as required
        var rawResponse = await ApiService.uploadReceiptWithGraph(_image!);
        _receiptData = ReceiptData.fromJson(rawResponse);
        _showToast("Knowledge graph built successfully!");

        if (_receiptData != null && AuthService.isLoggedIn) {
          _showToast("Saving to your knowledge graph...");

          Map<String, dynamic> receiptData = {
            'receipt_id': _receiptData!.receiptId,
            'merchant_name': _receiptData!.merchantName,
            'total_amount': _receiptData!.totalAmount,
            'formatted_total': _receiptData!.formattedTotal,
            'currency': _receiptData!.currency,
            'business_category': _receiptData!.businessCategory,
            'location': _receiptData!.location.toJson(),
            'processing_time': _receiptData!.processingTime,
            'created_at': _receiptData!.createdAt,
            'version': _receiptData!.version,
            'item_count': _receiptData!.itemCount,
            'warranty_count': _receiptData!.warrantyCount,
            'brand_count': _receiptData!.brandCount,
            'category_count': _receiptData!.categoryCount,
            'shopping_pattern': _receiptData!.shoppingPattern,
            'has_warranties': _receiptData!.hasWarranties,
            'latest_expiry_date': _receiptData!.latestExpiryDate,
            'has_expiring_soon': _receiptData!.hasExpiringSoon,
            'expiring_soon_count': _receiptData!.expiringSoonCount,
            'expiring_soon_labels': _receiptData!.expiringSoonLabels,
            'alerts': _receiptData!.alerts,
          };

          Map<String, dynamic> knowledgeGraphData = {
            'node_count': _receiptData!.nodeCount,
            'edge_count': _receiptData!.edgeCount,
            'processing_duration_ms': _receiptData!.processingDurationMs,
            'graph_built': true,
            'receipt_summary': _receiptData!.itemSummary,
            'merchant_info': {
              'name': _receiptData!.merchantName,
              'category': _receiptData!.businessCategory,
              'location': _receiptData!.location.toJson(),
            },
            'analytics': {
              'total_amount': _receiptData!.totalAmount,
              'item_count': _receiptData!.itemCount,
              'warranty_count': _receiptData!.warrantyCount,
              'brand_count': _receiptData!.brandCount,
              'has_warranties': _receiptData!.hasWarranties,
              'shopping_pattern': _receiptData!.shoppingPattern,
            },
            'items': rawResponse['items'] ?? [],
          };

          var result = await AuthService.storeReceiptKnowledgeGraph(
            receiptName: _receiptData!.merchantName + ' - ' + _receiptData!.formattedTotal,
            receiptData: receiptData,
            knowledgeGraphData: knowledgeGraphData,
          );

          if (result['success']) {
            _showToast("✅ Saved to your Knowledge Graph!");
            // Refresh profile data to show updated counts and spending
            ProfileRefresh.notifyRefresh();
          } else {
            _showToast("⚠ Failed to save: ${result['message']}");
          }
        } else if (!AuthService.isLoggedIn) {
          _showToast("⚠ Please log in to save to Knowledge Graph");
        }

      } else {
        var response = await ApiService.uploadReceiptWithGraph(_image!);
        setState(() {
          _fullResponse = response;
        });
      }

      setState(() {
        _isProcessing = false;
        _isUploaded = true;
      });

      _showToast("Receipt processed successfully!");
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showToast("Error: ${e.toString()}");
      _showErrorDialog(e.toString());
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Theme.of(context).colorScheme.primary,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Receipt Processed!',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_receiptData != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Receipt ID:', _receiptData!.receiptId),
                        _buildInfoRow('Merchant:', _receiptData!.merchantName),
                        _buildInfoRow('Total Amount:', _receiptData!.formattedTotal),
                        _buildInfoRow('Items:', _receiptData!.itemSummary),
                        _buildInfoRow('Business Type:', _receiptData!.businessCategory),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_tree_rounded,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Knowledge Graph Built!',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('Nodes:', '${_receiptData!.nodeCount}'),
                        _buildInfoRow('Edges:', '${_receiptData!.edgeCount}'),
                        _buildInfoRow('Processing Time:', _receiptData!.processingTime),
                      ],
                    ),
                  ),
                  if (_receiptData!.hasExpiringSoon) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_rounded, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Expiry Alerts',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._receiptData!.alerts.map((alert) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $alert',
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                  if (_receiptData!.hasWarranties) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.security_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Warranties',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('Warranty Items:', _receiptData!.warrantySummary),
                        ],
                      ),
                    ),
                  ],
                ] else if (_fullResponse != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Receipt processed with legacy format',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('Status:', 'Success'),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Receipt processed but no data available',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (_receiptData != null)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDetailedView();
              },
              child: const Text('View Details'),
            ),
        ],
      ),
    );
  }

  void _showDetailedView() {
    if (_receiptData == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Receipt Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailSection('Basic Information', [
                  _buildInfoRow('Receipt ID:', _receiptData!.receiptId),
                  _buildInfoRow('Merchant:', _receiptData!.merchantName),
                  _buildInfoRow('Business Category:', _receiptData!.businessCategory),
                  _buildInfoRow('Total Amount:', _receiptData!.formattedTotal),
                  _buildInfoRow('Currency:', _receiptData!.currency),
                  _buildInfoRow('Shopping Pattern:', _receiptData!.shoppingPattern),
                ]),
                _buildDetailSection('Item Analysis', [
                  _buildInfoRow('Total Items:', '${_receiptData!.itemCount}'),
                  _buildInfoRow('Categories:', '${_receiptData!.categoryCount}'),
                  _buildInfoRow('Brands:', '${_receiptData!.brandCount}'),
                ]),
                _buildDetailSection('Knowledge Graph', [
                  _buildInfoRow('Nodes:', '${_receiptData!.nodeCount}'),
                  _buildInfoRow('Edges:', '${_receiptData!.edgeCount}'),
                  _buildInfoRow('Processing Time:', _receiptData!.processingTime),
                  _buildInfoRow('Version:', _receiptData!.version),
                ]),
                _buildDetailSection('Location', [
                  _buildInfoRow('City:', _receiptData!.location.city),
                  _buildInfoRow('State:', _receiptData!.location.state),
                  _buildInfoRow('Country:', _receiptData!.location.country),
                ]),
                if (_receiptData!.hasExpiringSoon)
                  _buildDetailSection('Expiry Alerts',
                    _receiptData!.alerts.map((alert) =>
                        Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text('• $alert', style: TextStyle(color: Colors.orange[700])),
                        )
                    ).toList(),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 8),
        ...children,
        SizedBox(height: 16),
      ],
    );
  }

  void _showErrorDialog(String error) {
    String userMessage = error;
    if (error.contains('400')) {
      userMessage = 'Invalid image file. Please select a valid receipt image.';
    } else if (error.contains('timeout')) {
      userMessage = 'Request timed out. Please check your connection and try again.';
    } else if (error.contains('Network error')) {
      userMessage = 'Connection failed. Please check your internet connection.';
    } else if (error.contains('SocketException')) {
      userMessage = 'Cannot connect to server. Make sure the backend is running.';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.error_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Processing Error',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userMessage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please try again or contact support if the problem persists.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.document_scanner_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Smart Receipt Processing',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Snap or upload your receipt to extract details and build knowledge graphs',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Image Preview Card
              _buildImagePreviewCard(),

              const SizedBox(height: 24),

              // Action Buttons
              if (_image == null) _buildImageSelectionActions() else _buildProcessingActions(),

              const SizedBox(height: 24),

              // Results Section
              if (_isUploaded && _extractedContent != null) _buildExtractedTextCard(),
              if (_fullResponse != null) _buildDebugSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreviewCard() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: _image == null
          ? _buildEmptyImageState()
          : _buildImageDisplay(),
    );
  }

  Widget _buildEmptyImageState() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_photo_alternate_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to add receipt image',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Supports JPG, PNG formats',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageDisplay() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: kIsWeb
                ? Image.memory(_image!, fit: BoxFit.cover)
                : Image.file(_image!, fit: BoxFit.cover),
          ),
        ),
        if (_isProcessing)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    _buildGraph ? 'Building Knowledge Graph...' : 'Processing Receipt...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: _isProcessing ? null : () {
                setState(() {
                  _image = null;
                  _isUploaded = false;
                  _receiptData = null;
                  _extractedContent = null;
                  _fullResponse = null;
                });
              },
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSelectionActions() {
    return Column(
      children: [
        FilledButton.icon(
          onPressed: _pickImage,
          icon: Icon(kIsWeb ? Icons.upload_rounded : Icons.camera_alt_rounded),
          label: Text(kIsWeb ? 'Upload Image' : 'Take Photo'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        if (!kIsWeb) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Choose from Gallery'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProcessingActions() {
    return Column(
      children: [
        // Knowledge Graph Toggle
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_tree_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Build Knowledge Graph',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Extract entities and relationships using AI',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _buildGraph,
                  onChanged: _isProcessing ? null : (value) {
                    setState(() {
                      _buildGraph = value;
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Process Button
        FilledButton.icon(
          onPressed: _isProcessing ? null : _uploadImage,
          icon: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(_buildGraph ? Icons.auto_graph_rounded : Icons.upload_rounded),
          label: Text(
            _isProcessing
                ? (_buildGraph ? 'Building Graph...' : 'Processing...')
                : (_buildGraph ? 'Extract & Build Graph' : 'Extract Receipt Data'),
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: _isProcessing
                ? Theme.of(context).colorScheme.surfaceVariant
                : (_buildGraph 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.secondary),
            foregroundColor: _isProcessing
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),

        const SizedBox(height: 12),

        // Change Image Button
        OutlinedButton.icon(
          onPressed: _isProcessing ? null : () {
            setState(() {
              _image = null;
              _isUploaded = false;
              _receiptData = null;
              _extractedContent = null;
              _fullResponse = null;
            });
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Change Image'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildExtractedTextCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.text_fields_rounded,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Extracted Text',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stats Row
            Row(
              children: [
                _buildStatChip(
                  'Length: ${_extractedContent!['text_length']} chars',
                  Icons.format_size_rounded,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  'Confidence: ${((_extractedContent!["confidence"] as double) * 100).toStringAsFixed(1)}%',
                  Icons.verified_rounded,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Extracted Content:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 100,
                maxHeight: 250,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _extractedContent!["extracted_text"].toString().isEmpty
                      ? 'No text was extracted from the image.'
                      : _extractedContent!["extracted_text"].toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugSection() {
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(
            Icons.bug_report_rounded,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          title: Text(
            'Debug Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  JsonEncoder.withIndent('  ').convert(_fullResponse),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
