import 'package:flutter/material.dart';
import '../../utils/theme_config.dart';

class SaveCustomVorpRankingDialog extends StatefulWidget {
  final String position;
  final String? existingName;
  final Function(String) onSave;

  const SaveCustomVorpRankingDialog({
    super.key,
    required this.position,
    this.existingName,
    required this.onSave,
  });

  @override
  State<SaveCustomVorpRankingDialog> createState() => _SaveCustomVorpRankingDialogState();
}

class _SaveCustomVorpRankingDialogState extends State<SaveCustomVorpRankingDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    
    // Set default name or existing name
    final defaultName = widget.existingName ?? 
        'My Custom ${widget.position.toUpperCase()} Rankings ${DateTime.now().month}/${DateTime.now().day}';
    _nameController.text = defaultName;
    _isValid = defaultName.trim().isNotEmpty;
    
    _nameController.addListener(_validateName);
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateName);
    _nameController.dispose();
    super.dispose();
  }

  void _validateName() {
    setState(() {
      _isValid = _nameController.text.trim().isNotEmpty;
    });
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      widget.onSave(name);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.save_outlined,
            color: ThemeConfig.darkNavy,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            widget.existingName != null ? 'Update Ranking' : 'Save Custom Ranking',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeConfig.darkNavy,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existingName != null 
                  ? 'Update the name for your custom ${widget.position.toUpperCase()} rankings:'
                  : 'Give your custom ${widget.position.toUpperCase()} rankings a name:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: true,
              maxLength: 50,
              decoration: InputDecoration(
                labelText: 'Ranking Name',
                hintText: 'e.g., "My Custom ${widget.position.toUpperCase()} Rankings"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ThemeConfig.darkNavy, width: 2),
                ),
                prefixIcon: const Icon(Icons.label_outline),
                counterText: '', // Hide character counter
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_isValid) _handleSave();
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'What will be saved:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• Your custom player rankings and order\n'
                    '• Calculated projected points and VORP values\n'
                    '• Position-specific data (${widget.position.toUpperCase()})\n'
                    '• Timestamp for tracking changes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValid ? _handleSave : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeConfig.darkNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(widget.existingName != null ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}