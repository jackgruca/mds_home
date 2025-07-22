import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/theme_config.dart';

class SaveCustomRankingDialog extends StatefulWidget {
  final String position;
  final String? initialName;
  final bool isUpdate;

  const SaveCustomRankingDialog({
    super.key,
    required this.position,
    this.initialName,
    this.isUpdate = false,
  });

  @override
  State<SaveCustomRankingDialog> createState() => _SaveCustomRankingDialogState();
}

class _SaveCustomRankingDialogState extends State<SaveCustomRankingDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameController;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  
  bool _isValid = false;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _isValid = _nameController.text.trim().isNotEmpty;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _nameController.addListener(_validateInput);
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _validateInput() {
    final isValid = _nameController.text.trim().isNotEmpty;
    if (isValid != _isValid) {
      setState(() {
        _isValid = isValid;
      });
    }
  }

  Future<void> _save() async {
    if (!_isValid || _isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    HapticFeedback.lightImpact();
    
    // Simulate saving delay for user feedback
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      Navigator.of(context).pop(_nameController.text.trim());
    }
  }

  void _cancel() {
    HapticFeedback.lightImpact();
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  String get _positionDisplay {
    switch (widget.position.toLowerCase()) {
      case 'qb':
        return 'Quarterback';
      case 'rb':
        return 'Running Back';
      case 'wr':
        return 'Wide Receiver';
      case 'te':
        return 'Tight End';
      default:
        return widget.position.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopScope(
      canPop: !_isSaving,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: AlertDialog(
                backgroundColor: theme.colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                shadowColor: ThemeConfig.darkNavy.withOpacity(0.3),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ThemeConfig.darkNavy.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.isUpdate ? Icons.edit : Icons.save,
                        color: ThemeConfig.darkNavy,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isUpdate ? 'Update Rankings' : 'Save Custom Rankings',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            _positionDisplay,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter a name for your custom ${_positionDisplay.toLowerCase()} rankings:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      autofocus: true,
                      enabled: !_isSaving,
                      maxLength: 50,
                      decoration: InputDecoration(
                        labelText: 'Ranking Name',
                        hintText: 'e.g., "My 2024 ${_positionDisplay} Rankings"',
                        prefixIcon: Icon(
                          Icons.label_outline,
                          color: theme.colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: ThemeConfig.darkNavy,
                            width: 2,
                          ),
                        ),
                        errorText: _nameController.text.trim().isEmpty && _nameController.text.isNotEmpty
                            ? 'Please enter a valid name'
                            : null,
                      ),
                      onSubmitted: _isValid ? (_) => _save() : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You can edit or delete this ranking later from "My Rankings"',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: _isSaving ? null : _cancel,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isValid && !_isSaving ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConfig.darkNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: _isValid ? 2 : 0,
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.8),
                              ),
                            ),
                          )
                        : Text(widget.isUpdate ? 'Update' : 'Save'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Utility function to show the dialog
Future<String?> showSaveCustomRankingDialog(
  BuildContext context,
  String position, {
  String? initialName,
  bool isUpdate = false,
}) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => SaveCustomRankingDialog(
      position: position,
      initialName: initialName,
      isUpdate: isUpdate,
    ),
  );
}

// Success snackbar helper
void showSaveSuccessSnackBar(BuildContext context, String rankingName, bool isUpdate) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isUpdate ? Icons.check_circle : Icons.save,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isUpdate
                  ? 'Rankings "$rankingName" updated successfully!'
                  : 'Rankings "$rankingName" saved successfully!',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      action: SnackBarAction(
        label: 'View',
        textColor: Colors.white,
        onPressed: () {
          // TODO: Navigate to My Rankings when implemented
        },
      ),
    ),
  );
}