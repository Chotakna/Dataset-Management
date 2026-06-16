import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ChartImage extends StatelessWidget {
  final String? imageUrl;
  final String? base64Data;
  final double height;
  final String? errorMessage;

  const ChartImage.network({
    super.key,
    required this.imageUrl,
    this.height = 400,
  }) : base64Data = null, errorMessage = null;

  const ChartImage.base64({
    super.key,
    required this.base64Data,
    this.height = 400,
  }) : imageUrl = null, errorMessage = null;

  const ChartImage.error({
    super.key,
    this.height = 400,
    this.errorMessage,
  }) : imageUrl = null, base64Data = null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3A3020).withValues(alpha: 0.4)),
          ),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.contain,
        width: double.infinity,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _loadingIndicator();
        },
        errorBuilder: (context, error, stackTrace) => _errorWidget('Failed to load chart'),
      );
    }

    if (base64Data != null) {
      try {
        final bytes = base64Decode(base64Data!);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.contain,
          width: double.infinity,
          height: height,
          errorBuilder: (context, error, stackTrace) => _errorWidget('Failed to decode chart'),
        );
      } catch (_) {
        return _errorWidget('Invalid image data');
      }
    }

    return _errorWidget(errorMessage ?? 'No chart data');
  }

  Widget _loadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
    );
  }

  Widget _errorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_rounded, size: 40, color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13)),
        ],
      ),
    );
  }
}
