import 'package:flutter/material.dart';

/// Temporary stand-in content for tabs that aren't built yet.
/// Delete instances as real screens replace them.
class PlaceholderSection extends StatelessWidget {
  final String title;
  final String? subtitle;

  const PlaceholderSection({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_outlined,
              size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
