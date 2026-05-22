import 'package:flutter/material.dart';
import 'package:skillforgeapp/ui/design_system.dart';

class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    this.width,
    this.radius = 16,
  });

  final String label;
  final String value;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final child = GlassPanel(
      radius: radius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
    if (width == null) return child;
    return SizedBox(width: width, child: child);
  }
}
