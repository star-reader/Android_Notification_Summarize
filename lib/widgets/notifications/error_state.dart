import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  final String error;

  const ErrorState({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {

    print('渲染失败：$error');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 0,
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  '加载失败',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 