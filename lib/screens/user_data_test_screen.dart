import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

class UserDataTestScreen extends StatefulWidget {
  const UserDataTestScreen({Key? key}) : super(key: key);

  @override
  State<UserDataTestScreen> createState() => _UserDataTestScreenState();
}

class _UserDataTestScreenState extends State<UserDataTestScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userData = await UserService.getUserProfileData();
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Data Test'),
        actions: [
          IconButton(
            onPressed: _loadUserData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current User Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Firebase User',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Email: ${AuthService.currentUser?.email ?? 'Not logged in'}'),
                    Text('Display Name: ${AuthService.currentUser?.displayName ?? 'None'}'),
                    Text('User ID: ${AuthService.currentUser?.uid ?? 'None'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // User Data from Service
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Data from Firebase',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_error != null)
                      Text(
                        'Error: $_error',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      )
                    else if (_userData != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: ${_userData!['name']}'),
                          Text('Email: ${_userData!['email']}'),
                          Text('Knowledge Graphs: ${_userData!['knowledgeGraphsCount']}'),
                          Text('Total Spent: ${UserService.formatCurrency(_userData!['totalSpent'])}'),
                          Text('Receipts Count: ${_userData!['receiptsCount']}'),
                          Text('This Month: ${UserService.formatCurrency(_userData!['thisMonthSpent'])}'),
                          Text('Receipts Scanned: ${_userData!['receiptsScanned']}'),
                        ],
                      )
                    else
                      const Text('No data available'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
