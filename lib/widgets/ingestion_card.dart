import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class IngestionCard extends StatelessWidget {
  final dynamic image; // Can be File, Uint8List, or String
  final bool isProcessing;
  final VoidCallback onTap;

  const IngestionCard({super.key, 
    required this.image,
    required this.isProcessing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 290,
          width: double.infinity,
          child: image == null
              ? _buildPlaceholder()
              : _buildImageContent(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: 76,
          color: Colors.grey[400],
        ),
        SizedBox(height: 9),
        Text(
          'Tap to add receipt photo',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent() {
    return Stack(
      children: [
        // Image - Web compatible
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildImage(),
          ),
        ),
        // Loading overlay
        if (isProcessing)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 10),
                Text(
                  'Processing...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImage() {
    if (kIsWeb && image is Uint8List) {
      // Web: image is Uint8List
      return Image.memory(
        image as Uint8List,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (!kIsWeb && image is String) {
      // Mobile: image is file path string
      return Image.file(
        File(image as String),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (image is File) {
      // Legacy File support
      return Image.file(
        image as File,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      // Fallback
      return Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Text('Image format not supported'),
        ),
      );
    }
  }
}
