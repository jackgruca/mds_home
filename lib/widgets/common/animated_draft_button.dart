// lib/widgets/common/animated_draft_button.dart
import 'package:flutter/material.dart';

class AnimatedDraftButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final String teamLogo;
  final bool isPrimary;

  const AnimatedDraftButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.teamLogo = '',
    this.isPrimary = true,
  });

  @override
  _AnimatedDraftButtonState createState() => _AnimatedDraftButtonState();
}

class _AnimatedDraftButtonState extends State<AnimatedDraftButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isPrimary
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: _isHovered ? 8 : 4,
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
                return Colors.white.withOpacity(0.2);
              },
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.teamLogo.isNotEmpty) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Image.network(
                    widget.teamLogo,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}