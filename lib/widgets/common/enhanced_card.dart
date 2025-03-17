// lib/widgets/common/enhanced_card.dart
import 'package:flutter/material.dart';

class EnhancedCard extends StatefulWidget {
  final Widget child;
  final String title;
  final IconData? icon;
  final bool isHighlighted;
  final double elevation;
  
  const EnhancedCard({
    super.key,
    required this.child,
    this.title = '',
    this.icon,
    this.isHighlighted = false,
    this.elevation = 2.0,
  });

  @override
  _EnhancedCardState createState() => _EnhancedCardState();
}

class _EnhancedCardState extends State<EnhancedCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: widget.isHighlighted
                  ? theme.colorScheme.primary.withOpacity(isDark ? 0.5 : 0.3)
                  : Colors.black.withOpacity(_isHovered ? 0.2 : 0.1),
              blurRadius: _isHovered ? 10 : widget.elevation * 2,
              spreadRadius: _isHovered ? 2 : 0,
            ),
          ],
          border: widget.isHighlighted
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.title.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isHighlighted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: widget.isHighlighted
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: theme.dividerTheme.color ?? Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: widget.isHighlighted
                            ? Colors.white
                            : theme.iconTheme.color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: widget.isHighlighted
                            ? Colors.white
                            : theme.textTheme.titleMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(16),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}