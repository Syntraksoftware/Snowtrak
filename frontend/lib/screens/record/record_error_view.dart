import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

class RecordErrorView extends StatelessWidget {
  const RecordErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Activity'),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 80,
                color: context.colors.textTertiary,
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Map functionality is coming soon. You can still record activities without the map.',
                  style: TextStyle(fontSize: 14, color: context.colors.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
