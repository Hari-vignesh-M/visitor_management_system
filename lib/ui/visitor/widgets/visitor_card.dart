import 'package:flutter/material.dart';

import '../../../common_widgets/widgets/app_card.dart';
import '../../../common_widgets/widgets/status_chip.dart';
import '../../../common_widgets/widgets/visitor_avatar.dart';
import '../../../data/models/visitor/visitor_model.dart';
import '../../../utils/components/color/app_colors.dart';

/// Visitor summary used in the list and on the dashboard.
/// Edit / delete buttons are shown only when their callbacks are given.
class VisitorCard extends StatelessWidget {
  const VisitorCard({
    super.key,
    required this.visitor,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final VisitorModel visitor;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  bool get _hasActions => onEdit != null || onDelete != null;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VisitorAvatar(name: visitor.name, status: visitor.status),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visitor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _IconText(icon: Icons.phone_outlined, text: visitor.mobile),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: visitor.status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Tag(icon: Icons.apartment_outlined, text: visitor.project),
                    _Tag(icon: Icons.badge_outlined, text: visitor.visitorType),
                  ],
                ),
              ),
              if (onEdit != null)
                _ActionButton(
                  tooltip: 'Edit',
                  icon: Icons.edit_outlined,
                  color: AppColors.primary,
                  onPressed: onEdit!,
                ),
              if (onDelete != null)
                _ActionButton(
                  tooltip: 'Delete',
                  icon: Icons.delete_outline,
                  color: AppColors.error,
                  onPressed: onDelete!,
                ),
              if (!_hasActions)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textHint,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Small grey pill for project / visitor type.
class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.08),
        foregroundColor: color,
      ),
      icon: Icon(icon, size: 20),
    );
  }
}
