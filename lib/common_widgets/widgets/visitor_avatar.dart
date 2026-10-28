import 'package:flutter/material.dart';

import '../../data/models/visitor/visitor_model.dart';
import '../../utils/components/color/app_colors.dart';

class VisitorAvatar extends StatelessWidget {
  const VisitorAvatar({
    super.key,
    required this.name,
    required this.status,
    this.size = 46,
  });

  final String name;
  final VisitorStatus status;
  final double size;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forStatus(status);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Text(
        _initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
