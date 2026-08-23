import 'package:flutter/material.dart';

import 'package:brewline/shared/widgets/placeholder_section.dart';

/// Menu tab content for the waiter profile.
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderSection(
      title: 'Menu',
      subtitle:
          'Grid of products — use ResponsiveGrid for the item cards here.',
    );
  }
}
