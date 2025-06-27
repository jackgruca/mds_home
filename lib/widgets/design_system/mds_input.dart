import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mds_home/utils/theme_config.dart';

enum MdsInputType { 
  standard, 
  search, 
  filter, 
  numeric,
  email,
  password
}

class MdsInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final MdsInputType type;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;

  const MdsInput({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.type = MdsInputType.standard,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<MdsInput> createState() => _MdsInputState();
}

class _MdsInputState extends State<MdsInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _obscureText = widget.type == MdsInputType.password;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDarkMode ? Colors.white : ThemeConfig.darkNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        Container(
          decoration: _buildContainerDecoration(isDarkMode),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            keyboardType: _getKeyboardType(),
            inputFormatters: widget.inputFormatters,
            autofocus: widget.autofocus,
            obscureText: _obscureText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.white : ThemeConfig.darkNavy,
            ),
            decoration: _buildInputDecoration(isDarkMode),
          ),
        ),
        
        if (widget.helperText != null || widget.errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText ?? widget.helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: widget.errorText != null 
                ? ThemeConfig.deepRed 
                : (isDarkMode ? ThemeConfig.mediumGray : ThemeConfig.darkGray),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  BoxDecoration _buildContainerDecoration(bool isDarkMode) {
    Color borderColor;
    double borderWidth = 1.5;
    
    if (widget.errorText != null) {
      borderColor = ThemeConfig.deepRed;
    } else if (_isFocused) {
      borderColor = isDarkMode ? ThemeConfig.brightRed : ThemeConfig.deepRed;
      borderWidth = 2;
    } else {
      borderColor = isDarkMode 
        ? ThemeConfig.mediumGray.withOpacity(0.3)
        : ThemeConfig.mediumGray.withOpacity(0.5);
    }

    return BoxDecoration(
      color: _getBackgroundColor(isDarkMode),
      borderRadius: BorderRadius.circular(_getBorderRadius()),
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
      boxShadow: _isFocused ? [
        BoxShadow(
          color: (isDarkMode ? ThemeConfig.brightRed : ThemeConfig.deepRed).withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ] : null,
    );
  }

  InputDecoration _buildInputDecoration(bool isDarkMode) {
    return InputDecoration(
      hintText: widget.hint,
      hintStyle: TextStyle(
        color: isDarkMode 
          ? ThemeConfig.mediumGray.withOpacity(0.7)
          : ThemeConfig.darkGray.withOpacity(0.7),
      ),
      prefixIcon: widget.prefixIcon != null ? Icon(
        widget.prefixIcon,
        color: _getIconColor(isDarkMode),
        size: 20,
      ) : null,
      suffixIcon: _buildSuffixIcon(isDarkMode),
      border: InputBorder.none,
      contentPadding: _getContentPadding(),
      counterText: '', // Hide character counter
    );
  }

  Widget? _buildSuffixIcon(bool isDarkMode) {
    if (widget.type == MdsInputType.password) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: _getIconColor(isDarkMode),
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }
    
    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(
          widget.suffixIcon,
          color: _getIconColor(isDarkMode),
          size: 20,
        ),
        onPressed: widget.onSuffixTap,
      );
    }
    
    return null;
  }

  Color _getBackgroundColor(bool isDarkMode) {
    if (!widget.enabled) {
      return isDarkMode 
        ? ThemeConfig.darkGray.withOpacity(0.3)
        : ThemeConfig.lightGray.withOpacity(0.5);
    }
    
    switch (widget.type) {
      case MdsInputType.search:
        return isDarkMode 
          ? ThemeConfig.darkGray.withOpacity(0.7)
          : ThemeConfig.lightGray.withOpacity(0.8);
      case MdsInputType.filter:
        return isDarkMode 
          ? ThemeConfig.darkNavy.withOpacity(0.3)
          : Colors.white;
      default:
        return isDarkMode 
          ? ThemeConfig.darkGray.withOpacity(0.5)
          : Colors.white;
    }
  }

  Color _getIconColor(bool isDarkMode) {
    if (_isFocused) {
      return isDarkMode ? ThemeConfig.brightRed : ThemeConfig.deepRed;
    }
    return isDarkMode ? ThemeConfig.mediumGray : ThemeConfig.darkGray;
  }

  EdgeInsets _getContentPadding() {
    switch (widget.type) {
      case MdsInputType.search:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
      case MdsInputType.filter:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
      default:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    }
  }

  double _getBorderRadius() {
    switch (widget.type) {
      case MdsInputType.search:
        return 24;
      case MdsInputType.filter:
        return 6;
      default:
        return 8;
    }
  }

  TextInputType? _getKeyboardType() {
    if (widget.keyboardType != null) return widget.keyboardType;
    
    switch (widget.type) {
      case MdsInputType.email:
        return TextInputType.emailAddress;
      case MdsInputType.numeric:
        return TextInputType.number;
      case MdsInputType.search:
        return TextInputType.text;
      default:
        return null;
    }
  }
}

 