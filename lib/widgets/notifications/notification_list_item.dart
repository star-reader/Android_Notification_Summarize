import 'package:flutter/material.dart';

class NotificationListItem extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final String formattedTime;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.formattedTime,
  });

  @override
  Widget build(BuildContext context) {
    final data = notification['data'] as Map<String, dynamic>;
    final packageName = notification['packageName'] as String;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppIcon(packageName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          data['title'] ?? '无标题',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedTime,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['content'] ?? '无内容',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    packageName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIcon(String packageName) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.primaries[
        packageName.hashCode % Colors.primaries.length
      ],
      child: Text(
        packageName.split('.').last.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 