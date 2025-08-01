import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/auth_service.dart';

class GraphVisualizationScreen extends StatefulWidget {
  final String userId;

  const GraphVisualizationScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _GraphVisualizationScreenState createState() => _GraphVisualizationScreenState();
}

class _GraphVisualizationScreenState extends State<GraphVisualizationScreen> {
  Map<String, dynamic>? _graphData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserGraph();
  }

  Future<void> _loadUserGraph() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Loading knowledge graph data from Firebase
      if (!AuthService.isLoggedIn) {
        setState(() {
          _isLoading = false;
          _error = 'Please log in to view your knowledge graph.';
          _graphData = null;
        });
        return;
      }

      final userKnowledgeGraphs = await AuthService.getUserKnowledgeGraphs();

      if (userKnowledgeGraphs.isNotEmpty) {
        final realData = _createKnowledgeGraphFromUserData(userKnowledgeGraphs);

        setState(() {
          _graphData = realData;
          _isLoading = false;
        });

        _showToast("Knowledge graph loaded from Firebase!");
      } else {
        setState(() {
          _graphData = null;
          _isLoading = false;
          _error =
          'No knowledge graph data available. Scan a receipt to generate your knowledge graph.';
        });
      }
    } catch (e) {
      setState(() {
        _graphData = null;
        _isLoading = false;
        _error = 'Error loading knowledge graph. Please try again.';
      });
    }
  }

  Map<String, dynamic> _createKnowledgeGraphFromUserData(
      List<Map<String, dynamic>> userKnowledgeGraphs) {
    List<Map<String, dynamic>> nodes = [];
    List<Map<String, dynamic>> edges = [];

    int totalReceipts = userKnowledgeGraphs.length;
    double totalSpent = 0.0;
    Set<String> merchants = {};
    Set<String> categories = {};
    int totalItems = 0;

    for (int i = 0; i < userKnowledgeGraphs.length; i++) {
      var receipt = userKnowledgeGraphs[i];
      var receiptData = receipt['receipt_data'] ?? {};

      String receiptId = receiptData['receipt_id'] ?? 'receipt_$i';
      String merchantName = receiptData['merchant_name'] ?? 'Unknown Merchant';
      String category = receiptData['business_category'] ?? 'Unknown';
      double amount = (receiptData['total_amount'] ?? 0.0).toDouble();
      int itemCount = receiptData['item_count'] ?? 0;

      totalSpent += amount;
      merchants.add(merchantName);
      categories.add(category);
      totalItems += itemCount;

      nodes.add({
        'id': receiptId,
        'label': '$merchantName\n\$${amount.toStringAsFixed(2)}',
        'type': 'receipt',
        'size': 20 + (amount / 10),
        'color': _getCategoryColor(category),
        'metadata': {
          'merchant': merchantName,
          'amount': amount,
          'category': category,
          'items': itemCount,
          'date': receiptData['created_at'] ?? '',
        }
      });

      String merchantId = 'merchant_${merchantName.replaceAll(' ', '_')}';
      if (!nodes.any((node) => node['id'] == merchantId)) {
        nodes.add({
          'id': merchantId,
          'label': merchantName,
          'type': 'merchant',
          'size': 15,
          'color': '#4CAF50',
          'metadata': {'name': merchantName, 'category': category}
        });
      }

      String categoryId = 'category_${category.replaceAll(' ', '_')}';
      if (!nodes.any((node) => node['id'] == categoryId)) {
        nodes.add({
          'id': categoryId,
          'label': category,
          'type': 'category',
          'size': 12,
          'color': '#FF9800',
          'metadata': {'category': category}
        });
      }

      edges.add({
        'from': receiptId,
        'to': merchantId,
        'label': 'purchased_at',
        'type': 'purchased_at'
      });

      edges.add({
        'from': merchantId,
        'to': categoryId,
        'label': 'belongs_to',
        'type': 'belongs_to'
      });
    }

    return {
      'nodes': nodes,
      'edges': edges,
      'summary': {
        'total_receipts': totalReceipts,
        'total_spent': totalSpent,
        'unique_merchants': merchants.length,
        'unique_categories': categories.length,
        'total_items': totalItems,
        'merchants': merchants.toList(),
        'categories': categories.toList(),
      },
      'graph': {
        'entities': nodes,
        'relations': edges,
      },
      'analytics': {
        'spending_by_category': _calculateSpendingByCategory(userKnowledgeGraphs),
        'spending_by_merchant': _calculateSpendingByMerchant(userKnowledgeGraphs),
        'monthly_spending': _calculateMonthlySpending(userKnowledgeGraphs),
      }
    };
  }

  Map<String, double> _calculateSpendingByCategory(
      List<Map<String, dynamic>> receipts) {
    Map<String, double> spending = {};
    for (var receipt in receipts) {
      var receiptData = receipt['receipt_data'] ?? {};
      String category = receiptData['business_category'] ?? 'Unknown';
      double amount = (receiptData['total_amount'] ?? 0.0).toDouble();
      spending[category] = (spending[category] ?? 0.0) + amount;
    }
    return spending;
  }

  Map<String, double> _calculateSpendingByMerchant(List<Map<String, dynamic>> receipts) {
    Map<String, double> spending = {};
    for (var receipt in receipts) {
      var receiptData = receipt['receipt_data'] ?? {};
      String merchant = receiptData['merchant_name'] ?? 'Unknown';
      double amount = (receiptData['total_amount'] ?? 0.0).toDouble();
      spending[merchant] = (spending[merchant] ?? 0.0) + amount;
    }
    return spending;
  }

  Map<String, double> _calculateMonthlySpending(List<Map<String, dynamic>> receipts) {
    Map<String, double> spending = {};
    for (var receipt in receipts) {
      var receiptData = receipt['receipt_data'] ?? {};
      String dateStr = receiptData['created_at'] ?? '';
      double amount = (receiptData['total_amount'] ?? 0.0).toDouble();

      try {
        DateTime date = DateTime.parse(dateStr);
        String monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        spending[monthKey] = (spending[monthKey] ?? 0.0) + amount;
      } catch (e) {
        spending['Unknown'] = (spending['Unknown'] ?? 0.0) + amount;
      }
    }
    return spending;
  }

  String _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'grocery':
      case 'food':
        return '#4CAF50';
      case 'retail':
      case 'shopping':
        return '#2196F3';
      case 'restaurant':
      case 'dining':
        return '#FF5722';
      case 'gas':
      case 'fuel':
        return '#FFC107';
      case 'pharmacy':
      case 'health':
        return '#1976D2'; // Changed from purple to Google Blue
      default:
        return '#607D8B';
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Theme.of(context).colorScheme.primary,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Knowledge Graph',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadUserGraph,
            tooltip: 'Refresh',
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading Knowledge Graph...',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Analyzing your receipt data',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Knowledge Graph Available',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(color: Theme.of(context).colorScheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Go Back'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _loadUserGraph,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_graphData == null || _graphData!.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.account_tree_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Knowledge Graph Data',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Process some receipts to generate your knowledge graph',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add receipts'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummarySection(),
          const SizedBox(height: 20),
          _buildGraphSection(),
          const SizedBox(height: 20),
          _buildNodesSection(),
          const SizedBox(height: 20),
          _buildAnalyticsSection(),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final summary = _graphData?['summary'];
    if (summary == null) return Container();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Receipts',
                    '${summary['total_receipts'] ?? 0}',
                    Icons.receipt,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Total Spent',
                    '\$${(summary['total_spent'] ?? 0.0).toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Merchants',
                    '${summary['unique_merchants'] ?? 0}',
                    Icons.store,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Categories',
                    '${summary['unique_categories'] ?? 0}',
                    Icons.category,
                    Color(0xFF1976D2), // Google Blue instead of purple
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGraphSection() {
    final graph = _graphData?['graph'];
    if (graph == null) return Container();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Knowledge Graph Structure',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Entities: ${graph['entities']?.length ?? 0}'),
            Text('Relations: ${graph['relations']?.length ?? 0}'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(
                child: Text(
                  'Graph Visualization\n(Visual representation will be implemented here)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodesSection() {
    if (_graphData?['graph'] == null) {
      return Container();
    }

    final nodes = _graphData?['nodes'] as List? ?? [];
    final edges = _graphData?['edges'] as List? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Graph Details',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Nodes: ${nodes.length}'),
            Text('Edges: ${edges.length}'),
            const SizedBox(height: 16),
            if (nodes.isNotEmpty) ...[
              const Text(
                'Recent Nodes:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...nodes.take(5).map((node) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _parseColor(node['color'] ?? '#607D8B'),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${node['label']} (${node['type']})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    if (_graphData?['graph'] == null) {
      return Container();
    }
    final analytics = _graphData?['analytics'] ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (analytics['spending_by_category'] != null) ...[
              const Text(
                'Spending by Category:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...(analytics['spending_by_category'] as Map<String, double>)
                  .entries
                  .map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text('\$${entry.value.toStringAsFixed(2)}'),
                  ],
                ),
              )),
              const SizedBox(height: 16),
            ],
            Text(
                'Graph generated: ${_formatDate(_graphData?['metadata']?['generated_at'])}'),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.substring(1, 7), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return 'Invalid';
    }
  }
}
