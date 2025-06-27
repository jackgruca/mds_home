import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_config.dart';

enum MdsButtonType { primary, secondary, text }

class MdsButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final MdsButtonType type;
  final IconData? icon;

  const MdsButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.type = MdsButtonType.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case MdsButtonType.secondary:
        return _buildOutlinedButton(context);
      case MdsButtonType.text:
        return _buildTextButton(context);
      case MdsButtonType.primary:
      default:
        return _buildElevatedButton(context);
    }
  }

  Widget _buildElevatedButton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode ? ThemeConfig.brightRed : ThemeConfig.deepRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      child: _buildButtonChild(),
    );
  }
  
  Widget _buildOutlinedButton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = isDarkMode ? ThemeConfig.brightRed : ThemeConfig.deepRed;

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _buildButtonChild(),
    );
  }

  Widget _buildTextButton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: isDarkMode ? ThemeConfig.brightRed : ThemeConfig.deepRed,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _buildButtonChild(),
    );
  }

  Widget _buildButtonChild() {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold));
  }
} 