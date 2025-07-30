import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/ingestion_card.dart';
import '../services/api_services.dart';
import '../services/auth_service.dart';
import '../models/receipt_data.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Receipt Processed!', style: TextStyle(color: Colors.green)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_receiptData != null) ...[
                  Text('Receipt processed successfully!', style: TextStyle(fontWeight: FontWeight.w500)),
                  SizedBox(height: 16),
                  _buildInfoRow('Receipt ID:', _receiptData!.receiptId),
                  _buildInfoRow('Merchant:', _receiptData!.merchantName),
                  _buildInfoRow('Total Amount:', _receiptData!.formattedTotal),
                  _buildInfoRow('Items:', _receiptData!.itemSummary),
                  _buildInfoRow('Business Type:', _receiptData!.businessCategory),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.account_tree, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('Knowledge Graph Built!', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                    ],
                  ),
                  SizedBox(height: 8),
                  _buildInfoRow('Nodes:', '${_receiptData!.nodeCount}'),
                  _buildInfoRow('Edges:', '${_receiptData!.edgeCount}'),
                  _buildInfoRow('Processing Time:', _receiptData!.processingTime),
                  if (_receiptData!.hasExpiringSoon) ...[
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text('Expiry Alerts', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
                      ],
                    ),
                    SizedBox(height: 8),
                    ..._receiptData!.alerts.map((alert) => Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text('• $alert', style: TextStyle(color: Colors.orange[700])),
                    )),
                  ],
                  if (_receiptData!.hasWarranties) ...[
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.security, color: const Color(0xFF1976D2), size: 20), // Google Blue
                        SizedBox(width: 8),
                        Text('Warranties', style: TextStyle(fontWeight: FontWeight.w600, color: const Color(0xFF1976D2))),
                      ],
                    ),
                    SizedBox(height: 8),
                    _buildInfoRow('Warranty Items:', _receiptData!.warrantySummary),
                  ],
                ] else if (_fullResponse != null) ...[
                  Text('Receipt processed with legacy format', style: TextStyle(fontWeight: FontWeight.w500)),
                  SizedBox(height: 16),
                  _buildInfoRow('Status:', 'Success'),
                ] else ...[
                  Text('Receipt processed but no data available', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          if (_receiptData != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDetailedView();
              },
              child: Text('View Details'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Error', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(userMessage, style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            Text('Please try again or contact support if the problem persists.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.red)),
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
      appBar: AppBar(
        title: Text('Scan Receipt'),
        backgroundColor: const Color(0xFF1976D2), // Google Blue
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(
                'Snap or upload your receipt to extract the details below.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 18),
              IngestionCard(
                image: _image,
                isProcessing: _isProcessing,
                onTap: _image == null ? () => _pickImage() : () {},
              ),
              SizedBox(height: 30),
              _image == null
                  ? Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.camera_alt, color: Colors.white),
                    label: Text(
                      kIsWeb ? 'Select Image' : 'Take Photo',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 55),
                      backgroundColor: const Color(0xFF1976D2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                  if (!kIsWeb) ...[
                    SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: Icon(Icons.photo_library, color: const Color(0xFF1976D2)),
                      label: Text(
                        'Choose from Gallery',
                        style: TextStyle(color: const Color(0xFF1976D2), fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 55),
                        side: BorderSide(color: const Color(0xFF1976D2), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              )
                  : Column(
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.account_tree, color: const Color(0xFF1976D2)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Build Knowledge Graph',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  'Extract entities and relationships using AI',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
                            activeColor: const Color(0xFF1976D2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _uploadImage,
                    icon: _isProcessing
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Icon(
                      _buildGraph ? Icons.auto_graph : Icons.cloud_upload,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isProcessing
                          ? (_buildGraph ? 'Building Graph...' : 'Processing...')
                          : (_buildGraph ? 'Extract & Build Graph' : 'Extract Receipt Data'),
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 55),
                      backgroundColor: _isProcessing
                          ? Colors.grey
                          : (_buildGraph ? const Color(0xFF1976D2) : Colors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                  SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () {
                      setState(() {
                        _image = null;
                        _isUploaded = false;
                        _receiptData = null;
                        _extractedContent = null;
                        _fullResponse = null;
                        _buildGraph = false;
                      });
                    },
                    icon: Icon(Icons.refresh, color: const Color(0xFF1976D2)),
                    label: Text(
                      'Change Image',
                      style: TextStyle(color: const Color(0xFF1976D2), fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 45),
                      side: BorderSide(color: const Color(0xFF1976D2), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (_isUploaded && _extractedContent != null)
                Card(
                  elevation: 5,
                  margin: EdgeInsets.only(top: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.text_fields, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Extracted Text',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Divider(),
                        SizedBox(height: 8),
                        _buildInfoRow('Text Length:', '${_extractedContent!['text_length']} characters'),
                        _buildInfoRow('Confidence:', '${((_extractedContent!["confidence"] as double) * 100).toStringAsFixed(1)}%'),
                        _buildInfoRow('MIME Type:', _extractedContent!['mime_type']),
                        SizedBox(height: 16),
                        Text(
                          "Extracted Text:",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: 100,
                            maxHeight: 250,
                          ),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              _extractedContent!["extracted_text"].toString().isEmpty
                                  ? 'No text was extracted from the image.'
                                  : _extractedContent!["extracted_text"].toString(),
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'monospace',
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_fullResponse != null) ...[
                SizedBox(height: 20),
                ExpansionTile(
                  title: Text('Debug: Backend Response'),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          JsonEncoder.withIndent('  ').convert(_fullResponse),
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showGraphDetails() {
    if (_fullResponse != null && _fullResponse!['graph_created'] == true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Knowledge Graph Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Graph ID: ${_fullResponse!["graph_id"] ?? "Unknown"}'),
              SizedBox(height: 8),
              Text('Entities: ${_fullResponse!["total_entities"] ?? 0}'),
              Text('Relations: ${_fullResponse!["total_relations"] ?? 0}'),
              if (_fullResponse!['knowledge_graph'] != null && _fullResponse!['knowledge_graph']['summary'] != null) ...[
                SizedBox(height: 12),
                Text('Breakdown:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• Entity Types: ${(_fullResponse!["knowledge_graph"]["summary"]["entity_types"] as List?)?.length ?? 0}'),
                Text('• Relation Types: ${(_fullResponse!["knowledge_graph"]["summary"]["relation_types"] as List?)?.length ?? 0}'),
                if (_fullResponse!["knowledge_graph"]["summary"]["entity_types"] != null)
                  Text('• Types: ${(_fullResponse!["knowledge_graph"]["summary"]["entity_types"] as List).join(", ")}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
