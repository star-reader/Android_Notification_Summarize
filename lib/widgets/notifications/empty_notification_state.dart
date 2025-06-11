import 'package:flutter/material.dart';

class EmptyNotificationState extends StatelessWidget {
  const EmptyNotificationState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: Color(0xFF95A5A6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '暂无通知',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF7F8C8D),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '新的通知将会在这里显示',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFBDC3C7),
            ),
          ),
        ],
      ),
    );
  }
} 