import 'package:flutter/material.dart';
import '../utils/device_compatibility.dart';

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  DeviceInfo? _deviceInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final info = await DeviceCompatibility.getDeviceInfo();
      setState(() {
        _deviceInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _deviceInfo = DeviceInfo(
          platform: 'error',
          isSupported: false,
          reason: 'Failed to load device info: $e',
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Compatibility Test'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDeviceInfo(),
    );
  }

  Widget _buildDeviceInfo() {
    if (_deviceInfo == null) {
      return const Center(
        child: Text('Failed to load device information'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device Compatibility Status',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Platform', _deviceInfo!.platform),
                  _buildInfoRow(
                    'Google Wallet Support',
                    _deviceInfo!.isSupported ? 'Supported ✅' : 'Not Supported ❌',
                    valueColor: _deviceInfo!.isSupported ? Colors.green : Colors.red,
                  ),
                  if (_deviceInfo!.deviceModel != null)
                    _buildInfoRow('Device Model', _deviceInfo!.deviceModel!),
                  if (_deviceInfo!.apiLevel != null)
                    _buildInfoRow('Android API Level', _deviceInfo!.apiLevel.toString()),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _deviceInfo!.isSupported 
                          ? Colors.green[50] 
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _deviceInfo!.isSupported 
                            ? Colors.green[200]! 
                            : Colors.red[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _deviceInfo!.isSupported 
                              ? Icons.check_circle 
                              : Icons.error,
                          color: _deviceInfo!.isSupported 
                              ? Colors.green[700] 
                              : Colors.red[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _deviceInfo!.reason,
                            style: TextStyle(
                              color: _deviceInfo!.isSupported 
                                  ? Colors.green[700] 
                                  : Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Testing Information',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Requirements for Google Wallet:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Android 7.0 (API level 24) or higher'),
                  const Text('• Google Play Services installed'),
                  const Text('• Active internet connection'),
                  const Text('• Google account signed in'),
                  const SizedBox(height: 16),
                  const Text(
                    'If you\'re testing on different devices, verify that each device meets these requirements.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadDeviceInfo();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Device Info'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
