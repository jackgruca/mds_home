import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_config.dart';

class MdsFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? selectedColor;
  final Color? unselectedColor;
  final bool showCheckmark;
  final bool enabled;

  const MdsFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
    this.icon,
    this.selectedColor,
    this.unselectedColor,
    this.showCheckmark = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBgColor = selectedColor ?? Theme.of(context).colorScheme.primary;
    final unselectedBgColor = unselectedColor ?? Theme.of(context).cardColor;
    
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : unselectedBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
              ? selectedBgColor 
              : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: selectedBgColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected 
                  ? Colors.white 
                  : Theme.of(context).textTheme.bodyMedium?.color,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                  ? Colors.white 
                  : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (isSelected && showCheckmark) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
} 